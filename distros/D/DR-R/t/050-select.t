#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use Test::More tests    => 15;
use Encode qw(decode encode);



BEGIN {
    use_ok 'DR::R';
}

my $tree = new DR::R dimension => 2;
ok $tree => 'instance created';
for (my $i = 0; $i < 1_000_00; $i++) {
    $tree->insert([rand 100, rand 100], $i);
}

my $list = $tree->select(OVERLAPS => [20,20,80,80], limit => 10);
isa_ok $list => 'ARRAY', 'Select';
is @$list, 10, 'limit';

my $listo = $tree->select(OVERLAPS => [20,20,80,80], limit => 10, offset => 1);
isa_ok $listo => 'ARRAY', 'Select offset';
is @$listo, 10, 'limit';

shift @$list;
pop @$listo;
is_deeply $list, $listo, 'offset';

ok !eval { $tree->select(OVERLAPS1 => [1, 2]) }, 'Unknown type';
like $@ => qr{Unknown iterator type:}, 'error message';

ok !eval { $tree->select(OVERLAPS => [1, 2, 3]) }, 'Wrong point or rect 3 items';
like $@ => qr{Invalid point or rect}, 'error message';

ok !eval { $tree->select(OVERLAPS => undef) }, 'Wrong point or rect undef';
like $@ => qr{Invalid point or rect}, 'error message';

ok !eval { $tree->select(OVERLAPS => {a => 'b'}) }, 'Wrong point or rect HASH';
like $@ => qr{Invalid point or rect}, 'error message';
