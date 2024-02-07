package Acme::Crux::Plugin::Log;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

Acme::Crux::Plugin::Log - The Acme::Crux plugin for logging in your application

=head1 SYNOPSIS

    # In startup
    $app->plugin('Log');
    $app->plugin('Log', undef, { ... options ... });

    # In application
    $app->log->trace('Whatever');
    $app->log->debug('You screwed up, but that is ok');
    $app->log->info('You are bad, but you prolly know already');
    $app->log->notice('Normal, but significant, condition...');
    $app->log->warn('Dont do that Dave...');
    $app->log->error('You really screwed up this time');
    $app->log->fatal('Its over...');
    $app->log->crit('Its over...');
    $app->log->alert('Action must be taken immediately');
    $app->log->emerg('System is unusable');

=head1 DESCRIPTION

The Acme::Crux plugin for logging in your application

=head1 OPTIONS

This plugin supports the following options

=head2 autoclean

    $app->plugin(Log => undef, {autoclean => 1});

This option enables cleaning (closing handler or syslog) on DESTROY

Default: C<logautoclean> command line option or C<logautoclean> application argument
or C<LogAutoclean> configuration value or C<0> otherwise

=head2 color

    $app->plugin(Log => undef, {color => 1});

This option enables colorize log messages with the available levels using L<Term::ANSIColor>

Default: C<logcolorize> command line option or C<logcolorize> application argument
or C<LogColorize> configuration value or C<0> otherwise

=head2 facility

    $app->plugin(Log => undef, {facility => 'user'});

This option sets facility for logging

Available standard facilities: C<auth>, C<authpriv>, C<cron>, C<daemon>, C<ftp>,
C<kern>, C<local0>, C<local1>, C<local2>, C<local3>, C<local4>, C<local5>, C<local6>,
C<local7>, C<lpr>, C<mail>, C<news>, C<syslog>, C<user> and C<uucp>

Default: C<logfacility> command line option or C<logfacility> application argument
or C<LogFacility> configuration value or C<user> otherwise

=head2 file

    $app->plugin(Log => undef, {file => '/var/log/myapp.log'});

Log file path used by "handle"

Default: C<logfile> command line option or C<LogFile> configuration value
or C<logfile> application argument or C</var/log/$moniker/$moniker.log> otherwise

=head2 format

    $app->plugin(Log => undef, {format => sub {...}});

A callback function for formatting log messages. See L<Acrux::Log/format>

Default: C<logformat> application argument or C<undef> otherwise

=head2 handle

    $app->plugin(Log => undef, {
        handle => IO::Handle->new_from_fd(fileno(STDOUT), "w")
    });

Log filehandle, defaults to opening "file" or uses syslog if file not specified

Default: C<loghandle> application argument or C<undef> otherwise

=head2 ident

    $app->plugin(Log => undef, {ident => 'myapp'});

The B<ident> is prepended to every B<syslog> message

Default: C<logident> command line option or C<logident> application argument
or C<LogIdent> configuration value or script name C<basename($0)> otherwise

=head2 level

    $app->plugin(Log => undef, {level => 'debug'});

This option sets log level

Predefined log levels: C<fatal>, C<error>, C<warn>, C<info>, C<debug>, and C<trace> (in descending priority).
The syslog supports followed additional log levels: C<emerg>, C<alert>, C<crit'> and C<notice> (in descending priority).
But we recommend not using them to maintain compatibility.

See also L<Acrux::Log/level>

Default: C<loglevel> command line option or C<loglevel> application argument
or C<LogLevel> configuration value or C<debug> otherwise

=head2 logger

    $app->plugin(Log => undef, {logger => Mojo::Log->new()});

This option sets predefined logger, eg. Mojo::Log

Default: C<logger> application argument or C<undef> otherwise

=head2 logopt

    $app->plugin(Log => undef, {logopt => 'ndelay,pid'});

This option contains zero or more of the options detailed in L<Sys::Syslog/openlog>

Default: C<logopt> command line option or C<logopt> application argument
or C<LogOpt> configuration value or C<'ndelay,pid'> otherwise

=head2 prefix

    $app->plugin(Log => undef, {prefix => '>>>'});

The B<prefix> is prepended to every C<handled> log message

Default: C<logprefix> command line option or C<logprefix> application argument
or C<LogPrefix> configuration value or C<null> otherwise

=head2 provider

    $app->plugin(Log => undef, {provider => 'syslog'});

This option select the provider of logging. Avalabled providers:
C<logger>, C<handler>, C<file> and C<syslog>.

Default: C<logprovider> command line option or C<logprovider> application argument
or C<LogProvider> configuration value or C<file> otherwise

=head2 short

    $app->plugin(Log => undef, {short => 1});

Generate short log messages without a timestamp but with log level prefix

Default: C<logshort> command line option or C<logshort> application argument
or C<LogShort> configuration value or C<0> otherwise

=head1 METHODS

This class inherits all methods from L<Acme::Crux::Plugin> and implements the following new ones

=head2 register

    $plugin->register($app, {file => '/var/log/app.log'});

Register plugin in Acme::Crux application

=head1 HELPERS

