package Catalyst::Plugin::CSRFToken;

use strict;
use warnings;
use Moose::Role;
use Digest::SHA qw(hmac_sha256_hex);
use MIME::Base64 qw(encode_base64url decode_base64url);
use Crypt::URandom qw(urandom);

our $VERSION = '1.001';

requires 'session', 'stash', 'req', 'detach';

has 'csrf_token_session_key' => (is => 'ro', required => 1, builder => '_build_csrf_token_session_key');

sub _build_csrf_token_session_key {
  if(my $config = shift->config->{'Plugin::CSRFToken'}) {
    return $config->{session_key} if exists $config->{session_key};
  }
  return '_csrf_token';
}

has 'csrf_token_param_key' => (is => 'ro', required => 1, builder => '_build_csrf_token_param_key');

sub _build_csrf_token_param_key {
  if(my $config = shift->config->{'Plugin::CSRFToken'}) {
    return $config->{param_key} if exists $config->{param_key};
    return $config->{token_param_key} if exists $config->{token_param_key};
  }
  return 'csrf_token';
}

has 'csrf_max_age' => (is => 'ro', required => 1, builder => '_build_csrf_max_age');

sub _build_csrf_max_age {
  if(my $config = shift->config->{'Plugin::CSRFToken'}) {
    return $config->{max_age} if exists $config->{max_age}; # Backwards compatibility
  }
  return 3600;
}

has 'csrf_default_secret' => (
  is => 'ro',
  predicate => 'has_csrf_default_secret',
  builder => '_build_csrf_default_secret',
);

sub _build_csrf_default_secret {
  if(my $config = shift->config->{'Plugin::CSRFToken'}) {
    return $config->{default_secret} if exists $config->{default_secret};
  }
  return undef;
}

has 'auto_check_csrf_token' => ( is => 'ro', required => 1, builder => '_build_auto_check_csrf_token' );

sub _build_auto_check_csrf_token {
  if(my $config = shift->config->{'Plugin::CSRFToken'}) {
    return $config->{auto_check} if exists $config->{auto_check};
    return $config->{auto_check_csrf_token} if exists $config->{auto_check_csrf_token};
  }
  return 0;
}

has 'single_use_csrf_token' => (is => 'ro', required => 1, builder => '_build_single_use_csrf_token');

sub _build_single_use_csrf_token {
  if(my $config = shift->config->{'Plugin::CSRFToken'}) {
    return $config->{single_use_csrf_token} if exists $config->{single_use_csrf_token};
    return $config->{single_use} if exists $config->{single_use};
  }
  return 0;
}

before 'dispatch' => sub {
  my $c = shift;
  $c->check_csrf_token 
    if (
      ($c->auto_check_csrf_token || $c->action->attributes->{EnableCSRF})
      && $c->req->method =~ /^(POST|PUT|DELETE|PATCH)$/i
    );
};

sub check_csrf_token {
  my $c = shift;

  $c->log->debug('Checking CSRF token') if $c->debug;

  if ($c->action->attributes->{DisableCSRF}) {
    $c->log->debug('Skipping CSRF check for action '.$c->action->reverse) if $c->debug;
    return 1;
  }

  my $token   = $c->find_csrf_token_in_request
    or return $c->delegate_failed_csrf_token_check;

  $c->log->debug("Found CSRF token '$token' in request") if $c->debug;

  # $form_id is extracted from $token, in the form of "form_id:token"
  my $form_id = 'default';
  if ($token =~ /^(.*?):(.*)$/) {
    $form_id = $1;
    $token   = $2;
  }

  my $session_key = join('_', $c->csrf_token_session_key, $form_id);
  my $entry = $c->session->{$session_key};
  unless ($entry) {
    $c->log->debug('CSRF token not found in session') if $c->debug;
    return $c->delegate_failed_csrf_token_check;
  }

  if($c->single_use_csrf_token || $c->action->attributes->{SingleUseCSRF}) {
    $c->log->debug('Deleting single-use CSRF token from session') if $c->debug;
    delete $c->session->{$session_key};
  }

  if ((time - $entry->{created}) > $c->csrf_max_age) {
    $c->log->debug('CSRF token expired') if $c->debug;
    return $c->delegate_failed_csrf_token_check;
  }

  my $expected_token = $entry->{value};
  if ($c->has_csrf_default_secret) {
    $expected_token = hmac_sha256_hex($expected_token, $c->csrf_default_secret);
  }

  $c->log->debug("Expected CSRF token from session: $expected_token") if $c->debug;

  unless ($c->secure_compare($token, $expected_token)) {
    $c->log->debug('CSRF token mismatch') if $c->debug;
    return $c->delegate_failed_csrf_token_check;
  }
  $c->log->debug('CSRF token check passed') if $c->debug;

  return 1;
}

