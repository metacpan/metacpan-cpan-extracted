package CTK::App; # $Id: App.pm 250 2019-05-09 12:09:57Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::App - Application interface

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use CTK::App;

    my $ctk = new CTK::App;
    my $ctk = new CTK::App (
        project => 'MyApp',
        ident => "myapp",
        root => ".",
        confopts    => {... Config::General options ...},
        configfile  => '/path/to/conf/file.conf',
        log => 1,
        logfile     => '/path/to/log/file.log',
    );

=head1 DESCRIPTION

The module provides application functionality

Features:

=over 8

=item *

Configuration supported as CTK plugin

=item *

Logging supported as CTK plugin

=back

=head2 CONFIGURATION

For enabling configuration specify the follow arguments in constructor:

    root => "/path/to/conf",
    configfile  => '/path/to/conf/file.conf',

See L<CTK::Configuration>

=head3 ARGUMENTS

=over 8

=item B<configfile>

Path to the configuration file of the your project

Default: /etc/<PREFIX>/<PREFIX>.conf

See L<CTK/"configfile">

=item B<root>

    root => "/path/to/conf",

The main directory of project (confdir)

Default: /etc/<PREFIX>

See L<CTK/"root">

=back

=head2 LOGGER

For enabling logger specify the follow arguments in constructor:

    log => 1,

And include follow config-section:

    #
    # Logging
    #
    # Activate or deactivate the logging: on/off (yes/no). Default: off
    #
    LogEnable on

    #
    # Loglevel: debug, info, notice, warning, error,
    #              crit, alert, emerg, fatal, except
    # Default: debug
    #
    LogLevel debug

    #
    # LogIdent string. Default: none
    #
    #LogIdent "foo"

    #
    # LogFile: path to log file
    #
    # Default: using syslog
    #
    #LogFile /var/log/foo.log

For forcing disable this logger specify the follow arguments in constructor:

    no_logger_init => 1,

=head3 ARGUMENTS

=over 8

=item B<ident>

    ident => "foo"

Ident string for logs and debugging

Default: <PROJECT>

See L<CTK/"ident">

=item B<logfacility>

    logfacility => Sys::Syslog::LOG_USER

Sets facility. See L<CTK::Log/"facility"> and L<Sys::Syslog>

=item B<logfile>

    logfile => '/var/log/myapp/myapp.log'

Full path to the log file

Default: syslog

See L<CTK/"logfile">

=item B<no_logger_init>

Set to 1 for forcing disabling automatic logger initialization on start the your application

Default: 0 (logger is enabled)

=item B<loglevel>

    loglevel => "info"

This directive specifies the minimum possible priority level. You can use:

    'debug'
    'info'
    'notice' or 'note'
    'warning' or 'warn'
    'error' or 'err'
    'crit'
    'alert'
    'emerg' or 'emergency'
    'fatal'
    'except' or 'exception'

Default: "debug"

See L<CTK::Log/"level">

=item B<logopts>

    logopts => {
            utf8        => undef, # Default: 1
            syslogopts  => undef, # Defaukt: "ndelay,pid"
            socketopts  => undef, # Default: "unix"
            pure        => undef, # Default: 0
            separator   => undef, # Default: " "
        }

Default: undef

Logger options. See See L<CTK::Log/"new">

=back

=head1 METHODS

List of application methods

=head2 again

This method is called immediately after creating the CTK object.

Internal use only!

=head2 handle

    $ctk->handle($handler, @params) or die $ctk->error;

Runs handler with parameters

Internal use only!

=head2 list_handlers

    my @handlers = $ctk->list_handlers

Returns list of registered handlers

=head2 lookup_handler

    my $handler = $ctk->lookup_handler($name) or die "Handler lookup failed";

Lookup handler by name. Returns handler or undef while error

=head2 register_handler

    use base qw/ CTK::App /;

    __PACKAGE__->register_handler(
        handler     => "foo",
        description => "Foo CLI handler",
        parameters => {
                param1 => "foo",
                param2 => "bar",
                param3 => 123,
            },
        code => sub {
    ### CODE:
        my $self = shift;
        my $meta = shift;
        my @params = @_;

        $self->debug(Dumper({
                meta => $meta,
                params => [@params],
            }));

        return 1;
    });

Method for register new cli handler

