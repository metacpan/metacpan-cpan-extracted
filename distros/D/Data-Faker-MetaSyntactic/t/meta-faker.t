use strict;
use warnings;
use Test::More;

use Data::Faker 'MetaSyntactic';
use Acme::MetaSyntactic ();

# test using all themes
my @themes = grep !/^(?:any|random)$/, Acme::MetaSyntactic->themes;
my $meta = Acme::MetaSyntactic->new;
my %all;

plan tests => @themes + 2;

my $faker = Data::Faker->new;
for my $theme ( sort @themes ) {
    my $provider = "meta_$theme";
    my %item     = map +( $_ => 1 ), $meta->name( $theme => 0 );
    my $item     = $faker->$provider;
    ok( exists $item{$item}, "$provider: $item" );
    @all{ keys %item } = values %item;
}

# and not test any
my $item = $faker->meta_any;
ok( exists $all{$item}, "meta_any: $item" );

$item = $faker->meta;
ok( exists $all{$item}, "meta: $item" );
