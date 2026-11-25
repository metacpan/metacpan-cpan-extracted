#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 2 + 3*5 + 3*5 + 2*3*(2*4 + 1);

my @false_id_vectors = (
    [1, uuid    => '6d34d4a1-8fbc-4e22-b3e0-d50f43d97cb1'],
    [1, sid     => 45],
    [1, sni     => 189],
    [0, wd      => 'Q5432619'],
    [0, uri     => 'https://schema.org/False'],
    [0, uri     => 'http://schema.org/False'],
);
my @true_id_vectors = (
    [1, uuid    => 'eb50b3dc-28be-4cfc-a9ea-bd7cee73aed5'],
    [1, sid     => 46],
    [1, sni     => 190],
    [0, wd      => 'Q16751793'],
    [0, uri     => 'https://schema.org/True'],
    [0, uri     => 'http://schema.org/True'],
);

use_ok('Data::Identifier');
use_ok('Data::Identifier::Util');

foreach my $v (0, '', undef) {
    my $identifier = Data::Identifier::Util->from_bool($v);
    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, '6d34d4a1-8fbc-4e22-b3e0-d50f43d97cb1', 'UUID match');
    ok(!Data::Identifier::Util->is_true($identifier), 'false is not true');
    ok( Data::Identifier::Util->is_false($identifier), 'false is false');
    ok(!$identifier->is_null, 'false is not null');
}

foreach my $v (-1, 1, 'true') {
    my $identifier = Data::Identifier::Util->from_bool($v);
    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, 'eb50b3dc-28be-4cfc-a9ea-bd7cee73aed5', 'UUID match');
    ok( Data::Identifier::Util->is_true($identifier), 'true is true');
    ok(!Data::Identifier::Util->is_false($identifier), 'true is not false');
    ok(!$identifier->is_null, 'true is not null');
}

foreach my $v (@false_id_vectors) {
    my $is_same = shift(@{$v});
    my $identifier = Data::Identifier->new(@{$v});
    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, '6d34d4a1-8fbc-4e22-b3e0-d50f43d97cb1', 'UUID match') if $is_same;
    ok(!Data::Identifier::Util->is_true($identifier), 'false is not true');
    ok( Data::Identifier::Util->is_false($identifier), 'false is false');
    ok(!$identifier->is_null, 'false is not null');
}

foreach my $v (@true_id_vectors) {
    my $is_same = shift(@{$v});
    my $identifier = Data::Identifier->new(@{$v});
    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, 'eb50b3dc-28be-4cfc-a9ea-bd7cee73aed5', 'UUID match') if $is_same;
    ok( Data::Identifier::Util->is_true($identifier), 'true is true');
    ok(!Data::Identifier::Util->is_false($identifier), 'true is not false');
    ok(!$identifier->is_null, 'true is not null');
}

exit 0;
