package App::Syslogd::I18N::en;

# English lexicon.  Square brackets are Maketext syntax; a literal bracket
# is written "~[" or "~]".  Argument order is defined by %ARGUMENT_ORDER in
# App::Syslogd::I18N, not here.

use strict;
use warnings;
use autodie qw(:all);

# Not -norequire: a translation that inherits from this package (as the
# documentation recommends) may be loaded before App::Syslogd::I18N is
use parent 'App::Syslogd::I18N';

our $VERSION = '0.002.0';

our %Lexicon = (
	usage => 'Usage: [_1] ~[--port <port_number>~] ~[--address <address>~] ~[--file <CSV file>~] ~[--no-resolve~] ~[--language <tag>~]',
	listening => 'Syslog server listening on [_1] UDP port [_2]',
	shutdown => 'Syslog server shutting down after recording [quant,_1,message,messages]',
	socket_failed => 'Could not create a UDP socket on [_1] port [_2]: [_3]',
	open_failed => 'Could not open log file [_1]: [_2]',
	unsafe_file => 'Refusing to log to [_1]: it must be a regular file, owned by this user, with exactly one link',
	write_failed => 'Could not write to log file [_1]: [_2]',
	recv_failed => 'Error receiving a datagram: [_1]',
	no_log_open => 'process() was called before reopen_log() succeeded',
	not_a_datagram => 'A datagram must be a string (the type given was [_1])',
	missing_key => 'A message key is needed',
	bad_values => 'Message values must be a hash reference (the type given was [_1])',
	no_progress => 'the system accepted no data',
	not_a_log => 'Refusing to log to [_1]: it is not empty and does not start with the syslog header line',
	already_running => 'run() is already running',
	not_cgi => 'This program is a server, not a CGI program: it will not run from a web server',
);

=head1 NAME

App::Syslogd::I18N::en - English messages for App::Syslogd

=head1 VERSION

Version 0.002.0

=head1 SYNOPSIS

You do not use this package directly.  L<App::Syslogd::I18N> loads it:

	my $lh = App::Syslogd::I18N->handle('en');

=head1 DESCRIPTION

The English text of every message.  It is also the fallback: when no
lexicon matches the user's language, English is used.  Other languages
should inherit from this package, so that a message they have not translated
yet is still shown in English.  L<App::Syslogd::I18N> explains the format.

=head1 ENCODING

All the text is ASCII.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2
(see the F<LICENSE> file).  If you use it, please let me know.

=cut

1;
