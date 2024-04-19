#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/App/BPOMUtils/Table/FoodIngredient.pm','lib/App/BPOMUtils/Table/FoodIngredientRBA.pm','script/bpom-daftar-bahan-baku-pangan-lama','script/bpom-daftar-bahan-baku-pangan-rba','script/bpom-list-food-ingredients-old','script/bpom-list-food-ingredients-rba','script/bpomfi'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
