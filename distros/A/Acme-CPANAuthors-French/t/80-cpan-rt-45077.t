#!perl
use utf8;
use strict;
use Test::More;
use Acme::CPANAuthors;

# checks for bug CPAN-RT#45077, contributed by Olivier Mengue

my %name = (
    DOLMEN  => [ 23, "Olivier Mengué (dolmen)" ],
    JFENAL  => [ 12, "Jérôme Fenal" ],
);

plan tests => 2 * keys %name;

my $authors = Acme::CPANAuthors->new('French');

for my $pauseid (keys %name) {
    my $author = $authors->name($pauseid);
    is( length $author, $name{$pauseid}[0],
        "$pauseid: author name must be $name{$pauseid}[0] chars long" );
    is( $author, $name{$pauseid}[1], "$pauseid: checking encoding" );
}
