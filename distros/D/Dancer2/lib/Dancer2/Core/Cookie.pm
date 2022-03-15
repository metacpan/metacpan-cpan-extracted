package Dancer2::Core::Cookie;
# ABSTRACT: A cookie representing class
$Dancer2::Core::Cookie::VERSION = '0.400000';
use Moo;
use URI::Escape;
use Dancer2::Core::Types;
use Dancer2::Core::Time;
use Carp 'croak';
use Ref::Util qw< is_arrayref is_hashref >;
use overload '""' => \&_get_value;

BEGIN {
    my $try_xs =
        exists($ENV{PERL_HTTP_XSCOOKIES}) ? !!$ENV{PERL_HTTP_XSCOOKIES} :
        exists($ENV{PERL_ONLY})           ?  !$ENV{PERL_ONLY} :
        1;

    my $use_xs = 0;
    $try_xs and eval {
        require HTTP::XSCookies;
        $use_xs++;
    };
    if ( $use_xs ) {
        *to_header = \&xs_to_header;
    }
    else {
        *to_header = \&pp_to_header;
    }
    *_USE_XS = $use_xs ? sub () { !!1 } : sub () { !!0 };
}

sub xs_to_header {
    my $self = shift;

    # HTTP::XSCookies can't handle multi-value cookies.
    return $self->pp_to_header(@_) if @{[ $self->value ]} > 1;

    return HTTP::XSCookies::bake_cookie(
        $self->name,
        {   value    => $self->value,
            path     => $self->path,
            domain   => $self->domain,
            expires  => $self->expires,
            httponly => $self->http_only,
            secure   => $self->secure,
            samesite => $self->same_site,
        }
    );
}

sub pp_to_header {
    my $self   = shift;

    my $value = join( '&', map uri_escape($_), $self->value );
    my $no_httponly = defined( $self->http_only ) && $self->http_only == 0;

    my @headers = $self->name . '=' . $value;
    push @headers, "Path=" . $self->path          if $self->path;
    push @headers, "Expires=" . $self->expires    if $self->expires;
    push @headers, "Domain=" . $self->domain      if $self->domain;
    push @headers, "SameSite=" . $self->same_site if $self->same_site;
    push @headers, "Secure"                       if $self->secure;
    push @headers, 'HttpOnly' unless $no_httponly;

    return join '; ', @headers;
}

has value => (
    is       => 'rw',
    isa      => ArrayRef,
    required => 0,
    coerce   => sub {
        my $value = shift;
        my @values =
            is_arrayref($value) ? @$value
          : is_hashref($value)  ? %$value
          :                       ($value);
        return [@values];
    },
);

around value => sub {
    my $orig  = shift;
    my $self  = shift;
    my $array = $orig->( $self, @_ );
    return wantarray ? @$array : $array->[0];
};

# this is only for overloading; need a real sub to refer to, as the Moose
# attribute accessor won't be available at that point.
sub _get_value { shift->value }

has name => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has expires => (
    is       => 'rw',
    isa      => Str,
    required => 0,
    coerce   => sub {
        Dancer2::Core::Time->new( expression => $_[0] )->gmt_string;
    },
);

has domain => (
    is       => 'rw',
    isa      => Str,
    required => 0,
);

has path => (
    is        => 'rw',
    isa       => Str,
    default   => sub {'/'},
    predicate => 1,
);

has secure => (
    is       => 'rw',
    isa      => Bool,
    required => 0,
    default  => sub {0},
);

has http_only => (
    is       => 'rw',
    isa      => Bool,
    required => 0,
    default  => sub {1},
);

has same_site => (
    is       => 'rw',
    isa      => Enum[qw[Strict Lax None]],
    required => 0,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Core::Cookie - A cookie representing class

=head1 VERSION

version 0.400000

=head1 SYNOPSIS

    use Dancer2::Core::Cookie;

    my $cookie = Dancer2::Core::Cookie->new(
        name => $cookie_name, value => $cookie_value
    );

    my $value = $cookie->value;

    print "$cookie"; # objects stringify to their value.

=head1 DESCRIPTION

Dancer2::Core::Cookie provides a HTTP cookie object to work with cookies.

=head1 ATTRIBUTES

=head2 value

The cookie's value.

(Note that cookie objects use overloading to stringify to their value, so if
you say e.g. return "Hi, $cookie", you'll get the cookie's value there.)

In list context, returns a list of potentially multiple values; in scalar
context, returns just the first value.  (So, if you expect a cookie to have
multiple values, use list context.)

=head2 name

The cookie's name.

=head2 expires

The cookie's expiration date.  There are several formats.

Unix epoch time like 1288817656 to mean "Wed, 03-Nov-2010 20:54:16 GMT"

It also supports a human readable offset from the current time such as "2 hours".
See the documentation of L<Dancer2::Core::Time> for details of all supported
formats.

=head2 domain

The cookie's domain.

=head2 path

The cookie's path.

=head2 secure

If true, it instructs the client to only serve the cookie over secure
connections such as https.

=head2 http_only

By default, cookies are created with a property, named C<HttpOnly>,
that can be used for security, forcing the cookie to be used only by
the server (via HTTP) and not by any JavaScript code.

If your cookie is meant to be used by some JavaScript code, set this
attribute to 0.

=head2 same_site

Whether the cookie ought not to be sent along with cross-site requests.
Valid values are C<Strict>, C<Lax>, or C<None>. Default is unset.
Refer to
L<RFC6265bis|https://tools.ietf.org/html/draft-ietf-httpbis-cookie-same-site>
for further details regarding same-site context.

=head1 METHODS

=head2 my $cookie=Dancer2::Core::Cookie->new(%opts);

Create a new Dancer2::Core::Cookie object.

You can set any attribute described in the I<ATTRIBUTES> section above.

=head2 my $header=$cookie->to_header();

Creates a proper HTTP cookie header from the content.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
