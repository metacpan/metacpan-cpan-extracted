# Arch Perl library, Copyright (C) 2004 Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use 5.005;
use strict;

package Arch::LiteWeb;

use Socket;

sub new ($) {
	my $class = shift;
	my $self = {
		request_url      => undef,
		network_error    => undef,
		response_code    => undef,
		response_codestr => undef,
		response_error   => undef,
		response_headers => undef,
		response_content => undef,
	};
	return bless $self, $class;
}

sub _parse_url ($) {
	my $url = shift;
	$url =~ m!^http://([\w\.]+)(?::(\d+))?(?:(/.*))?$! or return;
	my $host = $1;
	my $port = $2 || 80;
	my $path = $3 || "/";
	return ($host, $port, $path);
}

sub get ($$%) {
	my $self = shift;
	my $url = shift;
	my %args = @_;
	$self->{request_url}      = undef;
	$self->{network_error}    = undef;
	$self->{response_code}    = undef;
	$self->{response_codestr} = undef;
	$self->{response_error}   = undef;
	$self->{response_headers} = undef;
	$self->{response_content} = undef;

	my $url_host = $args{url_host};
	my $url_port = $args{url_port};
	my $url_path = $args{url_path};
	if ($url) {
		($url_host, $url_port, $url_path) = _parse_url($url)
			or die "Unsupported url ($url), sorry\n";
	}

	my $use_proxy = $args{use_proxy};
	my $proxy_host = $args{proxy_host} || "";
	my $proxy_port = $args{proxy_port} || 80;
	if ($use_proxy && !$proxy_host && defined $ENV{http_proxy}) {
		($proxy_host, $proxy_port) = _parse_url($ENV{http_proxy})
			or die "Unsupported http_proxy url ($ENV{http_proxy}), sorry";
	}
	my $endl = $args{endl} || "\015\012";
	my $timeout = $args{timeout} || 20;
	my $user_agent = $args{user_agent} || "Arch::LiteWeb/0.1";
	my $max_redirect_depth = $args{max_redirect_depth} || 5;
	my $redirect_depth = 0;

	my $more_headers = "";
	$more_headers .= "Pragma: no-cache$endl" if $args{nocache};

HTTP_CONNECTION:
	my $url_port_str = $url_port? ":$url_port": "";
	$url = $self->{request_url} = "http://$url_host$url_port_str$url_path";
	print STDERR "getting: $url\n"
		if $ENV{DEBUG} && ("$ENV{DEBUG}" & "\2") ne "\0";

	my $host = $use_proxy? $proxy_host: $url_host;
	my $port = $use_proxy? $proxy_port: $url_port;
	my $iaddr = inet_aton($host) or do {
		$self->{network_error} = "Can't resolve host $host";
		return undef;
	};
	my $paddr = sockaddr_in($port, $iaddr);
	my $proto = getprotobyname('tcp');

	# should use POSIX instead or PERL_SIGNALS=unsafe to work in 5.8.*
	local $SIG{ALRM} = sub { die "timeout\n"; };
	alarm($timeout);
	eval {
		socket(SOCK, PF_INET, SOCK_STREAM, $proto) &&
		connect(SOCK, $paddr)
	} || do {
		$self->{network_error} = "Can't connect host $host";
		return undef;
	};
	alarm(0);
	select(SOCK); $| = 1; select(STDOUT);

	# send http request
	my $http_headers = "$endl" .
		"Host: $host$endl" .
		"Connection: close$endl" .
		"User-Agent: $user_agent$endl" .
		"$more_headers$endl";
	my $uri = $use_proxy? $self->{request_url}: $url_path;
	my $request = "GET $uri HTTP/1.1$http_headers";
	print STDERR "$request" if $ENV{DEBUG_MESSAGES};
	print SOCK $request;

	my $endl2 = "\015?\012";

	# read http response
	my $line = <SOCK>;
	unless ($line =~ m!^HTTP/1\.\d (\d+) (\w.*?)$endl2$!) {
		$line =~ s/$endl2$//;
		$self->{network_error} = "Invalid/unsupported HTTP response ($line)";
		return undef;
	}
	my $rc = $self->{response_code} = $1;
	$self->{response_codestr} = $2;

	my $text = join('', <SOCK>);
	print STDERR "$line$text" if $ENV{DEBUG_MESSAGES};

	my ($headers, $content) = split(/(?<=\012)$endl2/, $text, 2);
	my $unparsed;
	$headers = { map {
		/^([\w-]+):\s*(.*)$/?
			do { my ($k, $v) = (lc($1), $2); $k =~ s/-/_/g; ($k, $v) }:
			do { $unparsed .= "$_\n"; () };
	} split(/$endl2/, $headers) };
	$headers->{x_unparsed} = $unparsed if $unparsed;
	$self->{response_headers} = $headers;
	$self->{response_content} = $content;

	if ($rc == 301 || $rc == 302) {
		goto RETURN if $args{noredirect};

		# redirection
		++$redirect_depth < $max_redirect_depth or do {
			$self->{response_error} = "Too deep redirection, max depth is $max_redirect_depth";
			return undef;
		};
		my $new_url = $headers->{location};
		unless ($new_url) {
			$self->{response_error} = "Response code $rc with missing Location header";
			return undef;
		}
		($url_host, $url_port, $url_path) = _parse_url($new_url) or do {
			$self->{response_error} = "Response code $rc with unsupported Location value ($new_url)";
			return undef;
		};
		goto HTTP_CONNECTION;
	}
	unless ($rc == 200) {
		$self->{response_error} = "Non-success HTTP response code $rc";
		return undef;
	}
RETURN:
	return $content;
}

