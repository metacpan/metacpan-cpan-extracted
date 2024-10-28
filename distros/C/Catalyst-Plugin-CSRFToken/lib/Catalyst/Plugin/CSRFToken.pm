package Catalyst::Plugin::CSRFToken;

use Moo::Role;
use WWW::CSRF ();
use Bytes::Random::Secure ();


our $VERSION = '0.008';
 
has 'default_csrf_token_secret' => (is=>'ro', required=>1, builder=>'_build_default_csrf_token_secret');
 
  sub _build_default_csrf_token_secret {
    if(my $config = shift->config->{'Plugin::CSRFToken'}) {
      return $config->{default_secret} if exists $config->{default_secret};
    }
    return;
  }

has 'default_csrf_token_max_age' => (is=>'ro', required=>1, builder=>'_build_default_csrf_token_max_age');
 
  sub _build_default_csrf_token_max_age {
    if(my $config = shift->config->{'Plugin::CSRFToken'}) {
      return $config->{max_age} if exists $config->{max_age};
    }
    return 60*60; # One hour in seconds
  }

has 'csrf_token_param_key' => (is=>'ro', required=>1, builder=>'_build_csrf_token_param_key');
 
  sub _build_csrf_token_param_key {
    if(my $config = shift->config->{'Plugin::CSRFToken'}) {
      return $config->{param_key} if exists $config->{param_key};
    }
    return 'csrf_token';
  }

has 'auto_check_csrf_token' => (is=>'ro', required=>1, builder=>'_build_auto_check_csrf_token');
 
  sub _build_auto_check_csrf_token {
    if(my $config = shift->config->{'Plugin::CSRFToken'}) {
      return $config->{auto_check} if exists $config->{auto_check};
      return $config->{auto_check_csrf_token} if exists $config->{auto_check_csrf_token};
    }
    return 0;
  }

sub default_csrf_session_id {
  my $self = shift;
  $self->change_session_id unless $self->sessionid;
  return $self->sessionid;
}

sub random_token {
  my ($self, $length) = @_;
  $length = 48 unless $length;
  return Bytes::Random::Secure::random_bytes_base64($length,'');
}

sub single_use_csrf_token {
  my ($self) = @_;
  my $token = $self->random_token;
  $self->session(current_csrf_token => $token);
  return $token;
}

sub check_single_use_csrf_token {
  my ($self, %args) = @_;
  my $token = exists($args{csrf_token}) ? $args{csrf_token} : $self->find_csrf_token_in_request;
  return 0 unless $token;
  if(my $session_token = delete($self->session->{current_csrf_token})) {
    return $session_token eq $token ? 1:0;
  } else {
    return 0;
  }
}

sub csrf_token {
  my ($self, %args) = @_;
  my $session = exists($args{session}) ? $args{session} : $self->default_csrf_session_id;
  my $token_secret = exists($args{token_secret}) ? $args{token_secret}  : $self->default_csrf_token_secret;

  return my $token = WWW::CSRF::generate_csrf_token($session, $token_secret);
}

sub find_csrf_token_in_request {
  my $self = shift;
  if(my $header_token = $self->request->header('X-CSRF-Token')) {
    return $header_token;
  } else {
    return $self->req->body_parameters->{$self->csrf_token_param_key}
      if exists($self->req->body_parameters->{$self->csrf_token_param_key});
    return $self->req->body_data->{$self->csrf_token_param_key}
      if exists($self->req->body_data->{$self->csrf_token_param_key});      
    return undef;
  }
}

sub is_csrf_token_expired {
  my ($self, %args) = @_;
  my $token = exists($args{csrf_token}) ? $args{csrf_token} : $self->find_csrf_token_in_request;
  my $session = exists($args{session}) ? $args{session} : $self->default_csrf_session_id;
  my $token_secret = exists($args{token_secret}) ? $args{token_secret}  : $self->default_csrf_token_secret;
  my $max_age = exists($args{max_age}) ? $args{max_age}  : $self->default_csrf_token_max_age;

  return 0 unless $token;
  return 1 if WWW::CSRF::check_csrf_token(
    $session, 
    $token_secret,
    $token, 
    +{ MaxAge=>$max_age }
  ) == WWW::CSRF::CSRF_EXPIRED;
  
  return 0;
}

sub invalid_csrf_token {
  return shift->(@_)->check_csrf_token ? 0:1;
}

