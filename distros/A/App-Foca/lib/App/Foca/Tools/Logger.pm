#
# App::Foca::Tools::Logger
#
# Author(s): Pablo Fischer (pablo@pablo.com.mx)
# Created: 10/18/2011 07:38:59 AM UTC 07:38:59 AM
package App::Foca::Tools::Logger;

=head1 NAME

App::Foca::Tools::Logger - Main logger interface, uses log4perl

=head2 DESCRIPTION

Main logger interface, uses log4perl

=cut
use strict;
use warnings;
use Exporter 'import';
use vars qw(@EXPORT_OK @EXPORT);
use Data::Dumper;
use File::Basename;
use FindBin;
use Log::Log4perl qw(:easy get_logger :levels);

@EXPORT_OK = qw(init_logger use_debug log_debug log_error log_info log_warn log_die log_connection log_request);
@EXPORT = @EXPORT_OK;

my $LOGGER = undef;
my $USE_DEBUG = 0;

=head1 Methods and functions

=head2 B<init_logger()>

Creates the logger object.

=cut
sub init_logger {
    my ($self) = @_;

    # Foca logging goes to STDERR 
    my $log4perl_config = "log4perl.logger.Foca=DEBUG, Screen\n";
    $log4perl_config .= "log4perl.appender.Screen=" .
        "Log::Log4perl::Appender::Screen\n";
    $log4perl_config .= "log4perl.appender.Screen.stderr=1\n";
    $log4perl_config .= "log4perl.appender.Screen.layout=" .
        "Log::Log4perl::Layout::PatternLayout\n";
    $log4perl_config .= "log4perl.appender.Screen.DatePattern=" .
        "yyyy-MM-dd\n";
    $log4perl_config .= "log4perl.appender.Screen.layout.ConversionPattern=" .
        "\%d \%p \%m \%n\n";
    Log::Log4perl->init(\$log4perl_config);
    $LOGGER = get_logger('Foca');
}

=head2 B<use_debug($on)>

Turn on (by default) or off debug mode.

=cut
sub use_debug {
    my ($on) = @_;

    $USE_DEBUG = $on ? 1 : 0;
    $ENV{'USE_DEBUG'} = $USE_DEBUG;
}

=head2 B<log_connection($ip)>

Logs a connection regardless if it is a legit request or not.

=cut
sub log_connection {
    my ($ip) = @_;

    log_info("Connection - Incoming connection from IP $ip");
}

=head2 B<log_request($ip, $url_path)>

Logs a request. Requires the IP and a URL path.

=cut
sub log_request {
    my ($ip, $url_path) = @_;

    log_info("Request - IP $ip is making request of $url_path");
}

=head2 B<log_die($msg)>

Dies with log4perl sending a C<logdie()>

=cut
sub log_die {
    my ($msg) = @_;
    
    if ($LOGGER) {
        $LOGGER->logcroak($msg);
    } else {
        die $msg;
    }
}

=head2 B<log_error($msg)>

Logs an error, but not fatal errors to kill the app.

=cut
sub log_error {
    my ($msg) = @_;
    
    if ($LOGGER) {
        $LOGGER->error($msg);
    } else {
        print STDERR "ERROR: $msg\n";
    }
}

=head2 B<log_warn($msg)>

Logs a a warning.

=cut
sub log_warn {
    my ($msg) = @_;
    
    if ($LOGGER) {
        $LOGGER->warn($msg);
    } else {
        print STDERR "WARN: $msg\n";
    }
}

=head2 B<log_info($msg)>

Logs an info message (something handy, just as a FYI).

=cut
sub log_info {
    my ($msg) = @_;
    
    if ($LOGGER) {
        $LOGGER->info($msg);
    } else {
        print STDERR "INFO: $msg\n";
    }
}

=head2 B<log_debug($msg)>

Handy for debug messsages.

=cut
sub log_debug {
    my ($msg) = @_;

    if (!$USE_DEBUG) {
        if (!$ENV{'USE_DEBUG'}) {
            return;
        }
    }
    if ($LOGGER) {
        $LOGGER->debug($msg);
    } else {
        print STDERR "DEBUG: $msg\n";
    }
}

=head1 COPYRIGHT

Copyright (c) 2010-2012 Yahoo! Inc. All rights reserved.

=head1 LICENSE

This program is free software. You may copy or redistribute it under
the same terms as Perl itself. Please see the LICENSE file included
with this project for the terms of the Artistic License under which 
this project is licensed.

=head1 AUTHORS

Pablo Fischer (pablo@pablo.com.mx)

=cut
1;