sub post ($$$%) {
	my $self = shift;
	my $url = shift;
	my $input = shift;
	die "Not implemented yet\n";
}

sub error ($) {
	my $self = shift;
	return $self->{network_error} || $self->{response_error};
}

sub error_with_url ($) {
	my $self = shift;
	my $error = $self->error;
	return undef unless $error;
	return "$error\nwhile fetching $self->{request_url}\n";
}

use vars '$AUTOLOAD';

sub AUTOLOAD ($@) {
	my $self = shift;
	my @params = @_;

	my $method = $AUTOLOAD;

	# remove the package name
	$method =~ s/.*://;
	# DESTROY messages should never be propagated
	return if $method eq 'DESTROY';

	die "No such method $AUTOLOAD\n" unless exists $self->{$method};
	return $self->{$method};
}

1;

__END__

=head1 NAME

Arch::LiteWeb - simple way to access web pages

=head1 SYNOPSIS 

    my $web = Arch::LiteWeb->new;
    my $content = $web->get("http://some.domain:81/some/path");
    die $web->error . " while processing " . $web->request_url
        unless $content;
    my $content_type = $web->response_headers->{content_type};

=head1 DESCRIPTION

This class provides a basic and easy to use support for the client-side HTTP.
It is supplied in order to avoid dependency on LWP. If such dependency is
not a problem, consider to use LWP instead that provides much better support
for HTTP and other protocols.

=head1 METHODS

The following class methods are available:

B<get>,
B<post>,
B<request_url>,
B<error>,
B<error_with_url>,
B<network_error>,
B<response_code>,
B<response_codestr>,
B<response_error>,
B<response_headers>,
B<response_content>.

=over 4

=item B<get> I<url> [I<params> ...]

Execute HTTP get of the given I<url> and return the html string or undef
on network/response error. Use other methods to get the details about
the error and the response.

I<params> is key-value hash, the following keys are supported:

    url_host            - only used if url is none
    url_port            - only used if url is none (80)
    url_path            - only used if url is none
    endl                - default is "\015\012"
    timeout             - default is 20 seconds
    user_agent          - default is "Arch::LiteWeb/0.1"
    nocache             - add a no-cache header
    noredirect          - don't follow redirect responses
    max_redirect_depth  - default is 5
    use_proxy           - default is false
    proxy_url           - proxy url ($http_proxy supported too)
    proxy_host          - only used if proxy_url is none
    proxy_port          - only used if proxy_url is none (80)

=item B<post> I<url> I<input> [I<params>]

Not implemented yet.

=item B<request_url>

Actual url of the last issued request or I<undef>. If partial redirect
responses are enabled, then the result is the last (non-redirect) url.

=item B<error>

If the last request resulted in error (i.e. B<get>/B<post> returned I<undef>),
then this method returns the error message, otherwise it returns I<undef>.
This is just a shortcut for B<network_error> || B<response_error>.

=item B<error_with_url>

Like error, but with "\nwhile fetching I<request_url>\n" text appended
if non undef.

=item B<network_error>

The network error message for the last request or I<undef>.

=item B<response_error>

The response error message for the last request or I<undef>.

=item B<response_code>

The last response code (integer) or I<undef>.

=item B<response_codestr>

The last response code (string) or I<undef>.

=item B<response_headers>

The last response headers (hashref of HTTP headers) or I<undef>.

=item B<response_content>

The last response content or I<undef>.
This is the same thing that the last B<get>/B<post> returns.

=back

=head1 BUGS

Not intended for use in mission-critical applications.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<LWP>, L<LWP::Simple>.

=cut
