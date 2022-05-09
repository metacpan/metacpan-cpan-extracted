package Catalyst::Plugin::CSRFToken;

use Moo::Role;
use WWW::CSRF ();
 
our $VERSION = '0.002';
 
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
    }
    return 0;
  }

sub default_csrf_session_id {
  my $self = shift;
  return $self->sessionid;
}

sub csrf_token {
  my ($self, %args) = @_;
  my $id = exists($args{id}) ? $args{id} : $self->default_csrf_session_id;
  my $token_secret = exists($args{token_secret}) ? $args{token_secret}  : $self->default_csrf_token_secret;

  return my $token = WWW::CSRF::generate_csrf_token($id, $token_secret);
}

sub find_csrf_token_in_request {
  my $self = shift;
  if(my $header_token = $self->request->header('X-CSRF-Token')) {
    return $header_token;
  } else {
    return $self->req->body_parameters->{$self->csrf_token_param_key};
  }
}

sub check_csrf_token {
  my ($self, %args) = @_;
  my $token = exists($args{csrf_token}) ? $args{csrf_token} : $self->find_csrf_token_in_request;
  my $session = exists($args{session}) ? $args{session} : $self->default_csrf_session_id;
  my $token_secret = exists($args{token_secret}) ? $args{token_secret}  : $self->default_csrf_token_secret;
 
  return 0 unless $token;
  return 0 unless WWW::CSRF::check_csrf_token(
    $session, 
    $token_secret,
    $token, 
    +{ MaxAge=>$self->default_csrf_token_max_age }
  ) == WWW::CSRF::CSRF_OK;
  
  return 1;
}

sub delegate_failed_csrf_token_check {
  my $self = shift;
  return $self->controller->handle_failed_csrf_token_check($self) if $self->controller->can('handle_failed_csrf_token_check');
  return $self->handle_failed_csrf_token_check if $self->can('handle_failed_csrf_token_check');
  return Catalyst::Exception->throw(message => 'csrf_token failed validation');
}

after 'prepare_action', sub {
  my $self = shift;
  return unless $self->auto_check_csrf_token;
  if(
      (
        ($self->req->method eq 'POST') ||
        ($self->req->method eq 'PUT') ||
        ($self->req->method eq 'PATCH')
      ) &&
      !$self->check_csrf_token
  ) {
    return $self->delegate_failed_csrf_token_check;
  }
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
all POST, bPUT and PATCH request (but of course if you do this you have to be sure to add the token
to every single form.  If you need to just use this on a few forms (for example you have a 
large legacy application and need to improve security in steps) you can roll your own handling
via the C<check_csrf_token> method as in the example given above.

=head1 METHODS

This Plugin adds the following methods

=head2 csrf_token

Generates a token for the current request path and user session and returns this string
in a form suitable to put into an HTML form hidden field value.

=head2 check_csrf_token

Return true or false depending on if the current request has a token which is valid.

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

Failing either of those we just throw an expection which you can catch manually in the global
'end' action or else it will fail thru eventually to Catalyst's default error handler.


=head1 AUTHOR

  John Napiorkowski <jnapiork@cpan.org>
 
=head1 COPYRIGHT
 
Copyright (c) 2022 the above named AUTHOR
 
=head1 LICENSE
 
You may distribute this code under the same terms as Perl itself.
 
=cut
