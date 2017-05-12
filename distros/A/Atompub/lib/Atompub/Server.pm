package Atompub::Server;

use strict;
use warnings;

use Atompub;
use Digest::SHA qw(sha1);
use MIME::Base64 qw(encode_base64 decode_base64);
use HTTP::Status;
use XML::Atom;

use base qw(XML::Atom::Server);

sub send_http_header {
    my($server) = @_;
    my $type = $server->response_content_type || 'application/atom+xml';
    if ($ENV{MOD_PERL}) {
        $server->{apache}->status($server->response_code || RC_OK);
        $server->{apache}->send_http_header($type);
    }
    else {
        $server->{cgi_headers}{-status} = $server->response_code || RC_OK;
        $server->{cgi_headers}{-type} = $type;
        print $server->{cgi}->header(%{ $server->{cgi_headers} });
    }
}

sub realm {
    my($server, $realm) = @_;
    $server->{realm} = $realm if $realm;
    $server->{realm};
}

sub get_auth_info {
    my($server) = @_;
    my %param;

    # Basic Authentication
    if (my $auth = $server->request_header('Authorization')) {
        return unless $auth =~ s/^\s*Basic\s+//;
        require MIME::Base64;
	my $val = MIME::Base64::decode($auth);
	my($userid, $password) = split /:/, $val, 2;
	%param = (userid => $userid, password => $password);
    }
    # WSSE Authentication
    elsif (my $req = $server->request_header('X-WSSE')) {
        $req =~ s/^(?:WSSE|UsernameToken) //;
	for my $i (split /,\s*/, $req) {
            my($k, $v) = split /=/, $i, 2;
	    $v =~ s/^"//;
	    $v =~ s/"$//;
	    $param{$k} = $v;
        }
    }
    else {
        return $server->auth_failure(RC_UNAUTHORIZED, 'Basic or WSSE authentication required');
    }

    \%param;
}

sub authenticate {
    my($server) = @_;

    my $auth = $server->get_auth_info || return;

    # Basic Authentication
    if (defined $auth->{userid}) {
        my $password = $server->password_for_user($auth->{userid});
	return $server->auth_failure(RC_FORBIDDEN, 'Invalid login')
	    if !defined $password || $password ne $auth->{password};
    }
    # WSSE Authentication
    else {
        for my $f (qw(Username PasswordDigest Nonce Created)) {
	    return $server->auth_failure(RC_BAD_REQUEST, "X-WSSE requires $f")
	        unless $auth->{$f};
	}
	my $password = $server->password_for_user($auth->{Username});
	return $server->auth_failure(RC_FORBIDDEN, 'Invalid login')
            unless defined $password;
	my $expected
            = encode_base64(sha1(decode_base64($auth->{Nonce}).$auth->{Created}.$password), '');
	return $server->auth_failure(RC_FORBIDDEN, 'Invalid login')
	    unless $expected eq $auth->{PasswordDigest};
    }

    1;
}

sub auth_failure {
    my($server) = @_;
    my $realm = $server->realm || 'Atompub';
    $server->response_header(
        'WWW-Authenticate',
        qq{Basic realm="$realm", WSSE profile="UsernameToken"},
    );
    $server->error(@_);
}

1;
__END__

=head1 NAME

Atompub::Server - A server for the Atom Publishing Protocol


=head1 SYNOPSIS

    package My::Server;
    use base qw(Atompub::Server);

    sub handle_request {
        my($server) = @_;
        $server->authenticate or return;
        my $method = $server->request_method;
        if ($method eq 'POST') {
            return $server->new_post;
        }
        ...
    }

    my %Passwords;
    sub password_for_user {
        my($server, $username) = @_;
        $Passwords{$username};
    }

    sub new_post {
        my($server) = @_;
        my $entry = $server->atom_body or return;
        # $entry is an XML::Atom::Entry object.
        # ... Save the new entry ...
    }

    package main;
    my $server = My::Server->new;
    $server->run;

=head1 DESCRIPTION

L<Atompub::Server> provides a base class for Atom Publishing Protocol servers.
It handles all core server processing, and Basic and WSSE authentication.
It can also run as either a mod_perl handler or as part of a CGI program.

It does not provide functions specific to any particular implementation,
such as creating an entry, retrieving a list of entries, deleting an entry, etc.
Implementations should subclass L<Atompub::Server>, overriding the
C<handle_request> method, and handle all functions such as this themselves.

L<Atompub::Server> extends L<XML::Atom::Server>, and basically provides same functions.
However, this module has been fixed based on the Atom Publishing Protocol
described at L<http://www.ietf.org/rfc/rfc5023.txt>,
and supports Basic authentication rather than WSSE.


=head1 SUBCLASSING

=head2 Request Handling

Subclasses of L<Atompub::Server> must override the C<handle_request>
method to perform all request processing.
The implementation must set all response headers, including the response
code and any relevant HTTP headers, and should return a scalar representing
the response body to be sent back to the client.

For example:

    sub handle_request {
        my($server) = @_;
        my $method = $server->request_method;
        if ($method eq 'POST') {
            return $server->new_post;
        }
        # ... handle GET, PUT, etc
    }

    sub new_post {
        my($server) = @_;
        my $entry = $server->atom_body or return;

        # Implementation-specific
        my $id = save_this_entry($entry);
        my $location = join '/', $server->uri, $id;
	my $etag = calc_etag($entry);

        $server->response_header(Location => $location);
        $server->response_header(ETag     => $etag    );
        $server->response_code(RC_CREATED);
        $server->response_content_type('application/atom+xml;type=entry');

	# Implementation-specific
        return serialize_entry($entry);
    }

=head2 Authentication

Servers that require authentication should override the C<password_for_user> method.
Given a username (from the Authorization or WSSE header),
C<password_for_user> should return that user's password in plaintext.
If the supplied username doesn't exist in your user database or alike,
just return C<undef>.

For example:

    my %Passwords = (foo => 'bar');   # The password for "foo" is "bar".
    sub password_for_user {
        my($server, $username) = @_;
        $Passwords{$username};
    }

=over 2

=item * Basic Authentication

I<realm> must be assigned before authentication for Basic authentication.

    $server->realm('MySite');

If your server runs as a CGI program and authenticates by Basic authenticate,
you should use authentication mechanism of the http server, like C<.htaccess>.

=item * WSSE Authentication

Any pre-configuration is not required for WSSE.
The password returned from C<password_for_user> will be combined with the nonce
and the creation time to generate the digest, which will be compared
with the digest sent in the WSSE header.

=back


=head1 METHODS

L<Atompub::Server> provides a variety of methods to be used by subclasses
for retrieving headers, content, and other request information, and for
setting the same on the response.

=head2 $server->realm

If called with an argument, sets the I<realm> for Basic authentication.

Returns the current I<realm> that will be used when receiving requests.

=head2 $server->send_http_header($content_type)

=head2 $server->get_auth_info

=head2 $server->authenticate

=head2 $server->auth_failure($status, $message)

=head2 oether methods

Descriptions are found in L<XML::Atom::Server>.


=head1 USAGE

Once you have defined your server subclass, you can set it up either as a
CGI program or as a mod_perl handler.

See L<XML::Atom::Server> in details.


=head1 SEE ALSO

L<XML::Atom>
L<XML::Atom::Service>
L<Atompub>
L<Catalyst::Controller::Atompub>


=head1 AUTHOR

Takeru INOUE, E<lt>takeru.inoue _ gmail.comE<gt>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
