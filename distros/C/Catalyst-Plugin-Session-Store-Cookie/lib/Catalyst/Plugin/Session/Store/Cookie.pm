package Catalyst::Plugin::Session::Store::Cookie;

use Moose;
use Session::Storage::Secure;
use MRO::Compat;
use Catalyst::Utils;

extends 'Catalyst::Plugin::Session::Store';
with 'Catalyst::ClassData';

our $VERSION = '0.005';

__PACKAGE__->mk_classdata($_)
  for qw/_secure_store _store_cookie_name _store_cookie_expires
    _store_cookie_secure _store_cookie_httponly _store_cookie_samesite/;

sub get_session_data {
  my ($self, $key) = @_;
  $self->_needs_early_session_finalization(1);

  # Don't decode if we've decoded this context already.
  return $self->{__cookie_session_store_cache__}->{$key} if
    exists($self->{__cookie_session_store_cache__}) &&
      exists($self->{__cookie_session_store_cache__}->{$key});

  my $cookie = $self->req->cookie($self->_store_cookie_name);
  $self->{__cookie_session_store_cache__} = defined($cookie) ?
    $self->_decode_secure_store($cookie, $key) : +{};

  return $self->{__cookie_session_store_cache__}->{$key};
}

sub _decode_secure_store {
  my ($self, $cookie, $key) = @_;
  my $decoded = eval {
    $self->_secure_store->decode($cookie->value);
  } || do {
    $self->log->error("Issue decoding cookie for key '$key': $@");
    return +{};
  };
  return $decoded;
}

sub store_session_data {
  my ($self, $key, $data) = @_;

  $self->{__cookie_session_store_cache__} = +{
    %{$self->{__cookie_session_store_cache__}},
    $key => $data};

  my $cookie = {
    value => $self->_secure_store->encode($self->{__cookie_session_store_cache__}),
    expires => $self->_store_cookie_expires,
  };

  # copied from Catalyst::Plugin::Session::State::Cookie
  my $sec = $self->_store_cookie_secure;
  $cookie->{secure} = 1 unless ( ($sec==0) || ($sec==2) );
  $cookie->{secure} = 1 if ( ($sec==2) && $self->req->secure );
  $cookie->{httponly} = $self->_store_cookie_httponly;
  $cookie->{samesite} = $self->_store_cookie_samesite;

  return $self->res->cookies->{$self->_store_cookie_name} = $cookie;
}

sub delete_session_data {
  my ($self, $key) = @_;
  delete $self->{__cookie_session_store_cache__}->{$key};
}

# Docs say 'this may be used in the future', like 10 years ago...
sub delete_expired_sessions { }

sub setup_session {
  my $class = shift;
  my $cfg = $class->_session_plugin_config;
  $class->_store_cookie_name($cfg->{storage_cookie_name} || Catalyst::Utils::appprefix($class) . '_store');
  $class->_store_cookie_expires($cfg->{storage_cookie_expires} || '+1d');
  $class->_secure_store(
    Session::Storage::Secure->new(
      secret_key => ($cfg->{storage_secret_key} ||
        die "storage_secret_key' configuration param for 'Catalyst::Plugin::Session::Store::Cookie' is missing!"),
      sereal_encoder_options => ($cfg->{sereal_encoder_options} || +{ snappy => 1, stringify_unknown => 1 }),
      sereal_decoder_options => ($cfg->{sereal_decoder_options} || +{ validate_utf8 => 1 })
    )
  );
  $class->_store_cookie_secure($cfg->{storage_cookie_secure} || 0);
  $class->_store_cookie_httponly($cfg->{storage_cookie_httponly} || 1);
  $class->_store_cookie_samesite($cfg->{storage_cookie_samesite} || 'Lax');

  return $class->maybe::next::method(@_);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::Plugin::Session::Store::Cookie - Store session data in the cookie

=head1 SYNOPSIS

    package MyApp;

    use Catalyst qw/
      Session
      Session::State::Cookie
      Session::Store::Cookie
    /;

    __PACKAGE__->config(
      'Plugin::Session' => {
        storage_cookie_name => ...,
        storage_cookie_expires => ...,
        storage_secret_key => ...,
        storage_cookie_secure => ...,
        storage_cookie_httponly => ...,
        storage_cookie_samesite => ...,
      },
      ## More configuration
    );

    __PACKAGE__->setup;

=head1 DESCRIPTION

What's old is new again...

Store session data in the client cookie, like in 1995.  Handy when you don't
want to setup yet another storage system just for supporting sessions and
authentication. Can be very fast since you avoid the overhead of requesting and
deserializing session information from whatever you are using to store it.
Since Sessions in L<Catalyst> are global you can use this to reduce per request
overhead.  On the other hand you may just use this for early prototying and
then move onto something else for production.  I'm sure you'll do the right
thing ;)

