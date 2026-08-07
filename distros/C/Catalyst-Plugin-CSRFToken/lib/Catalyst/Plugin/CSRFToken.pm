package Catalyst::Plugin::CSRFToken;

use strict;
use warnings;
use Moose::Role;
use Digest::SHA qw(hmac_sha256_hex);
use MIME::Base64 qw(encode_base64url decode_base64url);
use Crypt::URandom qw(urandom);

our $VERSION = '1.100';

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

  my $token = $c->find_csrf_token_in_request
    or return $c->delegate_failed_csrf_token_check;

  $c->log->debug('Found CSRF token in request') if $c->debug;

  return $c->delegate_failed_csrf_token_check if ref $token;

  my ($form_id, $version, $payload) = split /:/, $token, 3;
  unless (
    defined($form_id)
      && length($form_id)
      && defined($version)
      && $version eq 'v2'
      && defined($payload)
  ) {
    $c->log->debug('Malformed CSRF token') if $c->debug;
    return $c->delegate_failed_csrf_token_check;
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

  my $expected_token = $c->_csrf_expected_token($entry);
  my $candidate_token = $c->_unmask_csrf_token($payload, length($expected_token));

  unless (
    defined($candidate_token)
      && $c->secure_compare($candidate_token, $expected_token)
  ) {
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

  my $expected_token = $c->_csrf_expected_token($entry);
  my $payload = $c->_mask_csrf_token($expected_token);
  my $token = "$form_id:v2:$payload";

  $c->log->debug("Using masked CSRF token for form ID '$form_id'") if $c->debug;

  return $token;
}

sub _csrf_expected_token {
  my ($c, $entry) = @_;
  my $expected_token = $entry->{value};
  my $secret = $c->csrf_default_secret;

  if (defined $secret) {
    $expected_token = hmac_sha256_hex($expected_token, $secret);
  }

  return $expected_token;
}

sub _mask_csrf_token {
  my ($c, $expected_token) = @_;
  return undef unless defined $expected_token && length $expected_token;

  my $mask = urandom(length($expected_token));
  my $masked_token = $mask ^ $expected_token;

  return encode_base64url($mask.$masked_token);
}

sub _unmask_csrf_token {
  my ($c, $payload, $expected_length) = @_;
  return undef unless defined $payload
    && length($payload)
    && $payload =~ /\A[A-Za-z0-9_-]+\z/
    && defined($expected_length)
    && $expected_length > 0;

  my $decoded = decode_base64url($payload);
  return undef unless encode_base64url($decoded) eq $payload;
  return undef unless length($decoded) == $expected_length * 2;

  my $mask = substr($decoded, 0, $expected_length);
  my $masked_token = substr($decoded, $expected_length, $expected_length);

  return $mask ^ $masked_token;
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

The value returned by C<csrf_token> is an opaque, masked representation of
the token held in the session.  A fresh random mask is generated on every
call, so repeated calls return different strings while all remain valid for
the same session token.  This prevents the stable response secret required
by BREACH compression-oracle attacks.  Applications must not parse or alter
the returned value.

All POST, PUT, DELETE, and PATCH requests are automatically checked for a valid CSRF token when
'auto_check_csrf_token' is enabled. If the check fails, a 403 Forbidden response is returned.  The
response can be customized by overriding the 'delegate_failed_csrf_token_check' method or as
otherwise documented below.

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

=head2 Version 1.100 Notes

This version changes the on-the-wire token format and does not accept tokens
issued by version 1.001 or earlier.  Read this before you deploy.

Version 1.001 returned the same token representation for a given session and
form until it expired.  In an application that reflects attacker-controlled
input into a compressed response containing that token, the stable value can
become the secret in a BREACH compression oracle.  Tokens are now masked with
fresh randomness on every call, so the representation differs each time while
still validating against the same session token.

The practical consequence of the format change is that any page rendered by
the old version stops validating the moment the new version is deployed.
Users part way through a form will get a 403 and have to reload.  If that
matters for your deployment, drain or expire sessions as part of the upgrade,
or plan for the rejections.

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

=head2 param_key, token_param_key

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

Optional secret used to derive the expected token with HMAC-SHA256 before
masking and comparison. The random session value itself remains unchanged.
When this setting is omitted, the random session value is masked and compared
directly.

Changing the secret invalidates outstanding tokens. Keep the secret outside
source control and rotate it according to the application's secret-management
policy.

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

Generates and returns a masked CSRF token for the given form ID. Defaults to
C<default> if not provided. Calling this method will return an opaque value
that can be embedded in a form field or sent in the C<X-CSRF-Token> header.

The underlying token and creation time are stored in the session. Every call
uses fresh randomness to mask that token, so two returned values will differ
but will both validate until the underlying token expires. If single-use
checking is enabled, a validation attempt consumes the underlying session
token and invalidates every masked representation of it.

=head2 check_csrf_token

Checks the CSRF token in the request. If the token is missing, invalid, or expired, a 403 Forbidden
response is returned. Returns 1 if the token is valid.

=head2 random_token($length)

Generates and returns a secure random token encoded in base64 format. Default length is 48 bytes.
Useful when you just need a disposable token that is cryptographically secure.

=head2 delegate_failed_csrf_token_check

This is the method that is called when a CSRF token check fails.  It first checks if the controller
has a 'handle_failed_csrf_token_check' method and calls that if it does.  If not it calls the
'handle_failed_csrf_token_check' method on the context object if that exists.  If neither of those
methods exist it creates a default 403 response, finalizes it, and throws a
L<Catalyst::Exception> with the message 'csrf_token failed validation'.

Override this method if you want to provide a custom response when a CSRF token check fails or
implement one of the other two methods mentioned above.

=head1 SKIPPING AUTOMATIC CSRF CHECKS

You can skip automatic CSRF checks (when using the 'auto_check' configuration option) for specific
actions by adding the 'DisableCSRF' attribute to the action:

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

=head1 RESPONSE COMPRESSION

CSRF tokens are masked with fresh randomness on every call to prevent a
stable token value from becoming a BREACH compression oracle. Applications
should still avoid reflecting attacker-controlled input into responses that
contain secrets and should apply appropriate response-compression policy,
rate limiting, and monitoring as defense in depth.

=head1 AUTHOR

  John Napiorkowski <jjnapiork@cpan.org>

=head1 COPYRIGHT

  Copyright (c) 2026 the above named AUTHOR

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
