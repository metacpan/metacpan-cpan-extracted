package DBIx::RetryConnect;
$DBIx::RetryConnect::VERSION = '0.002002';
=head1 NAME

DBIx::RetryConnect - automatically retry DBI connect() with exponential backoff

=head1 SYNOPSIS

    use DBIx::RetryConnect qw(Pg);    # use default settings for all Pg connections

    use DBIx::RetryConnect Pg => sub { {} }; # same as above

    use DBIx::RetryConnect Pg => sub {   # set these options for all Pg connections
        return { total_delay => 300, verbose => 1, ... }
    };

    use DBIx::RetryConnect Pg => sub { # set options dynamically for Pg connections
        my ($drh, $dsn, $user, $password, $attrib) = @_;

        # return undef to not retry for this connection

        # don't retry unless we're connecting to a specific database
        return undef if $dsn !~ /foo/;

        # don't retry for errors that don't include "server" in the message
        return undef if $drh->errstr !~ /server/i;

        # or return a hash ref containing the retry options to use
        return { ... };
    };

=head1 DESCRIPTION

The DBIx::RetryConnect module arranges for failed DBI connection attempts to be
automatically and transparently retried for a period of time, with a growing
delay between each retry.

As far as the application is concerned there's no change in behaviour.
Either the connection succeeds at once, succeeds sometime later after one or
more retries, or fails after one or more retries. It isn't aware of the retries.

The DBIx::RetryConnect module works by loading and I<monkey patching> the connect
method of the specified driver module. This allows it to work cleanly 'under the
covers' and thus avoid dealing with the complexities of C<connect_cached>,
C<dbi_connect_method>, C<RaiseError> etc. etc.

=head2 Multiple Usage

When DBIx::RetryConnect is used to configure a driver, the configuration is
added to a list of configurations for that driver.

When a connection fails for that driver the list of configuration code refs is
checked to find the first code ref that returns a hash reference. That hash is
then used to configure the retry behaviour for that connection retry.

=head2 Randomization

Wherever the documentation talks about the duration of a delay the I<actual>
delay is a random value between 75% and 100% of this value. This randomization
helps avoid a "thundering herd" where many systems might attempt to reconnect
at the same time.

=head2 Options

=head3 total_delay

The total time in seconds to spend retrying the connection before giving up
(default 30 seconds).

This time is an approximation. The actual time spent may overshoot by at least
the value of L</max_delay>, plus whatever time the connection attempts themselves
may take.

=head3 start_delay

The duration in seconds of the initial delay after the initial connection
attempt failed (default 0.1).

=head3 backoff_factor

For each subsequent attempt while retrying a connection the delay duration,
which started with L</start_delay>, is multiplied by L</backoff_factor>.

The default is 2, which provides the common "exponential backoff" behaviour.
See also L</max_delay>.

=head3 max_delay

The maximum duration, in seconds, for any individual retry delay. The default
is the value of L</total_delay> divided by 4. See also L</backoff_factor>.

=head3 verbose

Enable extra logging.

 1 - log each use of DBIx::RetryConnect module
 2 - also log each connect failure
 3 - also log each connect retry
 4 - also log each connect retry with more timing details

The default is the value of the C<DBIX_RETRYCONNECT_VERBOSE> environment
variable if set, else 0.

=cut


use strict;
use warnings;

use Carp qw(carp croak);
use DBI;

# proxy

my %installed_dbd_configs; # Pg => [ {...}, ... ]


sub import {
    my($exporter, @imports)  = @_;

    croak "No drivers specified"
        unless @imports;

    while (my $dbd = shift @imports) {
        my $options = (@imports && ref $imports[0]) ? shift @imports : sub { {} };

        croak "$exporter $dbd argument must be a CODE reference, not $options"
            if defined($options) && ref $options ne 'CODE';

        if ($ENV{DBIX_RETRYCONNECT_VERBOSE}) {
            my $desc = (defined $options) ? "$options" : "default";
            carp "$exporter installing $desc config for $dbd";
        }

        my $configs = $installed_dbd_configs{$dbd} ||= [];
        push @$configs, $options; # add to list of configs for this DBD

        # install the retry hook for this DBD if this is the first config
        install_retry_connect($dbd, $configs) if @$configs == 1;
    }

    return;
}