The downsides are that you can really only count on about 4Kb of storage space
on the cookie.  Also, that cookie data becomes part of every request so that
will increase overhead on the request side of the network.  In other words a big
cookie means more data over the wire (maybe you are paying by the byte...?)

Also there are some questions as to the security of this approach.  We encrypt
information with L<Session::Storage::Secure> so you should review that and the
notes that it includes.  Using this without SSL/HTTPS is not recommended.  Buyer
beware.

In any case if all you are putting in the session is a user id and a few basic
things this will probably be totally fine and likely a lot more sane that using
something non persistant like memcached.  On the other hand if you like to dump
a bunch of stuff into the user session, this will likely not work out.

B<NOTE> Since we need to store all the session info in the cookie, the session
state will be set at ->finalize_headers stage (rather than at ->finalize_body
which is the default for session storage plugins).  What this means is that if
you use the streaming or socket interfaces ($c->response->write, $c->response->write_fh
and $c->req->io_fh) your session state will get saved early.  For example you
cannot do this:

    $c->res->write("some stuff");
    $c->session->{key} = "value";

That key 'key' will not be recalled when the session is recovered for the following
request.  In general this should be an easy issue to work around, but you need
to be aware of it.

=head1 CONFIGURATION

This plugin supports the following configuration settings, which are stored as
a hash ref under the configuration key 'Plugin::Session::Store::Cookie'.  See
L</SYNOPSIS> for example.

=head2 storage_cookie_name

The name of the cookie that stores your session data on the client.  Defaults
to '${$myapp}_sstore' (where $myappp is the lowercased version of your application
subclass).  You may wish something less obvious.

=head2 storage_cookie_expires

How long before the cookie that is storing the session info expires.  defaults
to '+1d'.  Lower is more secure but bigger hassle for your user.  You choose the
right balance.

=head2 storage_secret_key

Used to fill the 'secret_key' initialization parameter for L<Session::Storage::Secure>.
Don't let this be something you can guess or something that escapes into the
wild...

There is no default for this, you need to supply.

=head2 storage_cookie_secure

If this attribute B<set to 0> the cookie will not have the secure flag.

If this attribute B<set to 1> the cookie sent by the server to the client
will get the secure flag that tells the browser to send this cookie back to
the server only via HTTPS.

If this attribute B<set to 2> then the cookie will get the secure flag only if
the request that caused cookie generation was sent over https (this option is
not good if you are mixing https and http in your application).

Default value is 0.

=head2 storage_cookie_httponly

If this attribute B<set to 0>, the cookie will not have HTTPOnly flag.

If this attribute B<set to 1>, the cookie will got HTTPOnly flag that should
prevent client side Javascript accessing the cookie value - this makes some
sort of session hijacking attacks significantly harder. Unfortunately not all
browsers support this flag (MSIE 6 SP1+, Firefox 3.0.0.6+, Opera 9.5+); if
a browser is not aware of HTTPOnly the flag will be ignored.

Default value is 1.

Note1: Many people are confused by the name "HTTPOnly" - it B<does not mean>
that this cookie works only over HTTP and not over HTTPS.

Note2: This parameter requires Catalyst::Runtime 5.80005 otherwise is skipped.

=head2 storage_cookie_samesite

This attribute configures the value of the
L<SameSite|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite>
flag.

If set to None, the cookie will be sent when making cross origin requests,
including following links from other origins. This requires the
L</cookie_secure> flag to be set.

If set to Lax, the cookie will not be included when embedded in or fetched from
other origins, but will be included when following cross origin links.

If set to Strict, the cookie will not be included for any cross origin requests,
including links from different origins.

Default value is C<Lax>. This is the default modern browsers use.

Note: This parameter requires Catalyst::Runtime 5.90125 otherwise is skipped.

=head2 sereal_decoder_options

=head2 sereal_encoder_options

This should be a hashref of options passed to init args of same name in
L<Session::Storage::Secure>.  Defaults to:

    sereal_encoder_options => +{ snappy => 1, stringify_unknown => 1 },
    sereal_decoder_options => +{ validate_utf8 => 1 },

Please note the default B<allows> object serealization.  You may wish to
not allow this for production setups.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>
Alexander Hartmaier L<email:abraxxa@cpan.org>

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>, L<Session::Storage::Secure>

=head1 COPYRIGHT & LICENSE

Copyright 2022, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

