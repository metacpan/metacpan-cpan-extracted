package CGI::Cookie::Splitter; # git description: v0.04-15-g9f9f932
# ABSTRACT: Split big cookies into smaller ones.

our $VERSION = '0.05';

use strict;
use warnings;

use Scalar::Util qw/blessed/;
use CGI::Simple::Util qw/escape unescape/;
use Carp qw/croak/;
use namespace::clean 0.19;

sub new {
    my ( $class, %params ) = @_;

    $params{size} = 4096 unless exists $params{size};

    croak "size has to be a positive integer ($params{size} is invalid)"
        unless $params{size} =~ /^\d+$/ and $params{size} > 1;

    bless \%params, $class;
}

sub size { $_[0]{size} }

sub split {
    my ( $self, @cookies ) = @_;
    map { $self->split_cookie($_) } @cookies;
}

sub split_cookie {
    my ( $self, $cookie ) = @_;
    return $cookie unless $self->should_split( $cookie );
    return $self->do_split_cookie(
        $self->new_cookie( $cookie,
            name => $self->mangle_name( $cookie->name, 0 ),
            value => CORE::join("&",map { escape($_) } $cookie->value) # simplifies the string splitting
        )
    );
}

sub do_split_cookie {
    my ( $self, $head ) = @_;

    my $tail = $self->new_cookie( $head, value => '', name => $self->mangle_name_next( $head->name ) );

    my $max_value_size = $self->size - ( $self->cookie_size( $head ) - length( escape($head->value) ) );
    $max_value_size -= 30; # account for overhead the cookie serializer might add

    die "Internal math error, please file a bug for CGI::Cookie::Splitter: max size should be > 0, but is $max_value_size (perhaps other attrs are too big?)"
        unless ( $max_value_size > 0 );

    my ( $head_v, $tail_v ) = $self->split_value( $max_value_size, $head->value );

    $head->value( $head_v );
    $tail->value( $tail_v );

    die "Internal math error, please file a bug for CGI::Cookie::Splitter"
        unless $self->cookie_size( $head ) <= $self->size; # 10 is not enough overhead

    return $head unless $tail_v;
    return ( $head, $self->do_split_cookie( $tail ) );
}

sub split_value {
    my ( $self, $max_size, $value ) = @_;

    my $adjusted_size = $max_size;

    my ( $head, $tail );

    return ( $value, '' ) if length($value) <= $adjusted_size;

    split_value: {
        croak "Can't reduce the size of the cookie anymore (adjusted = $adjusted_size, max = $max_size)" unless $adjusted_size > 0;

        $head = substr( $value, 0, $adjusted_size );
        $tail = substr( $value, $adjusted_size );

        if ( length(my $escaped = escape($head)) > $max_size ) {
            my $adjustment = int( ( length($escaped) - length($head) ) / 3 ) + 1;

            die "Internal math error, please file a bug for CGI::Cookie::Splitter"
                unless $adjustment;

            $adjusted_size -= $adjustment;
            redo split_value;
        }
    }

    return ( $head, $tail );
}

sub cookie_size {
    my ( $self, $cookie ) = @_;
    length( $cookie->as_string );
}

sub new_cookie {
    my ( $self, $cookie, %params ) = @_;

    my %out_params;
    for (qw/name secure path domain expires value/) {
        $out_params{"-$_"} = (exists($params{$_})
            ? $params{$_} : $cookie->$_
        );
    }

    blessed($cookie)->new( %out_params );
}

sub should_split {
    my ( $self, $cookie ) = @_;
    $self->cookie_size( $cookie ) > $self->size;
}

sub join {
    my ( $self, @cookies ) = @_;

    my %split;
    my @ret;

    foreach my $cookie ( @cookies ) {
        my ( $name, $index ) = $self->demangle_name( $cookie->name );
        if ( $name ) {
            $split{$name}[$index] = $cookie;
        } else {
            push @ret, $cookie;
        }
    }

    foreach my $name ( sort { $a cmp $b } keys %split ) {
        my $split_cookie = $split{$name};
        croak "The cookie $name is missing some chunks" if grep { !defined } @$split_cookie;
        push @ret, $self->join_cookie( $name => @$split_cookie );
    }

    return @ret;
}