sub find_csrf_token_in_request {
  my $c = shift;
  if(my $header_token = $c->request->header('X-CSRF-Token')) {
    $c->log->debug('Found CSRF token in request header') if $c->debug;
    return $header_token;
  } else {
    return $c->req->body_parameters->{$c->csrf_token_param_key}
      if exists($c->req->body_parameters->{$c->csrf_token_param_key});
    return $c->req->body_data->{$c->csrf_token_param_key}
      if exists($c->req->body_data->{$c->csrf_token_param_key});
    $c->log->debug('No CSRF token found in request') if $c->debug;    
    return undef;
  }
}

sub csrf_token {
  my ($c, %args) = @_;

  $c->log->warn("'session' argument is deprecated and will be removed in a future release")
    if exists($args{session});
  $c->log->warn("'token_secret' argument is deprecated and will be removed in a future release")
    if exists($args{token_secret});

  my $form_id = $args{form_id} || 'default';
  my $session_key = join('_', $c->csrf_token_session_key, $form_id);
  my $entry = $c->session->{$session_key};

  if (!$entry || time - $entry->{created} > $c->csrf_max_age) {
    $c->log->debug("Generating new CSRF token for form ID '$form_id'") if $c->debug;
    $entry = {
      value   => encode_base64url(urandom(32)),
      created => time,
    };
    $c->session->{$session_key} = $entry;
  } else {
    $c->log->debug("Reusing existing CSRF token for form ID '$form_id'") if $c->debug;
  }

  my $token = $entry->{value};

  if ($c->has_csrf_default_secret) {
    $token = hmac_sha256_hex($token, $c->csrf_default_secret);
  }

  $token = "$form_id:$token";

  $c->log->debug("Using CSRF token '$token'") if $c->debug;

  return $token;
}

sub secure_compare {
  my ($c, $a, $b) = @_;
  return 0 unless defined $a && defined $b && length $a == length $b;

  my $res = 0;
  for (my $i = 0; $i < length($a); $i++) {
    $res |= ord(substr($a, $i)) ^ ord(substr($b, $i));
  }
  return $res == 0;
}

sub random_token {
  my ($c, $length) = @_;
  $length ||= 48;
  return encode_base64url(urandom($length));
}

sub delegate_failed_csrf_token_check {
  my $c = shift;

  # Allow controller to handle failed CSRF token check
  return $c->controller->handle_failed_csrf_token_check($c)
    if $c->controller->can('handle_failed_csrf_token_check');
  return $c->handle_failed_csrf_token_check
    if $c->can('handle_failed_csrf_token_check');

  $c->response->status(403);
  $c->response->content_type('text/plain');
  $c->response->body('Forbidden: Invalid CSRF token.');
  $c->finalize;

  Catalyst::Exception->throw(message => 'csrf_token failed validation');
}

1;

__END__

=head1 NAME

Catalyst::Plugin::CSRFToken - Robust CSRF protection plugin for Catalyst

=head1 SYNOPSIS

    package MyApp;

    use Catalyst;

    # Enable CSRF protection; requires Session plugin
    __PACKAGE__->setup(qw/
      Session
      Session::Store::...     # your choice
      Session::State::Cookie  # Only sane state option
      CSRFToken               # Add this line
    /);

    # Configuration
    __PACKAGE__->config(
      'Plugin::CSRFToken' => {
        'max_age' => 3600,              # Token lifespan in seconds
        'default_secret' => '...',      # Optional, your default secret for HMAC signing
        'param_key' => '...',           # Optional, default is 'csrf_token'
        'single_use_csrf_token' => ..., # Optional, default is 0
        'auto_check' => ...,            # Optional, default is 0
      },
    );

