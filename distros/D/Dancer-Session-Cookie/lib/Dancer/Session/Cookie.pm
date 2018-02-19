package Dancer::Session::Cookie;
our $AUTHORITY = 'cpan:YANICK';
$Dancer::Session::Cookie::VERSION = '0.28';
use strict;
use warnings;
# ABSTRACT: Encrypted cookie-based session backend for Dancer
# VERSION

use base 'Dancer::Session::Abstract';

use Session::Storage::Secure 0.010;
use Crypt::CBC;
use String::CRC32;
use Crypt::Rijndael;
use Time::Duration::Parse;

use Dancer 1.3113 ':syntax'; # 1.3113 for on_reset_state and fixed after hook
use Dancer::Cookie  ();
use Dancer::Cookies ();
use Storable        ();
use MIME::Base64    ();

# crydec
my $CIPHER = undef;
my $STORE  = undef;

# cache session here instead of flushing/reading from cookie all the time
my $SESSION = undef;

sub is_lazy { 1 }; # avoid calling flush needlessly

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    my $key = setting("session_cookie_key") # XXX default to smth with warning
      or die "The setting session_cookie_key must be defined";

    my $duration = $self->_session_expires_as_duration;

    $CIPHER = Crypt::CBC->new(
        -key    => $key,
        -cipher => 'Rijndael',
    );

    $STORE = Session::Storage::Secure->new(
        secret_key => $key,
        ( $duration ? ( default_duration => $duration ) : () ),
        sereal_encoder_options => { snappy => 1, stringify_unknown => 1 },
        sereal_decoder_options => { validate_utf8 => 1 },
    );
}

# return our cached ID if we have it instead of looking in a cookie
sub read_session_id {
    my ($self) = @_;
    return $SESSION->id
      if defined $SESSION;
    return $self->SUPER::read_session_id;
}

sub retrieve {
    my ( $class, $id ) = @_;
    # if we have a cached session, hand that back instead
    # of decrypting again
    return $SESSION
      if $SESSION && $SESSION->id eq $id;

    my $ses = eval {
        if ( my $hash = $STORE->decode($id) ) {
            # we recover a plain hash, so reconstruct into object
            bless $hash, $class;
        }
        else {
            _old_retrieve($id);
        }
    };

    return $SESSION = $ses;
}

# support decoding old cookies
sub _old_retrieve {
    my ($id) = @_;
    # 1. decrypt and deserialize $id
    my $plain_text = _old_decrypt($id);
    # 2. deserialize
    $plain_text && Storable::thaw($plain_text);
}

sub create {
    # cache the newly created session
    return $SESSION = Dancer::Session::Cookie->new;
}

# we don't write session ID when told; we do it in the after hook
sub write_session_id { }

# we don't flush when we're told; we do it in the after hook
sub flush { }

sub destroy {
    my $self = shift;

    # gross hack; replace guts with new session guts
    %$self = %{ Dancer::Session::Cookie->new };

    return 1;
}

# Copied from Dancer::Session::Abstract::write_session_id and
# refactored for testing
hook 'after' => sub {
    my $response = shift;

    if ($SESSION) {
        # UGH! Awful hack because Dancer instantiates responses
        # and headers too many times and locks out new cookies
        $response->{_built_cookies} = 0;

        my $c = Dancer::Cookie->new( $SESSION->_cookie_params );
        Dancer::Cookies->set_cookie_object( $c->name => $c );
    }
};

# Make sure that the session is initially undefined for every request
hook 'on_reset_state' => sub {
    my $is_forward = shift;
    undef $SESSION unless $is_forward;
};

# modified from Dancer::Session::Abstract::write_session_id to add
# support for session_cookie_path
sub _cookie_params {
    my $self     = shift;
    my $name     = $self->session_name;
    my $duration = $self->_session_expires_as_duration;
    my %cookie   = (
        name      => $name,
        value     => $self->_cookie_value,
        path      => setting('session_cookie_path') || '/',
        domain    => setting('session_domain'),
        secure    => setting('session_secure'),
        http_only => defined( setting("session_is_http_only") )
        ? setting("session_is_http_only")
        : 1,
    );
    if ( defined $duration ) {
        $cookie{expires} = time + $duration;
    }
    return %cookie;
}

