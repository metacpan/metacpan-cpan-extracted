package Acme::Ghost::Log;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

Acme::Ghost::Log - Simple logger

=head1 SYNOPSIS

    use Acme::Ghost::Log;

    my $log = Acme::Ghost::Log->new();
       $log->error("My test error message to syslog")

    # Using file
    my $log = Acme::Ghost::Log->new(file => '/tmp/test.log');
       $log->error("My test error message to /tmp/test.log")

    # Customize minimum log level
    my $log = Acme::Ghost::Log->new(level => 'warn');

    # Log messages
    $log->trace('Doing stuff');
    $log->debug('Not sure what is happening here');
    $log->info('FYI: it happened again');
    $log->warn('This might be a problem');
    $log->error('Garden variety error');
    $log->fatal('Boom');

=head1 DESCRIPTION

Acme::Ghost::Log is a simple logger for Acme::Ghost logging after daemonization

=head2 new

    my $log = Acme::Ghost::Log->new(
        logopt      => 'ndelay,pid',
        facility    => 'user',
        level       => 'debug',
        ident       => 'test.pl',
    );

With default attributes

    use Mojo::Log;
    my $log = Acme::Ghost::Log->new( logger => Mojo::Log->new );
    $log->error("Test error message");

This is example with external loggers

=head1 ATTRIBUTES

This class implements the following attributes

=head2 facility

This attribute sets facility for logging

Available standard facilities: C<auth>, C<authpriv>, C<cron>, C<daemon>, C<ftp>,
C<kern>, C<local0>, C<local1>, C<local2>, C<local3>, C<local4>, C<local5>, C<local6>,
C<local7>, C<lpr>, C<mail>, C<news>, C<syslog>, C<user> and C<uucp>

Default: C<user> (Sys::Syslog::LOG_USER)

See also L<Sys::Syslog/Facilities>

=head2 file

Log file path used by "handle"

=head2 handle

Log filehandle, defaults to opening "file" or uses syslog if file not specified

=head2 ident

The B<ident> is prepended to every message

Default: script name C<basename($0)>

=head2 level

There are six predefined log levels: C<fatal>, C<error>, C<warn>, C<info>, C<debug>, and C<trace> (in descending priority).
The syslog supports followed additional log levels: C<emerg>, C<alert>, C<crit'> and C<notice> (in descending priority).
But we recommend not using them to maintain compatibility.
Your configured logging level has to at least match the priority of the logging message.

If your configured logging level is C<warn>, then messages logged with info(), debug(), and trace()
will be suppressed; fatal(), error() and warn() will make their way through, because their
priority is higher or equal than the configured setting.

Default: C<debug>

See also L<Sys::Syslog/Levels>

=head2 logger

This attribute perfoms to set predefined logger, eg. Mojo::Log

Default: C<undef>

=head2 logopt

This attribute contains zero or more of the options detailed in L<Sys::Syslog/openlog>

Default: C<'ndelay,pid'>

=head1 METHODS

This class implements the following methods

=head2 alert

    $log->alert('Action must be taken immediately');
    $log->alert('Real', 'problem');

Log C<alert> message

=head2 crit

    $log->crit('Its over...');
    $log->crit('Bye', 'bye');

Log C<crit> message (See L</fatal> method)

=head2 debug

    $log->debug('You screwed up, but that is ok');
    $log->debug('All', 'cool');

Log C<debug> message

=head2 emerg

    $log->emerg('System is unusable');
    $log->emerg('To', 'die');

Log C<emerg> message

=head2 error

    $log->error('You really screwed up this time');
    $log->error('Wow', 'seriously');

Log C<error> message

=head2 fatal

    $log->fatal('Its over...');
    $log->fatal('Bye', 'bye');

Log C<fatal> message

=head2 info

    $log->info('You are bad, but you prolly know already');
    $log->info('Ok', 'then');

Log C<info> message

=head2 level

    my $level = $log->level;
    $log      = $log->level('debug');

Active log level, defaults to debug.
Available log levels are C<trace>, C<debug>, C<info>, C<notice>, C<warn>, C<error>,
C<fatal> (C<crit>), C<alert> and C<emerg>, in that order

=head2 logger

    my $logger = $log->logger;

This method returns the logger object or undef if not exists

=head2 notice

    $log->notice('Normal, but significant, condition...');
    $log->notice('Ok', 'then');

Log C<notice> message

=head2 provider

    print $log->provider;

Returns provider name (C<external>, C<handle>, C<file> or C<syslog>)

=head2 trace

    $log->trace('Whatever');
    $log->trace('Who', 'cares');

Log C<trace> message

=head2 warn

    $log->warn('Dont do that Dave...');
    $log->warn('No', 'really');

Log C<warn> message

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Sys::Syslog>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.00';

use Carp qw/carp croak/;
use Scalar::Util qw/blessed/;
use Sys::Syslog qw//;
use File::Basename qw/basename/;
use IO::File qw//;
use Fcntl qw/:flock/;
use Encode qw/find_encoding/;
use Time::HiRes qw/time/;