sub install_retry_connect {
    my ($dbd, $configs) = @_;

    DBI->install_driver($dbd);

    my $connect_method = "DBD::${dbd}::dr::connect";

    ## no critic (ProhibitNoStrict)
    my $orig_connect_subref = do { no strict 'refs'; *$connect_method{CODE} }
        or croak "$connect_method not defined";

    my $retry_state_class = "DBIx::RetryConnect::RetryState";

    if (($ENV{DBIX_RETRYCONNECT_VERBOSE}||0) >= 2) {
        carp __PACKAGE__." installing $retry_state_class hook into DBD::$dbd";
    }

    my $retry_connect_subref = sub {

        my $retry;
        while (1) {

            my $dbh = $orig_connect_subref->(@_);
            return $dbh if $dbh;

            $retry ||= do {
                my $options = pick_retry_options_from_configs($configs, \@_);
                return undef if not $options;
                $retry_state_class->new($options, \@_);
            };

            $retry->pause
                or return undef;
        }
    };

    do {
        no warnings 'redefine';    ## no critic (ProhibitNoWarnings)
        no strict 'refs';          ## no critic (ProhibitNoStrict)
        *$connect_method = $retry_connect_subref;
    };

    return;
}


sub pick_retry_options_from_configs {
    my ($configs, $connect_args) = @_;

    for my $config (@$configs) {
        my $dynamic_config = $config->(@$connect_args);
        return $dynamic_config if $dynamic_config;
    }

    return undef; # no config matched, so no retry behaviour
}


{
package DBIx::RetryConnect::RetryState; ## no critic (ProhibitMultiplePackages)
$DBIx::RetryConnect::RetryState::VERSION = '0.002002';
use Carp qw(carp croak);
use Time::HiRes qw(usleep);
use Hash::Util qw(lock_keys);

sub new {
    my ($class, $options, $connect_args) = @_;

    my $self = bless {
        total_delay => 30,
        start_delay => undef,
        next_delay => undef,
        max_delay => undef,
        backoff_factor => 2,
        verbose => $ENV{DBIX_RETRYCONNECT_VERBOSE} || 0,
        connect_args => $connect_args,
    } => $class;
    lock_keys(%$self);

    $self->{$_} = $options->{$_} for keys %$options;

    $self->{next_delay} ||= $self->{start_delay} ||= 0.1; # 0.1 = 100ms
    $self->{max_delay}  ||= ($self->{total_delay} / 4);

    if ($self->{verbose} >= 2) {
        my @ca = @{$self->{connect_args}};
        local $self->{connect_args} = "$ca[0]->{Name}:$ca[1]"; # just the driver and dsn, hide password
        my $kv = DBI::_concat_hash_sorted($self, "=", ", ", 1, undef); ## no critic (ProtectPrivateSubs)
        carp "$class $kv";
    }

    return $self;
}

sub calculate_next_delay {
    my $self = shift;

    return 0 if $self->{total_delay} <= 0;

    if ($self->{next_delay} > $self->{max_delay}) {
        $self->{next_delay} = $self->{max_delay};
    }

    # treat half the delay time as fixed and half as random
    # this helps avoid a thundering-herd problem
    my $this_delay = ($self->{next_delay} * 0.75) + rand($self->{next_delay} * 0.25);

    if ($self->{verbose} >= 3) {

        my $extra = "";
        $extra = sprintf " [delay %.1fs, remaining %.1fs]",
                $self->{next_delay}, $self->{total_delay}
            if $self->{verbose} >= 4;

        # fudge %Carp::Internal so the carp shows a more useful caller
        local $Carp::Internal{'DBI'} = 1;                ## no critic (ProhibitPackageVars)
        local $Carp::Internal{'DBIx::RetryConnect'} = 1; ## no critic (ProhibitPackageVars)
        my ($drh, $dsn) = @{$self->{connect_args}};
        my $errstr = $drh->errstr;
        $errstr = "(undef errstr)" if not defined $errstr;
        carp sprintf "DBIx::RetryConnect(%s:%s): sleeping for %.2gs after error: %s%s",
                $drh->{Name}, $dsn, $this_delay, $errstr, $extra;
    }

    $self->{total_delay} -= $this_delay;     # track actual remaining time
    $self->{next_delay}  *= $self->{backoff_factor}; # backoff

    return $this_delay;
}

sub pause {
    my $self = shift;

    my $this_delay = $self->calculate_next_delay;

    return 0 if not $this_delay;

    usleep($this_delay * 1_000_000); # microseconds

    return 1;
}

} # end of DBIx::RetryConnect::RetryState

1;
