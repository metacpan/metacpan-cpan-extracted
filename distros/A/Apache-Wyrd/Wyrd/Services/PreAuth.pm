use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Services::PreAuth;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Services::Auth);
use Apache::Constants qw(OK);
use LWP::UserAgent;
use HTTP::Request::Common;

=pod

=head1 NAME

Apache::Wyrd::Services::PreAuth - Login to Apache::Wyrd::Services::Auth directly

=head1 SYNOPSIS

  <Directory /www/someplace/preauth>
    SetHandler perl-script
    PerlHandler  Apache::Wyrd::Services::PreAuth
  </Directory>

=head1 DESCRIPTION

C<Apache::Wyrd::Services::PreAuth> is a much more simple form of the
C<Apache::Wyrd::Services::Auth> class of handlers, in that it represents
only that step in the process where a C<Apache::Wyrd::Services::LoginServer>
object is used to authenticate the user.  Typically this is done to provide
a login identity before a restricted page/directory is requested, rather than
the redirect-to-login-if-unauthorized model that C<Apache::Wyrd::Services::Auth>
uses.

Otherwise, it behaves the same as a C<Apache::Wyrd::Services::PreAuth>
handler, and uses the same dirconfig parameters.

=cut

sub handler : method {
	my ($class, $req) = @_;
	my $self = {};
	bless ($self, $class);
	my $apr = Apache::Wyrd::Request->instance($req);
	$self->{'ticketfile'} = $req->dir_config('KeyDBFile') || '/tmp/keyfile';
	my $debug = $req->dir_config('Debug');
	my $scheme = 'http';
	$scheme = 'https' if ($ENV{'HTTPS'} eq 'on');
	my $port = '';
	$port = ':' . $req->server->port unless ($req->server->port == 80);

	#Get an encryption key and a ticket number
	my ($key, $ticket) = $self->generate_ticket;

	#Send that pair to the Login Server
	my $key_url = $req->dir_config('LSKeyURL') || $apr->param('url')
		|| die "Either provide the url param or define the LSKeyURL directory configuration";
	$key_url = 'https://' . $req->hostname . $key_url unless ($key_url =~ /^https?:\/\//i);
	if ($key_url =~ /^https:\/\//i) {
		eval('use IO::Socket::SSL');
		die "LWP::UserAgent needs to support SSL to use a login server over https.  Install IO::Socket::SSL and make sure it works."
			if ($@);
	}
	my $ua = LWP::UserAgent->new;
	$ua->timeout(60);
	my $response = $ua->request(POST $key_url,
		[
			key		=>	$key,
			ticket	=>	$ticket
		]
	);
	my $status = $response->status_line;

	if ($status !~ /200|OK/) {
		my $failed_url = $req->dir_config('LSDownURL');
		$failed_url = $scheme . '://' . $req->hostname . $port . $failed_url unless ($failed_url =~ /^http/i);
		print $failed_url;
	} else {
		print $ticket;
	}
	return OK;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Services::Auth

Authentication and Authorization handler for the C<Apache::Wyrd> hierarchy.

=item Apache::Wyrd::User

Generic User object for the Wyrd hierarchy.

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;