sub check_csrf_token {
  my ($self, %args) = @_;
  my $token = exists($args{csrf_token}) ? $args{csrf_token} : $self->find_csrf_token_in_request;
  my $session = exists($args{session}) ? $args{session} : $self->default_csrf_session_id;
  my $token_secret = exists($args{token_secret}) ? $args{token_secret}  : $self->default_csrf_token_secret;
  my $max_age = exists($args{max_age}) ? $args{max_age}  : $self->default_csrf_token_max_age;
 
  return 0 unless $token;

  my $status = WWW::CSRF::check_csrf_token(
    $session, 
    $token_secret,
    $token, 
    +{ MaxAge=>$max_age }
  );
  $self->stash(_last_csrf_token_status => $status);

  return 0 unless  $status == WWW::CSRF::CSRF_OK;
  return 1;
}

sub last_checked_csrf_token_expired {
  my ($self) = @_;
  my $status = $self->stash->{_last_csrf_token_status};

  return Catalyst::Exception->throw(message => 'csrf_token has not been checked yet') unless defined $status;
  return $status == WWW::CSRF::CSRF_EXPIRED ? 1:0;
}

sub delegate_failed_csrf_token_check {
  my $self = shift;
  return $self->controller->handle_failed_csrf_token_check($self) if $self->controller->can('handle_failed_csrf_token_check');
  return $self->handle_failed_csrf_token_check if $self->can('handle_failed_csrf_token_check');

  # If we get this far we need to create a rational default error response and die
  $self->response->status(403);
  $self->response->content_type('text/plain');
  $self->response->body('Forbidden: Invalid CSRF token.');
  $self->finalize;
  Catalyst::Exception->throw(message => 'csrf_token failed validation');
}

sub validate_csrf_token_if_required {
  my $self = shift;
  return (
    (
      ($self->req->method eq 'POST') ||
      ($self->req->method eq 'PUT') ||
      ($self->req->method eq 'PATCH')
    )
      && 
    (
      !$self->check_csrf_token &&
      !$self->check_single_use_csrf_token
    )
  );
}

sub process_csrf_token {
  my $self = shift;
  return 1 unless (
    ($self->req->method eq 'POST') ||
    ($self->req->method eq 'PUT') ||
    ($self->req->method eq 'PATCH')
  );

  if($self->can('session') && $self->session->{current_csrf_token}) {
    return $self->check_single_use_csrf_token;
  } else {
    return $self->check_csrf_token;
  }
}

around 'dispatch', sub {
  my ($orig, $self, @args) = @_;
  if(
    $self->auto_check_csrf_token
      &&
    $self->validate_csrf_token_if_required
  ) {
    return $self->delegate_failed_csrf_token_check;
  }
  return $self->$orig(@args);
};

1;

=head1 NAME

Catalyst::Plugin::CSRFToken - Generate tokens to help prevent CSRF attacks

=head1 SYNOPSIS
 
    package MyApp;
    use Catalyst;

    # The default functionality of this plugin expects a method 'sessionid' which
    # is associated with the current user session.  This method is provided by the
    # session plugin but you can provide your own or override 'default_csrf_session_id'
    # if you know what you are doing!

    MyApp->setup_plugins([qw/
      Session
      Session::State::Cookie
      Session::Store::Cookie
      CSRFToken
    /]);

    MyApp->config(
      'Plugin::CSRFToken' => { default_secret=>'changeme', auto_check_csrf_token => 1 }
    );
         
    MyApp->setup;
 
    package MyApp::Controller::Root;
 
    use Moose;
    use MooseX::MethodAttributes;
 
    extends 'Catalyst::Controller';
 
    sub login_form :Path(login_form) Args(0) {
      my ($self, $c) = @_;

      # A Basic manual check example if you leave 'auto_check_csrf_token' off (default)
      if($c->req->method eq 'POST') {
        Catalyst::Exception->throw(message => 'csrf_token failed validation')
          unless $c->check_csrf_token;
      }

      $c->stash(csrf_token => $c->csrf_token);  # send a token to your view and make sure you
                                                # add it to your form as a hidden field
    }
 
=head1 DESCRIPTION

This uses L<WWW::CSRF> to generate hard to guess tokens tied to a give web session.  You can
generate a token and pass it to your view layer where it should be added to the form you are
trying to process, typically as a hidden field called 'csrf_token' (althought you can change
that in configuration if needed).