sub join_cookie {
    my ( $self, $name, @cookies ) = @_;
    $self->new_cookie( $cookies[0], name => $name, value => $self->join_value( map { $_->value } @cookies ) );
}

sub join_value {
    my ( $self, @values ) = @_;
    return [ map { unescape($_) } split('&', CORE::join("", @values)) ];
}

sub mangle_name_next {
    my ( $self, $mangled ) = @_;
    my ( $name, $index ) = $self->demangle_name( $mangled );
    $self->mangle_name( $name, 1 + ((defined($index) ? $index : 0)) ); # can't trust magic incr because it might overflow and fudge 'chunk'
}

sub mangle_name {
    my ( $self, $name, $index ) = @_;
    return sprintf '_bigcookie_%s_chunk%d', +(defined($name) ? $name : ''), $index;
}

sub demangle_name {
    my ( $self, $mangled_name ) = @_;
    my ( $name, $index ) = ( $mangled_name =~ /^_bigcookie_(.+?)_chunk(\d+)$/ );

    return ( $name, $index );
}

__PACKAGE__;

__END__

=pod

=encoding UTF-8

=head1 NAME

CGI::Cookie::Splitter - Split big cookies into smaller ones.

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use CGI::Cookie::Splitter;

    my $splitter = CGI::Cookie::Splitter->new(
        size => 123, # defaults to 4096
    );

    @small_cookies = $splitter->split( @big_cookies );

    @big_cookies = $splitter->join( @small_cookies );

=head1 DESCRIPTION

RFC 2109 recommends that the minimal cookie size supported by the client is
4096 bytes. This has become a pretty standard value, and if your server sends
larger cookies than that it's considered a no-no.

This module provides a pretty simple interface to generate small cookies that
are under a certain limit, without wasting too much effort.

=head1 METHODS

=head2 new

    $splitter = CGI::Cookie::Splitter->new(%params)

The only supported parameters right now are C<size>. It defaults to 4096.

=head2 split

    @cookies = $splitter->split(@cookies)

This method accepts a list of CGI::Cookie objects (or lookalikes) and returns
a list of L<CGI::Cookie>s.

Whenever an object with a total size that is bigger than the limit specified at
construction time is encountered it is replaced in the result list with several
objects of the same class, which are assigned serial names and have a smaller
size and the same domain/path/expires/secure parameters.

=head2 join

    $cookie = $splitter->join(@cookies)

This is the inverse of C<split>.

=head2 should_split

    $splitter->should_split($cookie)

Whether or not the cookie should be split

=head2 mangle_name_next

    $splitter->mangle_name_next($name)

=head2 mangle_name

    $splitter->mangle_name($name, $index)

=head2 demangle_name

    $splitter->demangle_name($mangled_name)

These methods encapsulate a name mangling scheme for changing the cookie names
to allow a 1:n relationship.

The default mangling behavior is not 100% safe because cookies with a safe size
are not mangled.

As long as your cookie names don't start with the substring C<_bigcookie_> you
should be OK ;-)

=for stopwords demangles remangles

Demangles name, increments the index and remangles.

=head1 SUBCLASSING

This module is designed to be easily subclassed... If you need to split cookies
using a different criteria then you should look into that.

=head1 SEE ALSO

=over 4

=item *

L<CGI::Cookie>

=item *

L<CGI::Simple::Cookie>

=item *

L<http://www.cookiecutter.com/>

=item *

L<http://perlcabal.org/~gaal/metapatch/images/copper-moose-cutter.jpg>

=item *

L<RFC 2109|https://www.ietf.org/rfc/rfc2109.txt>

=back

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Shlomi Fish

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Shlomi Fish <shlomif@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
