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

my $filenames = ['lib/App/BPOMUtils.pm','lib/App/BPOMUtils/Table.pm','script/bpom-daftar-bahan-baku-pangan','script/bpom-daftar-bahan-tambahan-pangan','script/bpom-daftar-cemaran-logam-pangan','script/bpom-daftar-cemaran-mikroba-pangan','script/bpom-daftar-jenis-pangan','script/bpom-daftar-kategori-pangan','script/bpom-daftar-kode-prefiks-reg','script/bpom-list-food-additives','script/bpom-list-food-categories','script/bpom-list-food-ingredients','script/bpom-list-food-inputs','script/bpom-list-food-microbe-inputs','script/bpom-list-food-types','script/bpom-list-reg-code-prefixes','script/bpom-show-nutrition-facts','script/bpom-tampilkan-ing'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
