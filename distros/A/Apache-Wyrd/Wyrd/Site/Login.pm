use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Site::Login;
use base qw(Apache::Wyrd::Interfaces::Setter Apache::Wyrd);
use Apache::Constants qw(OK);
use MIME::Base64;
use LWP::UserAgent;
use HTTP::Request::Common;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Site::Login - HTML Interface for Apache::Wyrd::Services::(Pre)Auth

=head1 SYNOPSIS

  <BASENAME::Login>
    <BASENAME::Template name="login">
      <input type="text" name="username"><br>
      <input type="text" name="password">
    </BASENAME::Template>
    <BASENAME::Template name="username">
      You are logged in as $:username
    </BASENAME::Template>
    <BASENAME::Template name="error">
      Login Error: Try again.<br>
      <input type="text" name="username"><br>
      <input type="text" name="password">
    </BASENAME::Template>
  </BASENAME::Login>

=head1 DESCRIPTION

The Login Wyrd is used to provide an interface on any page for logging in as
a user of the site.  It requires three templates: One for the login itself (called "login"), another to show that the user is logged in which can show information about which user is logged in (called 'username'), and a third for login errors (see SYNOPSIS for a very bare-bones example).

=head2 HTML ATTRIBUTES

NONE

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (void) C<_form_template> (scalar)

_form_template provides the hidden data that is needed to supply the
Apache::Wyrd::Services::Auth handler with the necessary security credentials
and return values.  It does not need to be overridden when using the Auth or
PreAuth Services.   It is provided as a method in order to handle any other
parameters the webmaster has added to the login process.

=cut

sub _form_template {
	my ($self) = @_;
	#provide a ultra-rudimentary login form template, or use the one provided by the form attribute.
	return $self->{'form'} || q(
<form action="$:key_url" method="post">
<input type="hidden" name="ticket" value="$:preauth_url">
<input type="hidden" name="on_success" value="$:on_success">
<input type="hidden" name="use_error" value="$:use_error">
$:data
</form>
);
}

=pod

=back

=head1 BUGS/CAVEATS

Reserves the _format_output method.

=cut

sub _format_output {
	my ($self) = @_;
	my $req = $self->dbl->req;

	#first check to see if there is a pending login.  A login is pending when the challenge is being
	#returned to the authorization handler.  If so, abort this request, asking the Handler to go through
	#the normal authorization challenge-response per Apache::Wyrd::Services::Auth
	my $challenge_param = $self->{'challenge_param'} = $req->dir_config('ChallengeParam') || 'challenge';
	if ($self->dbl->param($challenge_param)) {
		$self->abort('request authorization');
	}

	my %params = ();
	#there are two options for what CGI param to use to store the error message.  Look first for the string in the
	#cgi param "use_error", then if it isn't present, use the global ReturnError directory paraameter.  Failing that,
	#use the default "error_message"
	my $use_error = $params{'use_error'} = $self->{'use_error'} = $req->dir_config('ReturnError') || 'err_message';

	#then check for a login error;  An authorization handler redirects the client to the URL with the error
	#param set, so its presence is an indication that the login has failed.  If so, return the "error" template
	#of the login, setting the template with the params, which include the error message.
	my $error_message = $params{'error'} = $self->dbl->param($use_error);
	if ($error_message) {
		$self->_data($self->_set(\%params, $self->error));
		return;
	}

	#then check for a logged-in user.  If the user is logged in, use the "username" template, which has spaces for the
	#user's parameters.  This prevents confusion caused by presenting a second login and allows the login area to display
	#information about the user, i.e. "you are logged in as..."
	my $username = $params{'username'} = $self->dbl->user->{'username'};
	if ($username) {
		#TODO: make the user attributes a configurable option set by the User object.
		map {$params{$_} = $self->dbl->user->{$_}} qw(username password salutation firstname lastname organisation);
		$self->_data($self->_set(\%params, $self->username));
		return;
	}

	#Not logged in at all, set up a preauth login.  Do this by setting the necessary parameters per A::W::Services::Auth
	$params{'debug'} = $self->{'debug'} = $req->dir_config('Debug') || 0;
	$params{'ticketfile'} = $self->{'ticketfile'} = $req->dir_config('KeyDBFile') || '/tmp/keyfile';
	$params{'challenge_param'} = $self->{'challenge_param'} = $req->dir_config('ChallengeParam') || 'challenge';
	$params{'key_url'} = $self->{'key_url'} = $req->dir_config('LSKeyURL') || die "Must define LSKeyURL";
	$params{'preauth_url'} = $self->{'preauth_url'} = $req->dir_config('PreAuthURL') || die "Must define PreAuthURL";
	$params{'on_success'} = $self->{'on_success'} = encode_base64($self->dbl->self_url);
	$params{'data'} = $self->{'login'};

	$self->_data($self->_set(\%params, $self->_form_template));
	return;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Services::Auth

Authentication and authorization services for the Apache::Wyrd hierarchy.

=item Apache::Wyrd::Services::PreAuth

Authentication and Authorization on demand for the Apache::Wyrd hierarchy.

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;