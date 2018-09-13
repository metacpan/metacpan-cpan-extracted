use strict;
use warnings;

use Test::More;
use Test::Fatal;
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

use BSON;
use boolean;

my $c = BSON->new;

# PERL-575 boolean values were references to each other, so if two were created
# identically, then changing one would change the other.

my $a = { "okay" => false, "name" => "fred0" };
my $b = { "okay" => false, "name" => "fred1" };

my $a_bin = $c->encode_one( $a );
my $b_bin = $c->encode_one( $b );

my @docs = ( map{ $c->decode_one( $_ ) } ( $a_bin, $b_bin ) );

is( exception { $_->{okay} = $_->{okay}->TO_JSON for @docs },
  undef, "replacing one boolean doesn't affect another" );

done_testing;