All helpers of this plugin are allows get access to logger object.
See L<Acrux::Log> for details

=head2 log

Returns L<Acrux::Log> object

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Acme::Crux::Plugin>, L<Acrux::Log>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '0.01';

use parent 'Acme::Crux::Plugin';

use Acrux::Log;

use Carp qw/croak/;
use Acrux::RefUtil qw/as_array_ref as_hash_ref is_code_ref is_true_flag is_ref/;

sub register {
    my ($self, $app, $args) = @_;
    my $has_config = $app->can('config') ? 1 : 0;

    # Autoclean flag: PLGARGS || OPTS || ORIG || CONF || DEFS
    my $autoclean = is_true_flag($args->{autoclean}) # From plugin arguments first
      || $app->getopt("logautoclean")               # From command line options
      || $app->orig->{"logautoclean"}               # From App arguments
      || ($has_config ? $app->config->get("/logautoclean") : 0); # From config file

    # Colorize flag: PLGARGS || OPTS || ORIG || CONF || DEFS
    my $colorize = is_true_flag($args->{color}) # From plugin arguments first
      || $app->getopt("logcolorize")           # From command line options
      || $app->orig->{"logcolorize"}           # From App arguments
      || ($has_config ? $app->config->get("/logcolorize") : 0); # From config file

    # Log facility: PLGARGS || OPTS || ORIG || CONF || DEFS
    my $facility = $args->{facility}  # From plugin arguments first
      || $app->getopt("logfacility") # From command line options
      || $app->orig->{"logfacility"} # From App arguments
      || ($has_config ? $app->config->get("/logfacility") : ''); # From config file

    # Log file: PLGARGS || OPTS || CONF || ORIG || DEFS
    my $file = $args->{file}  # From plugin arguments first
      || $app->getopt("logfile") # From command line options
      || ($has_config ? $app->config->get("/logfile") : '') # From config file
      || $app->logfile; # From App arguments

    # Format: PLGARGS || DEFS
    my $frmt = $args->{format} || $app->orig->{"logformat"};
    if (defined($frmt) && length($frmt)) {
        croak(qq{Invalid log format coderef}) unless is_code_ref($frmt);
    }

    # Handle: PLGARGS || DEFS
    my $handle = $args->{handle} || $app->orig->{"loghandle"};
    if (defined $handle) {
        croak(qq{Invalid log handle}) unless is_ref($handle);
    }

    # Log ident: PLGARGS || OPTS || ORIG || CONF || DEFS
    my $ident = $args->{ident}  # From plugin arguments first
      || $app->getopt("logident") # From command line options
      || $app->orig->{"logident"} # From App arguments
      || ($has_config ? $app->config->get("/logident") : ''); # From config file

    # Log level: PLGARGS || OPTS || ORIG || CONF || DEFS
    my $level = $args->{level}  # From plugin arguments first
      || $app->getopt("loglevel") # From command line options
      || $app->orig->{"loglevel"} # From App arguments
      || ($has_config ? $app->config->get("/loglevel") : ''); # From config file

    # Logger: PLGARGS || DEFS
    my $logger = $args->{logger} || $app->orig->{"logger"};
    if (defined $logger) {
        croak(qq{Invalid logger object}) unless is_ref($logger);
    }

    # Log options: PLGARGS || OPTS || ORIG || CONF || DEFS
    my $logopt = $args->{logopt}  # From plugin arguments first
      || $app->getopt("logopt") # From command line options
      || $app->orig->{"logopt"} # From App arguments
      || ($has_config ? $app->config->get("/logopt") : ''); # From config file

    # Short flag: PLGARGS || OPTS || ORIG || CONF || DEFS
    my $short = is_true_flag($args->{short}) # From plugin arguments first
      || $app->getopt("logshort") # From command line options
      || $app->orig->{"logshort"} # From App arguments
      || ($has_config ? $app->config->get("/logshort") : 0); # From config file

    # Log prefix: PLGARGS || OPTS || ORIG || CONF || DEFS
    my $prefix = $args->{prefix}  # From plugin arguments first
      || $app->getopt("logprefix") # From command line options
      || $app->orig->{"logprefix"} # From App arguments
      || ($has_config ? $app->config->get("/logprefix") : ''); # From config file

    # Correct provider rules
    my $provider = $args->{provider}  # From plugin arguments first
      || $app->getopt("logprovider") # From command line options
      || $app->orig->{"logprovider"} # From App arguments
      || ($has_config ? $app->config->get("/logprovider") : '') || ''; # From config file
    if ($provider eq 'syslog')    { $file = $handle = $logger = undef }
    elsif ($provider eq 'file')   { $logger = $handle = undef }
    elsif ($provider eq 'handle') { $logger = undef }

    # Create instance
    my $log = Acrux::Log->new(
        autoclean => $autoclean,
        color => $colorize, # !!
        facility => $facility,
        file => $file,
        format => $frmt, # !!
        handle => $handle,
        ident => $ident,
        level => $level,
        logger => $logger,
        logopt => $logopt,
        short => $short,
        prefix => $prefix,
    );

    # Set log helper (method)
    $app->register_method(log => sub { $log });

    return $log;
}

1;

__END__