Its probably best to enable 'auto_check_csrf_token' true since that will automatically check
all POST, PUT and PATCH request (but of course if you do this you have to be sure to add the token
to every single form.  If you need to just use this on a few forms (for example you have a 
large legacy application and need to improve security in steps) you can roll your own handling
via the C<check_csrf_token> method as in the example given above.

=head1 METHODS

This Plugin adds the following methods

=head2 random_token

This just returns base64 random string that is cryptographically secure and is generically
useful for anytime you just need a random token.   Default length is 48 but please note 
that the actual base64 length will be longer.  

=head2 csrf_token ($session, $token_secret)

Generates a token for the current request path and user session and returns this string
in a form suitable to put into an HTML form hidden field value.  Accepts the following 
positional arguments:

=over 4

=item $session

This is a string of data which is somehow linked to the current user session.   The default
is to call the method 'default_csrf_session_id' which currently just returns the value of
'$c->sessionid'.  You can pass something here if you want a tigher scope (for example you
want a token that is scoped to both the current user id and a given URL path).

=item $token_secret

Default is whatever you set the configuration value 'default_secret' to.

=back

=head2 check_csrf_token

Return true or false depending on if the current request has a token which is valid.  Accepts the
following arguments in the form of a hash:

=over 4

=item csrf_token

The token to check.   Default behavior is to invoke method C<find_csrf_token_in_request> which
looks in the HTTP request header and body parameters for the token.  Set this to validate a
specific token.

=item session

This is a string of data which is somehow linked to the current user session.   The default
is to call the method 'default_csrf_session_id' which currently just returns the value of
'$c->sessionid'.  You can pass something here if you want a tigher scope (for example you
want a token that is scoped to both the current user id and a given URL path).

It should match whatever you passed to C<csrf_token> for the request token you are trying to validate.

=item token_secret

Default is whatever you set the configuration value 'default_secret' to.  Allows you to specify a
custom secret (it should match whatever you passed to C<csrf_token>).

=item max_age

Defaults to whatever you set configuration value <max_age>.  A value in seconds that measures how
long a token is considered 'not expired'.  I recommend setting this to as short a value as is 
reasonable for your users to linger on a form page.

=back

Example:

    $c->check_csrf_token(max_age=>(60*10)); # Don't accept a token that is older than 10 minutes.

B<NOTE>: If the token 

=head2 invalid_csrf_token

Returns true if the token is invalid.  This is just the inverse of 'check_csrf_token' and
it accepts the same arguments.

=head2 last_checked_csrf_token_expired

Return true if the last checked token was considered expired based on the arguments used to
check it.  Useful if you are writing custom checking code that wants to return a different
error if the token was well formed but just too old.   Throws an exception if you haven't
actually checked a token.

=head2 single_use_csrf_token

Creates a token that is saved in the session.  Unlike 'csrf_token' this token is not crytographically
signed so intead its saved in the user session and can only be used once.   You might prefer
this approach for classic HTML forms while the other approach could be better for API applications
where you don't want the overhead of a user session (or where you'd like the client to be able to
open multiply connections at once.


=head2 check_single_use_csrf_token

Checks a single_use_csrf_token.   Accepts the token to check but defaults to getting it from
the request if not provided.

=head1 CONFIGURATION

This plugin permits the following configurations keys

=head2 default_secret

String that is used in part to generate the token to help ensure its hard to guess.

=head2 max_age

Default to 3600 seconds (one hour).   This is the length of time before the generated token
is considered expired.  One hour is probably too long. You should set it to the shortest
time reasonable.

=head2 param_key

Defaults to 'csrf_token'.   The Body param key we look for the token.

=head2 auto_check_csrf_token

Defaults to false.   When set to true we automatically do a check for all POST, PATCH and
PUT method requests and if the check fails we delegate handling in the following way:

If the current controller does a method called 'handle_failed_csrf_token_check' we invoke that
passing the current context.

Else if the application class does a method called 'handle_failed_csrf_token_check' we invoke
that instead.

Failing either of those we just throw an exception and set a rational message body (403 Forbidden:
Bad CSRF token).  In all cases if there's a CSRF error we skip the 'dispatch' phase so none of
 your actions will run, including any global 'end' actions.  

=head1 AUTHOR

  John Napiorkowski <jnapiork@cpan.org>
 
=head1 COPYRIGHT
 
Copyright (c) 2023 the above named AUTHOR
 
=head1 LICENSE
 
You may distribute this code under the same terms as Perl itself.
 
=cut
