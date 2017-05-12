use strictures 1;

package Data::UUID::Concise;

use 5.010;
use utf8;
use open qw(:std :utf8);
use charnames qw(:full :short);

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use Carp;
use Data::UUID;
use List::MoreUtils qw[ uniq ];
use Math::BigInt;

our $VERSION = '0.121240';    # VERSION

# ABSTRACT: Encode UUIDs to be more concise or communicable
# ENCODING: utf-8

has 'alphabet' => (
    is      => 'rw',
    isa     => Str,
    default => sub {
        '23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    },
);

around 'alphabet' => sub {
    my ( $next, $self, @rest ) = @_;
    return $self->$next unless @rest;

    my ( $alphabet_candidate ) = @rest;
    return $self->$next( _normalize_alphabet( $alphabet_candidate ) );
};

sub _normalize_alphabet
{
    my ( $alphabet_candidate ) = @_;

    my @symbols = split //, $alphabet_candidate;
    my @decruftified_symbols = uniq sort { $a cmp $b } @symbols;
    my $decruftified_alphabet = join '', @decruftified_symbols;

    return $decruftified_alphabet;
}

sub encode
{
    my ( $self, $uuid ) = @_;

    my $output = '';
    my $numeric =
        Math::BigInt->new( ( Data::UUID->new )->to_hexstring( $uuid ) );
    my $alphabet_length = length( $self->alphabet );

    while ( $numeric->is_positive ) {
        my $index = $numeric->copy->bmod( $alphabet_length );
        $output .= substr( $self->alphabet, $index, 1 );
        $numeric->bdiv( $alphabet_length );
    }

    return $output;
}

sub decode
{
    my ( $self, $string ) = @_;

    my $numeric         = Math::BigInt->new;
    my @characters      = split //, $string;
    my $alphabet_length = length( $self->alphabet );

    for my $character ( @characters ) {
        my $value = index $self->alphabet, $character;
        $numeric = $numeric->bmul( $alphabet_length );
        $numeric = $numeric->badd( $value );
    }

    return ( Data::UUID->new )->from_hexstring( $numeric->as_hex );
}

1;

__END__

=pod

=for :stopwords Nathaniel Reindl cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders metacpan

=encoding utf-8

=head1 NAME

Data::UUID::Concise - Encode UUIDs to be more concise or communicable

=head1 VERSION

version 0.121240

=head1 SYNOPSIS

    use Data::UUID::Concise;

    my $duc = Data::UUID::Concise->new();
    my $encoded_uuid = $duc->encode((Data::UUID->new)->create);
    my $decoded_uuid = $duc->decode('M55djt9tt4WoFaL68da9Ef');

    $duc->alphabet('aaaaabcdefgh1230123');
    $duc->alphabet; # 0123abcdefgh

=head1 ATTRIBUTES

=head2 alphabet

This is the collection of symbols that are used for the encoding
scheme.

By default, a reasonably unambiguous set of characters is used that is
reminiscent of the base 58 scheme used by a rather prominent photo
site's URL shortener.

=head1 METHODS

=head2 encode

Encode a Data::UUID instance as a string with the appropriate set of
symbols.

=head2 decode

Decode a string with the appropriate set of symbols and return a
Data::UUID instance representing the decoded UUID.

=head1 FUNCTIONS

=head2 _normalize_alphabet

Private method. Normalize the alphabet such that it is sorted and that
all elements are distinct.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Data::UUID::Concise

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Data-UUID-Concise>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Data-UUID-Concise>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Data-UUID-Concise>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Data-UUID-Concise>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Data::UUID::Concise>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<nrr+bug-DATA-UUID-CONCISE@corvidae.org>, or through
the web interface at L<https://github.com/nrr/Data-UUID-Concise/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/nrr/Data-UUID-Concise>

  git clone https://github.com/nrr/Data-UUID-Concise.git

=head1 AUTHOR

Nathaniel Reindl <nrr@corvidae.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nathaniel Reindl.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
