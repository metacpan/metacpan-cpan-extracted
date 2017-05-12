# Copyright (C) 2000 by Robert Jenks
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package Apache::AddHostPath;

use Apache::Constants qw(:common);
use Apache::Log ();
use vars qw($VERSION);
$VERSION = '0.02';

sub handler {
	my $r = shift;
	my $uri = $r->uri();
	$uri =~ s{^/}{};
	my @path_items = split '/', $uri;
	my ($hostname, $port) = split ':', $r->headers_in->{'Host'};
	
	my @path_info = ();
	my $filename = '';
	PATH_ITEMS: while (1) {
		my @host_items = reverse split '\.', $hostname;
		push @host_items, $port;
		HOST_ITEMS: while (1) {
			$uri = '/' . join '/', @host_items, @path_items;
			$filename = $r->document_root() . $uri;
			$r->log->debug("Checking for: '$filename'");
			last PATH_ITEMS if -d $filename or -f $filename;
			last HOST_ITEMS unless pop @host_items;
		}
		return DECLINED unless @path_items;
		unshift @path_info, pop @path_items;
	}
	$filename .= '/' if -d $filename;
	$r->log->debug("Found match at: '$filename'");
	
	# Set $r->filename()
	#$filename = join '/', $filename, @path_info;
	#$r->log->debug("Filename set to: '$filename'");
	#$r->filename($filename);
	#return OK;
	
	# Set $r->uri()
	$uri = join '/', $uri, @path_info;
	$uri .= '/' if ! @path_info && -d $filename;
	$r->log->debug("URI set to: '$uri'");
	$r->uri($uri);
	return DECLINED;
}

1;

__END__

=head1 NAME

Apache::AddHostPath - Adds some or all of the hostname and port to the URI

=head1 SYNOPSIS

  # in httpd.conf
  PerlTransHandler Apache::AddHostPath

=head1 DESCRIPTION

This module transforms the requested URI based on the hostname
and port number from the http request header.  It allows you
to manage an arbitrary number of domains and/or sub-domains
all pointed to the same document root, but for which you want
a combination of shared and distinct files.

Essentially the module implements Apache's URI translation
phase by attempting to use some or all of the URL hostname
and port number as the base of the URI.  It simply does
file and directory existence tests on a series of URIs (from
most-specific to least-specific) and sets the URI to the most 
specific match.

If the requested is:

 URL: http://www.alpha.cvsroot.org:8080/index.html
 URI: /index.html

Apache::AddHostPath would go through the following list of
possible paths and set the new URI based on the first match which
passes a B<-f> or B<-d> existence test:

 $docRoot/org/cvsroot/alpha/www/8080/index.html
 $docRoot/org/cvsroot/alpha/www/index.html
 $docRoot/org/cvsroot/alpha/index.html
 $docRoot/org/cvsroot/index.html
 $docRoot/org/index.html
 $docRoot/index.html

For example if you have three domains cvsroot.org, ransommoney.com,
and inputsignal.com using the same apache instance and DocumentRoot
(without using VirtualHosts). If you assume that the DocumentRoot 
contains the following files and directories:

 images/
 images/bg.gif
 org/
 org/cvsroot/
 org/cvsroot/images/logo.gif
 com/
 com/images/
 com/images/bg.gif
 com/ransommoney/
 com/ransommoney/images/
 com/ransommoney/images/logo.gif
 com/ransommoney/images/bg.gif
 com/inputsignal/
 com/inputsignal/images/
 com/inputsignal/images/logo.gif

Apache::AddHostPath would transform the following requested URL/URIs as follows:

 Input URL:  http://cvsroot.org/images/bg.gif
 Input URI:  /images/bg.gif
 Output URI: /images/bg.gif

 Input URL:  http://cvsroot.org/images/logo.gif
 Input URI:  /images/logo.gif
 Output URI: /org/cvsroot/images/logo.gif

 Input URL:  http://ransommoney.com/images/bg.gif
 Input URI:  /images/bg.gif
 Output URI: /com/ransommoney/images/bg.gif

 Input URL:  http://inputsignal.com/images/bg.gif
 Input URI:  /images/bg.gif
 Output URI: /com/images/bg.gif

It also correctly handles extra path info to CGI scripts.  For example if you add
the following files and dirs to the above example:

 cgi-bin/
 cgi-bin/magic.pl
 org/cvsroot/cgi-bin/
 org/cvsroot/cgi-bin/magic.pl

Apache::AddHostPath would transform the following requested URL/URIs as follows:

 Input URL: http://cvsroot.org/cgi-bin/magic.pl/param1/param2
 Input URI: /cgi-bin/magic.pl/param1/param2
 Output URI: /org/cvsroot/cgi-bin/magic.pl/param1/param2

 Input URL: http://ransommoney.com/cgi-bin/magic.pl/param1
 Input URI: /cgi-bin/magic.pl/param1
 Output URI: /cgi-bin/magic.pl/param1

You can debug this URI translation by setting your Apache LogLevel to "debug".
This will show add messages to your error log showing every URI combination
tested and which one it ended up using.

This module adds powerful yet simplistic inheritance capabilities to a
multi-domain server.  A number of domains could be set to a single flat document
root initially. Then individual files could be overridden for a hostname, or set of
hostnames, simply by creating the appropriate directory structures and specific 
files while leaving the rest of the domain untouched.

=head1 AUTHOR

Robert C W Jenks, rjenks@cvsroot.org

=head1 SEE ALSO

perl(1). L<mod_perl>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut
