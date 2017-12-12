package App::MonM::Notifier::Log; # $Id: Log.pm 41 2017-11-30 11:26:30Z abalama $
use strict;

=head1 NAME

App::MonM::Notifier::Log - monotifier logger

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Notifier::Log;

    my $logger = new App::MonM::Notifier::Log(
            "ident"
        );

    $logger->log_info(" ... blah-blah-blah ... ");

=head1 DESCRIPTION

This module provides log methods

=head2 METHODS

=over 8

=item B<new>

Constructor

=item B<log_debug>

Send debug message to the syslog

=item B<log_info>

Send info message to the syslog

=item B<log_notice>

Send notice message to the syslog

=item B<log_warning>, B<log_warn>

Send warning message to the syslog

=item B<log_error>, B<log_err>

Send error message to the syslog

=item B<log_crit>

Send crit message to the syslog

=item B<log_alert>

Send alert message to the syslog

=item B<log_emerg>, B<log_fatal>, B<log_except>, B<log_exception>

Send emerg message to the syslog

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::Notifier>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use constant {
    IDENT   => 'monotifier',
    LOGOPT  => 'ndelay,pid', # For Sys::Syslog
    MSWIN   => $^O =~ /mswin/i ? 1 : 0,
};

use Sys::Syslog qw/ :standard :macros /;

use vars qw/$VERSION/;
$VERSION = '1.00';

sub new {
    my $class = shift;
    my $ident = shift || IDENT;
    my $opts = shift || LOGOPT;
    my $facility = shift || LOG_DAEMON;

    # never log to console - thats too slow, and
    # it corrupts the DBD database connection!
    Sys::Syslog::setlogsock('unix') unless MSWIN;
    openlog($ident, $opts, $facility);

    return bless {
            inited  => 1,
            ident   => $ident,
            facility=> $facility,
        }, $class;
}

sub _syslog {
    my $level = shift;
    my $self = shift;
    eval { syslog ($level, @_); }; # ignore errors
}

sub log_debug { _syslog(LOG_DEBUG, @_) } # LOG_DEBUG - debug-level message
sub log_info { _syslog(LOG_INFO, @_) } # LOG_INFO - informational message
sub log_notice { _syslog(LOG_NOTICE, @_) } # LOG_NOTICE - normal, but significant, condition
sub log_warning { _syslog(LOG_WARNING, @_) } # LOG_WARNING - warning conditions
sub log_warn { goto &log_warning }
sub log_error { _syslog(LOG_ERR, @_) } # LOG_ERR - error conditions
sub log_err { goto &log_error }
sub log_crit { _syslog(LOG_CRIT, @_) } # LOG_CRIT - critical conditions
sub log_alert { _syslog(LOG_ALERT, @_) } # LOG_ALERT - action must be taken immediately
sub log_emerg { _syslog(LOG_EMERG, @_) }  # LOG_EMERG - system is unusable
sub log_fatal { goto &log_emerg }
sub log_except { goto &log_emerg }
sub log_exception { goto &log_emerg }

sub DESTROY {
    my $self = shift;
    return 1 unless $self && $self->{inited};
    closelog();
    return 1;
}

1;