use constant {
    LOGOPTS         => 'ndelay,pid', # For Sys::Syslog
    SEPARATOR       => ' ',
    LOGFORMAT       => '%s',
};
my %LOGLEVELS = (
    'trace'     => Sys::Syslog::LOG_DEBUG,    # 7 debug-level message
    'debug'     => Sys::Syslog::LOG_DEBUG,    # 7 debug-level message
    'info'      => Sys::Syslog::LOG_INFO,     # 6 informational message
    'notice'    => Sys::Syslog::LOG_NOTICE,   # 5 normal, but significant, condition
    'warn'      => Sys::Syslog::LOG_WARNING,  # 4 warning conditions
    'error'     => Sys::Syslog::LOG_ERR,      # 3 error conditions
    'fatal'     => Sys::Syslog::LOG_CRIT,     # 2 critical conditions
    'crit'      => Sys::Syslog::LOG_CRIT,     # 2 critical conditions
    'alert'     => Sys::Syslog::LOG_ALERT,    # 1 action must be taken immediately
    'emerg'     => Sys::Syslog::LOG_EMERG,    # 0 system is unusable
);
my %MAGIC = (
    'trace'     => 8,
    'debug'     => 7,
    'info'      => 6,
    'notice'    => 5,
    'warn'      => 4,
    'error'     => 3,
    'fatal'     => 2, 'crit' => 2,
    'alert'     => 1,
    'emerg'     => 0,
);
my %SHORT = ( # Log::Log4perl::Level notation
    0 => 'fatal', 1 => 'fatal', 2 => 'fatal',
    3 => 'error',
    4 => 'warn',
    5 => 'info', 6 => 'info',
    7 => 'debug',
    8 => 'trace',
);

my $ENCODING = find_encoding('UTF-8') or croak qq/Encoding "UTF-8" not found/;

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $args->{facility}   ||= Sys::Syslog::LOG_USER;
    $args->{ident}      ||= basename($0);
    $args->{logopt}     ||= LOGOPTS;
    $args->{logger}     ||= undef;
    $args->{level}      ||= 'debug';
    $args->{file}       ||= undef;
    $args->{handle}     ||= undef;
    $args->{provider}   = 'unknown';

    # Check level
    croak "Incorrect log level specified" unless exists $MAGIC{$args->{level}};

    # Instance
    my $self = bless {%$args}, $class;

    # Open sys log socket
    if ($args->{logger}) {
        croak "Blessed reference expected in logger attribute" unless blessed($args->{logger});
        $self->{provider} = "external";
    } elsif ($args->{handle}) {
        $self->{provider} = "handle";
        return $self;
    } elsif ($args->{file}) {
        my $file = $args->{file};
        $self->{handle} = IO::File->new($file, ">>");
        croak qq/Can't open file "$file": $!/ unless defined $self->{handle};
        $self->{provider} = "file";
    } else {
        Sys::Syslog::openlog($args->{ident}, $args->{logopt}, $args->{facility});
        $self->{provider} = "syslog";
    }

    return $self;
}
sub level {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{level} = shift;
        return $self;
    }
    return $self->{level};
}
sub logger { shift->{logger} }
sub handle { shift->{handle} }
sub provider { shift->{provider} }

sub trace { shift->_log('trace', @_) }
sub debug { shift->_log('debug', @_) }
sub info { shift->_log('info', @_) }
sub notice { shift->_log('notice', @_) }
sub warn { shift->_log('warn', @_) }
sub error { shift->_log('error', @_) }
sub fatal { shift->_log('fatal', @_) }
sub crit { shift->_log('crit', @_) }
sub alert { shift->_log('alert', @_) }
sub emerg { shift->_log('emerg', @_) }

sub _log {
    my ($self, $level, @msg) = @_;
    my $req = $MAGIC{$self->level};
    my $mag = $MAGIC{$level} // 7;
    return 0 unless $mag <= $req;

    # Logger
    if (my $logger = $self->logger) {
        my $name = $SHORT{$mag};
        if (my $code = $logger->can($name)) {
            return $logger->$code(@msg);
        } else {
            carp(sprintf("Can't found '%s' method in '%s' package", $name, ref($logger)));
        }
        return 0;
    }

    # Handle
    if (my $handle = $self->handle) {
        flock $handle, LOCK_EX;
        my $tm = time;
        my ($s, $m, $h, $day, $month, $year) = localtime $tm;
        my $time = sprintf '%04d-%02d-%02d %02d:%02d:%08.5f', $year + 1900, $month + 1, $day, $h, $m,
           "$s." . ((split /\./, $tm)[1] // 0);
        $handle->print($ENCODING->encode("[$time] [$$] [$level] " . join(SEPARATOR, @msg) . "\n", 0))
            or croak "Can't write to log: $!";
        flock $handle, LOCK_UN;
        return 1;
    }

    return 0 if $self->provider ne "syslog";
    my $lvl = $LOGLEVELS{$level} // Sys::Syslog::LOG_DEBUG;
    Sys::Syslog::syslog($lvl, LOGFORMAT, join(SEPARATOR, @msg));
}

DESTROY {
    my $self = shift;
    undef $self->{handle} if $self->{file};
    Sys::Syslog::closelog() unless $self->logger;
}

1;

__END__
