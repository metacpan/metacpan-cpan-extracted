#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use lib 't/lib';
use App::Mimosa::Test;
use aliased 'App::Mimosa::Test::Mech';
use Test::DBIx::Class;

fixtures_ok 'basic_ss';
fixtures_ok 'basic_ss_organism';

my $mech = Mech->new( autolint => 1 );

my @urls = qw{/};

for my $url (@urls) {
    local $TODO = 'interleaving form and table tags';
    $mech->get_ok($url);
}

done_testing();