If not using 'auto_check' you can enable CSRF checks on a per-action basis:

    sub some_action :Local EnableCSRF {
      my ($self, $c) = @_;
      # CSRF check is automatically performed
    }

Or manually check the token:

    if($c->req->method eq 'POST') {
      Catalyst::Exception->throw(message => 'csrf_token failed validation')
        unless $c->check_csrf_token;
    }

In your templates, specify form IDs for multiple forms:

    <form id="edit_profile" method="POST">
        <input type="hidden" name="csrf_token" value="[% c.csrf_token(form_id=>'edit_profile') %]">
        <!-- form fields here -->
    </form>

Tokens can also be provided via the 'X-CSRF-Token' HTTP request header (useful for AJAX requests):

  <script
    src="https://code.jquery.com/jquery-3.6.0.min.js"
    integrity="sha384-..."
    crossorigin="anonymous"
  ></script>
  <script>
    $.ajax({
      url: '/some/endpoint',
      type: 'POST',
      headers: {
        'X-CSRF-Token': '[% c.csrf_token(form_id=>"your_form_id") %]'
      },
      data: {
        // form data here
      },
      success: function(response) {
        // handle response
      }
    });
  </script>

=head1 DESCRIPTION

This creates a cryptographical token tied to a given web session used for CSRF protection.  You can
generate a token and pass it to your view layer where it should be added to the form you are
trying to process, typically as a hidden field called 'csrf_token' (although you can change
that in configuration if needed).

All POST, PUT, and PATCH requests are automatically checked for a valid CSRF token when
'auto_check_csrf_token' is enabled. If the check fails, a 403 Forbidden response is returned.  The
response can be customized by overriding the 'csrf_failure_response' method or as otherwise
documented below.

If you leave this disabled, you will need to manually check the token using the 'check_csrf_token'
method.  Example:

  if($c->req->method eq 'POST') {
    Catalyst::Exception->throw(message => 'csrf_token failed validation')
      unless $c->check_csrf_token;
  }

Or you can enable CSRF checks on a per-action basis by adding the 'EnableCSRF' attribute to the
action.  Example:

  sub some_action :Local EnableCSRF {
    my ($self, $c) = @_;
    # CSRF check is automatically performed
  }

=head2 Version 1.001 Notes

Older versions of this plugin contained security and related bugs stemming from a 
mistake I made in the first release.   Over the years I've tried to tweak it to
make it more secure and robust.  However, I've come to the conclusion that the
best way to fix the issue required me to substantially rewrite the guts.  I did
my best to maintain the public API and as much of the private API as I could, but
its possible this version break compatibility with older versions.  Usually I
try to avoid this, but in this case I felt it was necessary because I think the
old versions are insecure and you should not use them in any case.  Hit me with a
bug report if you find something that doesn't work as expected and I will try to
fix it, if I can without reintroducing the security issues.

This version also adds more debugging log output when Catalyst is run in debug
mode.  This should help you understand what is going on with the CSRF token
generation and validation.   But the log is more noisy.

=head1 CONFIGURATION

=head2 param_key
=head2 token_param_key

Name of the request parameter used to carry the CSRF token. Defaults to 'csrf_token'.

=head2 max_age

Lifespan of a CSRF token in seconds. Defaults to 3600 (1 hour).  After this time the token
will be considered expired and a new one will be generated if requested, or will result
in a 403 Forbidden response if the token is used in a request for validation.

=head2 auto_check_csrf_token

Boolean attribute controlling whether automatic CSRF checks on incoming requests are enabled. 
Defaults to 0 (disabled).  Highly recommended to enable this feature.  If you leave it off
you will need to manually check the token using the 'check_csrf_token' method or you can enable
on a per action basis by adding the 'EnableCSRF' attribute to the action.  Examples:

    sub some_action :Local EnableCSRF {
      my ($self, $c) = @_;
      # CSRF check is automatically performed
    }

    sub some_other_action :Local {
      my ($self, $c) = @_;
      Catalyst::Exception->throw(message => 'csrf_token failed validation')
        unless $c->check_csrf_token;
    }

=head2 default_secret

Optional secret key to enhance security by hashing tokens with HMAC.  You can use this for
example to force invalidation when restarting the service or just to add an extra layer of
security.  If you don't provide a secret, the token is stored in the session as is.  If you
provide a secret, the token is hashed with the secret before being stored in the session.

