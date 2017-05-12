package App::Milter::Limit;
$App::Milter::Limit::VERSION = '0.52';
# ABSTRACT: Sendmail Milter that limits message rate by sender

use strict;
use base qw(Class::Accessor Class::Singleton);

use Carp;
use App::Milter::Limit::Config;
use App::Milter::Limit::Log;
use App::Milter::Limit::Util;
use Sendmail::PMilter 0.98 ':all';
use Sys::Syslog ();

__PACKAGE__->mk_accessors(qw(driver milter));


sub _new_instance {
    my ($class, $driver) = @_;

    croak "usage: new(driver)" unless defined $driver;

    my $self = $class->SUPER::_new_instance();

    $self->init($driver);

    return $self;
}

sub init {
    my ($self, $driver) = @_;

    $self->_init_log;

    $self->_init_statedir;

    $self->milter(new Sendmail::PMilter);

    $self->_init_driver($driver);
}

# initialize logging
sub _init_log {
    my $self = shift;

    my $conf = $self->config->section('log');
    $$conf{identity} ||= 'milter-limit';
    $$conf{facility} ||= 'mail';

    Sys::Syslog::openlog($$conf{identity}, $$conf{options}, $$conf{facility});
    info("syslog initialized");

    $SIG{__WARN__} = sub {
        Sys::Syslog::syslog('warning', "warning: ".join('', @_));
    };

    $SIG{__DIE__}  = sub {
        Sys::Syslog::syslog('crit', "fatal: ".join('',@_));
        die @_;
    };
}

# initialize the configured state dir.
# default: /var/run/milter-limit
sub _init_statedir {
    my $self = shift;

    my $conf = $self->config->global;

    App::Milter::Limit::Util::make_path($$conf{state_dir});
}

sub _init_driver {
    my ($self, $driver) = @_;

    my $driver_class = "App::Milter::Limit::Plugin::$driver";

    eval "require $driver_class";
    if ($@) {
        die "failed to load $driver_class: $@\n";
    }
    debug("loaded driver $driver");

    $self->driver($driver_class->instance);
}


sub register {
    my $self = shift;

    my $milter = $self->milter;

    my $conf = $self->config->global;

    $milter->auto_setconn($$conf{name})
        or croak "auto_setconn failed";

    my %callbacks = (
        envfrom => \&_envfrom_callback
    );

    $milter->register($$conf{name}, \%callbacks, SMFI_CURR_ACTS);

    debug("registered as $$conf{name}");
}

# drop user/group privs.
sub _drop_privileges {
    my $self = shift;

    my $conf = $self->config->global;

    if (defined $$conf{group}) {
        ($(,$)) = ($$conf{group}, $$conf{group});
    }

    if (defined $$conf{user}) {
        ($<,$>) = ($$conf{user}, $$conf{user});
    }
}


sub main {
    my $self = shift;

    $self->_drop_privileges;

    my $milter = $self->milter;

    my $conf = $self->config->global;

    my %dispatch_args = (
        max_children           => $$conf{max_children} || 5,
        max_requests_per_child => $$conf{max_requests_per_child} || 100
    );

    my $driver = $self->driver;

    # add child_init hook if necessary
    if ($driver->can('child_init')) {
        debug("child_init hook registered");
        $dispatch_args{child_init} = sub { $driver->child_init };
    }

    # add child_exit hook if necessary
    if ($driver->can('child_exit')) {
        debug("child_exit hook registered");
        $dispatch_args{child_exit} = sub { $driver->child_exit };
    }

    my $dispatcher = Sendmail::PMilter::prefork_dispatcher(%dispatch_args);

    $milter->set_dispatcher($dispatcher);

    info("starting");

    $milter->main;
}

sub _envfrom_callback {
    my ($ctx, $from) = @_;

    # strip angle brackets
    $from =~ s/(?:^\<)|(?:\>$)//g;

    # do not restrict NULL sender (bounces)
    unless (length $from) {
        return SMFIS_CONTINUE;
    }

    my $self = __PACKAGE__->instance();

    my $conf = $self->config->global;

    my $reply = $$conf{reply} || 'reject';

    my $count = $self->driver->query($from);
    debug("$from [$count/$$conf{limit}]");

    if ($count > $$conf{limit}) {
        if ($reply eq 'defer') {
            info("$from exceeded message limit, deferring");

            $ctx->setreply(450, '4.7.1', 'Message limit exceeded');

            return SMFIS_TEMPFAIL;
        }
        else {
            info("$from exceeded message limit, rejecting");

            $ctx->setreply(550, '5.7.1', 'Message limit exceeded');

            return SMFIS_REJECT;
        }
    }
    else {
        return SMFIS_CONTINUE;
    }
}


# shortcut to get the config.
sub config {
    App::Milter::Limit::Config->instance;
}

1;

__END__

=pod

=head1 NAME

App::Milter::Limit - Sendmail Milter that limits message rate by sender

=head1 VERSION

version 0.52

=head1 SYNOPSIS

 my $config = App::Milter::Limit::Config->instance('/etc/mail/milter-limit.conf');
 my $milter = App::Milter::Limit->instance('BerkeleyDB');
 $milter->register;
 $milter->main

=head1 DESCRIPTION

This is a milter framework that limits the number of messages sent by SMTP
envelope sender within a specified time period.  The number of messages and
length of time in which the maximum number of messages can be sent is
configurable in the configuration file.  Once the limit is reached, messages
will be rejected from that sender until the time period has elapsed.

This module provides the interface for the milter.  A datastore plugin is also
required to use this milter.  Datastores are available in the I<App::Milter::Limit::Plugin> namespace.

=head1 METHODS

=head2 instance($driver)

This gets the I<App::Milter::Limit> object, constructing it if necessary.
C<$driver> is the name of the driver that you wish to use (e.g.: I<SQLite>,
I<BerkeleyDB>).

=head2 register

Registers the milter with sendmail and sets up the milter handlers.
See L<Milter::PMilter::register()>.

=head2 main

Main milter loop.

=head2 config

get the App::Milter::Limit::Config instance

=for Pod::Coverage init

=head1 SEE ALSO

L<App::Milter::Limit::Plugin::BerkeleyDB>,
L<App::Milter::Limit::Plugin::SQLite>

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/milter-limit>
and may be cloned from L<git://github.com/mschout/milter-limit.git>

=head1 BUGS

Please report any bugs or feature requests to bug-app-milter-limit@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=App-Milter-Limit

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
