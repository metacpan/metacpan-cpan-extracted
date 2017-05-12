use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Services::LoginServer;
our $VERSION = '0.98';
use Apache::Wyrd::Services::CodeRing;
use Apache::Wyrd::Services::TicketPad;
use Apache::Wyrd::Request;
use Apache::Constants qw(AUTH_REQUIRED HTTP_SERVICE_UNAVAILABLE HTTP_MOVED_TEMPORARILY NOT_FOUND OK);
use Apache::Util;
use MIME::Base64;
use LWP::UserAgent;
use HTTP::Request::Common;

=pod

=head1 NAME

Apache::Wyrd::Services::LoginServer - Login service For Auth object

=head1 SYNOPSIS

  <Location /logins/login.html>
    SetHandler  perl-script
    PerlHandler Apache::Wyrd::Services::LoginServer
    PerlSetVar  TicketDBFile   /var/run/www/ticketfile.db
    PerlSetVar  Debug   0
  </Location>

=head1 DESCRIPTION

The Login Server provides SSL encryption for a login to a
Apache::Wyrd::Auth module when it must run on an insecure port.  This
behavior is described in the documentation for
C<Apache::Wyrd::Services::Auth>.

It uses the TicketPad module to keep a cache of 100 recent tickets.  If
presented with a POST request with a 'key' parameter, it stores the key
and returns OK.  If presented with an authorization set (on_success,
[on_fail], user, password, ticket), it returns the data to the server
via a redirected GET request with the challenge parameter set to the
encrypted data.

The TicketPad has a limited capacity, and old tickets are removed as new
ones are added.  If the authorization request is so stale it asks for a
ticket that has been discarded, the LoginServer returns the status
HTTP_SERVICE_UNAVAILABLE.

All other accesses fail with an AUTH_REQUIRED

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (RESPONSE) C<handler> (Apache)

The handler handles all functions.

=cut

sub handler {
	my $req = shift;
	my $apr = Apache::Wyrd::Request->instance($req);
	my $debug = $req->dir_config('Debug');
	my $ticket = $apr->param('ticket');
	my $key = $apr->param('key');
	my $self_url = 'https://' . $req->hostname . $req->uri;
	my $use_error = $req->dir_config('ReturnError') || 'err_message';
	$debug && warn("Ticket:Key -> ", $ticket, ':' , $key);
	my $ticketfile = $req->dir_config('TicketDBFile') || '/tmp/ticketfile';
	if ($key) {
		#if param 'key' is set, store the ticket for later retrieval
		#by the login process.
		return AUTH_REQUIRED unless ($ticket);
		my $pad = Apache::Wyrd::Services::TicketPad->new($ticketfile);
		$pad->add_ticket($ticket, $key);
		$req->headers_out;
		$req->print('Key accepted...');
		return OK;
	} elsif ($ticket) {

		#get info on what to do if this fails to be handed back to the
		#Auth handler.
		my $success_url = decode_base64($apr->param('on_success')) || return AUTH_REQUIRED;

		#url was escaped by the Auth module
		$success_url = Apache::Util::unescape_uri($success_url);

		#if the url had a query string, the challenge should be appended to it.
		my $fail_url = $apr->param('on_fail') || $success_url;

		#get necessaries
		my $ticket = $apr->param('ticket');
		#a URL for a ticket means the ticket must be picked up elsewhere at a Pre-Auth server.
		if ($ticket =~ /^http/) {
			my $ua = LWP::UserAgent->new;
			$ua->timeout(60);
			my $response = $ua->request(POST $ticket,
				[
					url		=>	$self_url
				]
			);
			my $status = $response->status_line;
			unless ($status =~ /200|OK/) {
				my $joiner = '?';
				$joiner = '&' if ($fail_url =~ /\?/);
				$debug && warn("key could not be generated.  The pre-auth URL returned the status: $status");
				$req->custom_response(HTTP_MOVED_TEMPORARILY, "$fail_url$joiner$use_error" . '=Authorization%20Server%20is%20down.');
				return HTTP_MOVED_TEMPORARILY;
			}
			my $content = $response->content;
			$content =~ s/\s*//gsm;
			if ($content =~ /http/) {
				$req->custom_response(HTTP_MOVED_TEMPORARILY, $content);
				return HTTP_MOVED_TEMPORARILY;
			}
			$ticket = $content;
		}
		my $user = $apr->param('username') || 'anonymous';
		my $password = $apr->param('password');

		#find key
		$debug && warn('finding ' . $ticket);
		my $pad = Apache::Wyrd::Services::TicketPad->new($ticketfile);
		$key = $pad->find($ticket);
		unless ($key) {
			my $joiner = '?';
			$joiner = '&' if ($fail_url =~ /\?/);
			$debug && warn("key could not be found.  Server key has probably been lost due to a re-initializtion of Apache::Wyrd::Services::CodeRing.  Nothing for it but to send the browser back.");
			$req->custom_response(HTTP_MOVED_TEMPORARILY, "$fail_url$joiner$use_error" . '=Login%20Server%20has%20been%20re-started%20please%20try%20again.');
			return HTTP_MOVED_TEMPORARILY;
		}
		my $joiner = '?';
		$joiner = '&' if ($success_url =~ /\?/);
		$debug && warn("found the key $key");
		$key = Apache::Util::unescape_uri($key);
		my $ex_cr = Apache::Wyrd::Services::CodeRing->new({key => $key});
		$debug && warn("Generated a new decryption ring with the found key");
		my $data = "$user\t$password";
		$data = $ex_cr->encrypt(\$data);
		$debug && warn("Data encrypted with the key");
		$req->custom_response(HTTP_MOVED_TEMPORARILY, "$success_url" . $joiner . 'challenge=' . $ticket . ':' . $$data);
		$debug && warn("loginserver has set the challenge to $$data");
		return HTTP_MOVED_TEMPORARILY;
	} else {
		return AUTH_REQUIRED
	}
}

=pod

=back

=head2 PERLSETVAR DIRECTIVES

=over

=item TicketDBFile

Location of the DB file holding the tickets.  It should be writable by
the Apache process.  It should probably be unreadable by anyone else.

=item Debug

Set to true to allow debugging, which will go to the error log.

=head1 BUGS/CAVEATS/RESERVED METHODS

Size of the ticketpad is not configurable.

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd::Services::Auth

Authorization handler

=item Apache::Wyrd::Services::Key

Shared-memory encryption key and cypher.

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut


1;