Using a secret can improve the security of your tokens and reduce the risk of playback attacks.
But you should have a key rotation policy for this to be effective.  If you don't provide a

=head2 session_key

Name of the session key used to store CSRF tokens. Defaults to '_csrf_token'.  You can change
this if it conflicts with another session key you are using.

=head2 single_use_csrf_token

Boolean attribute controlling whether CSRF tokens are single-use. Defaults to 0 (disabled). If
enabled, the token is deleted from the session after the first validation. If disabled, the
token can be used multiple times until it expires.

This is disabled by default because enabling it  can lead to some tricky UI experiences, like if the 
user clicks the back button and resubmits the form, which then generated a CSRF token validation error.
You can mitigate this issue and similar ones by setting you HTML form to not cache, or by using
JavaScript to prevent the user from resubmitting, Example:

    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />

But this can be browser dependent and not always work as expected.  If you don't need the highest
level of CSRF protection you can leave the default as zero, which will allow the token
to be used multiple times until it expires.  That way you don't break the 'back' button and similar
actions that might cause a token to be reused.   But this is less secure.

Even if youi leave this as zero, you can selectivly enable single use tokens by setting the ':SingleUseCSRF'
attribute on the action.  Example:

    sub some_action :Local SingleUseCSRF {
      my ($self, $c) = @_;
      # CSRF check is automatically performed
    }

You may wish to do this for particularly sensitive actions, like changing a password or making a payment
or logging in.

=head1 METHODS

=head2 csrf_token(form_id=>$form_id)

Generates and returns a CSRF token for the given form ID. Defaults to 'default' if not provided.
Calling this method will return a token you can embed in your form as a hidden field. If your
webpage has multiple forms, you can generate a token for each form by providing a unique form ID.

Token is stored in the session and used to perform CSRF checks on form submissions. Please keep
in mind that this session key is deleted once the token is used, so you can't use the same token
twice. You should also deal with 'back' buttons and similar actions that might cause a token to be
reused and return an error. 

=head2 check_csrf_token

Checks the CSRF token in the request. If the token is missing, invalid, or expired, a 403 Forbidden
response is returned. Returns 1 if the token is valid.

=head2 random_token($length)

Generates and returns a secure random token encoded in base64 format. Default length is 48 bytes.
Useful when you just need a disposable token that is cryptographically secure.

=head2 csrf_failure_response

This is the method that is called when a CSRF token check fails.  It first checks if the controller
has a 'handle_failed_csrf_token_check' method and calls that if it does.  If not it calls the
'handle_failed_csrf_token_check' method on the context object if that exists.  If neither of those
methods exist it creates a default response and finalizes it.

Override this method if you want to provide a custom response when a CSRF token check fails or
implement one of the other two methods mentioned above.

=head1 SKIPPING AUTOMATIC CSRF CHECKS

You can skip automatic CSRF checks (when using the 'auto_check' configuration option) for specific
actions by adding the 'NoCSRF' attribute to the action:

    sub skip :Path(skip) DisableCSRF Args(0) {
      my ($self, $c) = @_;
      $c->res->body('ok');
    }

=head1 CHAINING AND ACTION ATTRIBUTES

If using chained actions in your Catalyst application, you can apply the 'EnableCSRF', 'DisableCSRF',
and 'SingleUseCSRF' attributes to alter how the CSRF token is checked.  However you MUST apply the
attribte to the final action in the chain for this to work.  Example:

    sub base :Chained('/') PathPart('') CaptureArgs(0) {
      my ($self, $c) = @_;
    }

    sub some_action :Chained('base') PathPart('some_action') Args(0)  {
      my ($self, $c) = @_;
    }

    sub final_action :Chained('base') PathPart('final_action') Args(0) EnableCSRF SingleUseCSRF {
      my ($self, $c) = @_;
      # CSRF check is automatically performed and token is deleted after use
    }

If you don't place the attribute on the final action the plugin will not see it.

=head1 AUTHOR

  John Napiorkowski <jnapiork@cpan.org>
 
=head1 COPYRIGHT
 
  Copyright (c) 2025 the above named AUTHOR
 
=head1 LICENSE
 
You may distribute this code under the same terms as Perl itself.
 
=cut