=head2 run, run_handler

    my $app = new CTK::MyApp;
    my $result = $app->run("foo",
        foo => "one",
        bar => 1
    ) or die $app->error;

Run handler by name

Example of result:

    {
      'meta' => {
        'params' => {
           'param3' => 123,
           'param1' => 'foo',
           'param2' => 'bar'
        },
        'name' => 'foo',
           'description' => 'Foo CLI handler'
      },
      'params' => [
        'foo',
        'one',
        'bar',
        1
      ],
    };

=head1 HISTORY

=over 8

=item B<1.00 Mon 29 Apr 22:26:18 MSK 2019>

Init version

=back

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Helper>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
$VERSION = '1.00';

use base qw/ CTK /;

use Carp;

use constant {
        APP_PLUGINS => [qw/
                cli config log
            /],
    };

my %handler_registry;

sub again {
    my $self = shift;
    my $args = $self->origin;
    my $status = $self->load_plugins(@{(APP_PLUGINS)});
    $self->{status} = 0 unless $status;
    my $config = $self->configobj;

    # Autoloading logger (data from config)
    my $log_on = $config->get("logenable") || $config->get("logenabled") || 0;
    if ($self->logmode && (!$args->{no_logger_init}) && $log_on) {
        my $logopts = $args->{logopts} || {};
        my $logfile = defined($args->{logfile}) ? $self->logfile : $config->get("logfile"); # From args or config
        $logopts->{facility} = $args->{logfacility} if defined($args->{logfacility});  # From args only!
        $logopts->{file} = $logfile if defined($logfile) && length($logfile);
        $logopts->{ident} = defined($args->{ident})
            ? $args->{ident}
            : ($config->get("logident") // $self->project); # From args or config
        $logopts->{level} = defined($args->{loglevel})
            ? $args->{loglevel}
            : ($config->get("loglevel")); # From args or config
        $self->logger_init(%$logopts) or do {
            $self->error("Can't initialize logger");
            $self->{status} = 0;
        };
    }

    return $self;
}

sub register_handler {
    my $class = shift;
    $class = ref($class) if ref($class);
    my %info = @_;
    $handler_registry{$class} = {} unless exists($handler_registry{$class});
    my $handlers = $handler_registry{$class};

    # Handler data
    my $name = $info{handler} // $info{name} // '';
    croak("Incorrect handler name") unless length($name);
    delete $info{handler};
    $info{name} = $name;
    croak("The $name duplicate handler definition")
        if defined($handlers->{$name});
    $info{description} //= '';
    my $params = $info{parameters} || $info{params} || {};
    delete $info{parameters};
    $params = {} unless ref($params) eq "HASH";
    $info{params} = $params;
    my $code = $info{code} || sub {return 1};
    if (ref($code) eq 'CODE') {
        $info{code} = $code;
    } else {
        $info{code} = sub { $code };
    }

    $handlers->{$name} = {%info};
    return 1;
}
sub lookup_handler {
    my $self = shift;
    my $name = shift;
    return undef unless $name;
    my $invocant = ref($self) || scalar(caller(0));
    my $handlers = $handler_registry{$invocant};
    return undef unless $handlers;
    return $handlers->{$name}
}
sub list_handlers {
    my $self = shift;
    my $invocant = ref($self) || scalar(caller(0));
    my $handlers = $handler_registry{$invocant};
    return () unless $handlers && ref($handlers) eq 'HASH';
    return (sort {$a cmp $b} keys %$handlers);
}
sub handle {
    my $self = shift;
    my $meta = shift;
    my @params = @_;
    my %info;
    my $func;
    foreach my $k (keys %$meta) {
        next unless defined $k;
        if ($k eq 'code') {
            $func = $meta->{code};
            next;
        }
        $info{$k} = $meta->{$k};
    }
    unless(ref($func) eq 'CODE') {
        $self->error("Handler code not found!");
        return 0;
    }
    my $result = &$func($self, {%info}, @params);
    return $result;
}
sub run_handler {
    my $self = shift;
    my $name = shift;
    my @params = @_;
    unless($name) {
        $self->error("Incorrect handler name");
        return 0;
    }
    my $handler = $self->lookup_handler($name) or do {
        $self->error(sprintf("Handler lookup failed: %s", $name));
        return 0;
    };
    return $self->handle($handler, @params);
}
sub run { goto &run_handler }

1;

__END__
