package Apache::FormatLog;

=head1 NAME

Apache::FormatLog -- Base package to retrieve logdata for creating Apache access logs from mod_perl handlers.

=head1 SYNOPSIS

=begin html

<code>
use Apache;<br>
use Apache::FormatLog;<br>
<br>
$lf = Apache::FormatLog->new($r);<br>
$logdata = $lf->getLogData();<br>
$logline = $lf->toString();<br>
</code>

=end html

=head1 DESCRIPTION

C<Apache::FormatLog> provides an interface to most common logdata that is used for access logs.
You can use this module from mod_perl handlers.
This class should always be extended, and the methods toString and write should always be overridden.
Two existing FormatLog modules that use C<Apache::FormatLog> are:
C<Apache::FormatLog::Common> and C<Apache::FormatLog::Combined>

=head1 METHODS


=head2 new ( $requestObject )

Created a new FormatLog object. An Apache request object (see docs [1]) is expected as a parameter.

=head2 toString ( )

Return the formatted logline as a string.

=head2 getLogData ( )

Returns a hashreference with the most common data that is needed for logging.
The hash reference contains the following keys:

=over

=item waittime

The time between the start and end of the request in seconds.

=item status

The HTTP status code for this request.

=item bytes

The total number of bytes sent in this request.

=item browser

The identified User-agent

=item filename

The filename that is returned in the request.

=item referer

The referer page.

=item remotehost

=item remoteip

=item remoteuser

=item remotelogname

=item hostname

=item encoding

=item language

=item request

The first line of the full HTTP request.

=item timeFormatted

The standard Apache formatted time (now): [dd/MM/yyyy:hh:mm::s +GMT]

=item protocol

=item querystring

The query string, without a leading ? (question mark)

=item method

The request method as a string: "GET", "HEAD" or "POST"


=back

=head1 SEE ALSO

perl(1), mod_perl(3), Apache(3),
Apache::FormatLog::Common, Apache::FormatLog::Combined

=head1 AUTHOR

Leendert Bottelberghs <lbottel@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005, Leendert Bottelberghs.  All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 REFERENCES

[1] http://search.cpan.org/~gozer/mod_perl-1.29/Apache/Apache.pm

=cut


use strict;
use vars qw($VERSION);

$VERSION = '0.01';

sub new {
	my $class = shift;
	bless {'r'=>$_[0]}, $class;
}

sub _getFormattedTime {
	my $class = shift;
	my (@lctime, @gmtime, $mo, $tz, $time);
	@lctime = localtime();
	@gmtime = gmtime();
	$mo = (($lctime[2]-$gmtime[2])%24)*60+($lctime[1]-$gmtime[1])%60;
	$tz = int($mo/60)*100+($mo/abs($mo))*($mo%60);
	$time = sprintf "[%02d/%3s/%4d:%02d:%02d:%02d %+05d]",
			($lctime[3],
			(qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[$lctime[4]]),
			(1900+$lctime[5]),
			$lctime[2],
			$lctime[1],
			$lctime[0],
			$tz);
	return $time;
}

sub getLogData {
	my $class = shift;
	my $r = $class->{r};
	my %logdata;
	$logdata{waittime} = time - $r->pnotes("REQUEST_START");
	$logdata{status} = $r->status();
	$logdata{bytes} = $r->bytes_sent();
	$logdata{browser} = $r->headers_in->get('User-agent');
	$logdata{filename} = $r->filename();
	$logdata{uri} = $r->uri();
	$logdata{referer} = $r->headers_in->get('Referer');
	$logdata{remotehost} = $r->get_remote_host();
	$logdata{remoteip} = $r->connection->remote_ip();
	$logdata{remoteuser} = $r->user();
	$logdata{remotelogname} = $r->get_remote_logname();
	$logdata{hostname} = $r->hostname();
	$logdata{encoding} = $r->headers_in->get('Accept-Encoding');
	$logdata{language} = $r->headers_in->get('Accept-Language');
	$logdata{request} = $r->the_request();
	$logdata{formattedtime} = $class->_getFormattedTime();
	$logdata{protocol} = $r->protocol();
	$logdata{queryString} = $r->args();
	$logdata{method} = $r->method();
	return \%logdata;
}

sub toString {
# extend this method to create custom FormatLog.
	my $class = shift;
	return '';
}

1;
