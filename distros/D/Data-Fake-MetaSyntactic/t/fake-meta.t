use strict;
use warnings;
use Test::More;

use Data::Fake::MetaSyntactic;

use Acme::MetaSyntactic;
use List::Util qw( min );

my $count = 5;

plan tests => 2 + $count * ( $count + 1 ) + 3 + $count * 4;

my %theme;
@theme{ grep $_ ne 'any', Acme::MetaSyntactic->themes } = ();
diag scalar keys %theme, " Acme::MetaSyntactic themes installed";

# fake_metatheme
for my $args ( [], [ 'foo' ] ) {
    my $metacategory = fake_metacategory( @$args );
    is( ref $metacategory, 'CODE', "fake_metatheme() returns a coderef" );
}

my $metatheme = fake_metatheme;
my @themes;
my %item;
for ( 1 .. $count ) {

    my $theme = $metatheme->();
    ok( exists $theme{$theme}, "$theme is an installed theme" );
    push @themes, $theme;

    @{ $item{$theme} }{ Acme::MetaSyntactic->new($theme)->name(0) } = ();

    for ( 1 .. $count ) {
        my $item = fake_meta($theme)->();
        ok( exists $item{$theme}{$item}, "$item is an item from $theme" );
    }
}

# fake_meta with a coderef
for ( 1 .. $count ) {
    my $item = fake_meta( sub { $themes[ rand @themes ] } )->();
    my ($theme) = grep exists $item{$_}{$item}, keys %item;
    ok( $theme, "$item is an item from $theme" );
}

# fake_meta with no parameter
for ( 1 .. $count ) {
    my $item = fake_meta()->();
    like( $item, qr/^[A-Za-z_]\w{0,250}$/, "$item looks legit" );
}

# fake_metacategory
for my $args ( [], [ fake_metatheme()->() ], [ fake_metatheme() ] ) {
    my $metacategory = fake_metacategory( @$args );
    is( ref $metacategory, 'CODE', "fake_metacategory() returns a coderef" );
}

# fake_metacategory() picks one theme at random
{
    my $metacategory = fake_metacategory();
    my ($theme) = split m:/:, $metacategory->();

    # same theme each time
    for ( 1 .. $count ) {
        my $category = $metacategory->();
        like( $category, qr{^$theme(?:/|$)}, "$category belongs to $theme" );
    }
}

# pick random categories, and ensure at least one of them has a /
my $metacategory = fake_metacategory( fake_metatheme() );
my @categories;
push @categories, $metacategory->()
    until @categories >= $count && $categories[-1] =~ m:/:;
for my $category ( splice @categories, -$count ) {
    my ($theme) = split m:/:, $category;
    like( $category, qr{^$theme(?:/|$)}, "$category belongs to $theme" );
}

done_testing;
