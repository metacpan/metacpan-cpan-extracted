package Catalyst::Plugin::CookiedSession;
use strict;
use warnings;
use Catalyst::Exception;
use Crypt::CBC;
use JSON::XS::VersionOneAndTwo;
use MIME::Base64;
use NEXT;
use base qw/Class::Accessor::Fast/;
our $VERSION = '0.35';

BEGIN {
    __PACKAGE__->mk_accessors(
        qw(_cookiedsession_key _cookiedsession_expires _cookiedsession_name _cookiedsession_session)
    );
}

sub prepare_cookies {
    my $c = shift;
    $c->NEXT::prepare_cookies(@_);

    my $configuration = $c->config->{cookiedsession} || {};

    my $key = $configuration->{key};
    $c->_cookiedsession_throw_error(
        'CookiedSession: requires a key in the configuration')
        unless $key;
    $c->_cookiedsession_key($key);

    my $expires = $configuration->{expires};
    $c->_cookiedsession_expires($expires);

    my $name = $configuration->{name}
        || Catalyst::Utils::appprefix( ref($c) ) . '_cookiedsession';
    $c->_cookiedsession_name($name);

    my $cookie  = $c->request->cookie($name);
    my $session = {};

    if ($cookie) {
        my $ciphertext_base64   = $cookie->value;
        my $ciphertext_unbase64 = decode_base64($ciphertext_base64);
        my $json = $c->_cookiedsession_cipher->decrypt($ciphertext_unbase64);
        $session = decode_json($json);
        $c->log->debug("CookiedSession: found cookie $name containing $json")
            if $c->debug;
    } else {
        $c->log->debug("CookiedSession: found no cookie $name") if $c->debug;
    }
    $c->_cookiedsession_session($session);
}

sub finalize_cookies {
    my $c                 = shift;
    my $session           = $c->_cookiedsession_session;
    my $json              = encode_json($session);
    my $ciphertext        = $c->_cookiedsession_cipher->encrypt($json);
    my $ciphertext_base64 = encode_base64( $ciphertext, '' );
    my $name              = $c->_cookiedsession_name;
    $c->response->cookies->{$name} = {
        value   => $ciphertext_base64,
        expires => $c->_cookiedsession_expires
    };
    $c->log->debug("CookiedSession: set cookie $name containing $json")
        if $c->debug;
    $c->NEXT::finalize_cookies(@_);
}

sub _cookiedsession_throw_error {
    my ( $c, $error ) = @_;
    $c->log->fatal($error);
    Catalyst::Exception->throw($error);
}

sub session {
    my $c = shift;
    return $c->_cookiedsession_session;
}

sub _cookiedsession_cipher {
    my $c = shift;
    return Crypt::CBC->new(
        -key    => $c->_cookiedsession_key,
        -cipher => 'Rijndael'
    );
}

1;

__END__

=head1 NAME

Catalyst::Plugin::CookiedSession - Store sessions in a browser cookie

=head1 SYNOPSIS

  # in your Catalyst application:
  use Catalyst qw(CookiedSession);
  
  __PACKAGE__->config(
      cookiedsession => { key => 'secretkey', expires => '+1d' },
  );
  
  # later on in your code
  $c->session->{product} = 'foo';
  ...
  my $product = $c->session->{product};
  
=head1 DESCRIPTION

This module is a replacement module for Catalyst::Plugin::Session::*
which stores the L<Catalyst> session in a browser cookie. This has two
advantages: it's easier to configure than Catalyst::Plugin::Session::*
and sessions require no disk IO.

The session is encrypted using Rijndael using the key you provide in the
configuration, which should be unique to your application.

More about Rijndael: http://en.wikipedia.org/wiki/Rijndael

If you do not set an expires value in the configuration, then a session
cookie is used. You should set a value to make the cookie persist through
closing the browser: use '+1h' for one hour, '+2d' for two days, '+3M'
for three months and '+4y' for four years.

The cookied is named after your application, with _cookiedsession
appended to the end. Pass in a name value in the configuration to
override this.

Note that the cookie is limited in size to 4096 bytes. Keep your sessions
very small. Alternatively please provide a patch which works along the
lines of L<CGI::Cookie::Splitter>.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2008, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