# refactored for testing
sub _cookie_value {
    my ($self) = @_;
    # copy self guts so we aren't serializing a blessed object.
    # we don't set expires, because default_duration will handle it
    return $STORE->encode( {%$self} );
}

# session_expires could be natural language
sub _session_expires_as_duration {
    my ($self) = @_;
    my $session_expires = setting('session_expires');
    return unless defined $session_expires;
    my $duration = eval { parse_duration($session_expires) };
    die "Could not parse session_expires: $session_expires"
      unless defined $duration;
    return $duration;
}

# legacy algorithm
sub _old_decrypt {
    my $cookie = shift;

    $cookie =~ tr{_*-}{=+/};

    $SIG{__WARN__} = sub { };
    my ( $crc32, $plain_text ) = unpack "La*",
      $CIPHER->decrypt( MIME::Base64::decode($cookie) );
    return $crc32 == String::CRC32::crc32($plain_text) ? $plain_text : undef;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer::Session::Cookie - Encrypted cookie-based session backend for Dancer

=head1 VERSION

version 0.28

=head1 SYNOPSIS

Your F<config.yml>:

    session: "cookie"
    session_cookie_key: "this random key IS NOT very random"

=head1 DESCRIPTION

This module implements a session engine for sessions stored entirely
in cookies. Usually only the B<session id> is stored in cookies and
the session data itself is saved in some external storage, e.g.
a database. This module allows you to avoid using external storage at
all.

Since a server cannot trust any data returned by clients in cookies, this
module uses cryptography to ensure integrity and also secrecy. The
data your application stores in sessions is completely protected from
both tampering and analysis on the client-side.

Do be aware that browsers limit the size of individual cookies, so this method
is not suitable if you wish to store a large amount of data.  Browsers typically
limit the size of a cookie to 4KB, but that includes the space taken to store
the cookie's name, expiration and other attributes as well as its content.

=head1 CONFIGURATION

The setting B<session> should be set to C<cookie> in order to use this session
engine in a Dancer application. See L<Dancer::Config>.

Another setting is also required: B<session_cookie_key>, which should
contain a random string of at least 16 characters (shorter keys are
not cryptographically strong using AES in CBC mode).

The optional B<session_expires> setting can also be passed,
which will provide the duration time of the cookie. If it's not present, the
cookie won't have an expiration value.

Here is an example configuration to use in your F<config.yml>:

    session: "cookie"
    session_cookie_key: "kjsdf07234hjf0sdkflj12*&(@*jk"
    session_expires: 1 hour

Compromising B<session_cookie_key> will disclose session data to
clients and proxies or eavesdroppers and will also allow tampering,
for example session theft. So, your F<config.yml> should be kept at
least as secure as your database passwords or even more.

Also, changing B<session_cookie_key> will have an effect of immediate
invalidation of all sessions issued with the old value of key.

B<session_cookie_path> can be used to control the path of the session
cookie.  The default is C</>.

The global B<session_secure> setting is honored and a secure (https
only) cookie will be used if set.

=head1 DEPENDENCY

This module depends on L<Session::Storage::Secure>.  Legacy support is provided
using L<Crypt::CBC>, L<Crypt::Rijndael>, L<String::CRC32>, L<Storable> and
L<MIME::Base64>.

=head1 SEE ALSO

See L<Dancer::Session> for details about session usage in route handlers.

See L<Plack::Middleware::Session::Cookie>,
L<Catalyst::Plugin::CookiedSession>, L<Mojolicious::Controller/session> for alternative implementation of this mechanism.

=head1 AUTHORS

=over 4

=item *

Alex Kapranoff <kappa@cpan.org>

=item *

Alex Sukria <sukria@cpan.org>

=item *

David Golden <dagolden@cpan.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2015, 2014, 2011 by Alex Kapranoff.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


# vim: ts=4 sts=4 sw=4 et:
