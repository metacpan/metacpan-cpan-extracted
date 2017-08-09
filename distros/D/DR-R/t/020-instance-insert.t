#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use Test::More tests    => 18;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::R';
}


isa_ok(DR::R->new, DR::R::, 'instance created');
is(DR::R->new->dimension, 2, 'default dimension is 2');
is(DR::R->new(dimension => 5)->dimension, 5, 'dimension 5');

for my $r (DR::R->new) {
    is eval { $r->insert }, undef, 'insert wo point';
    like $@, qr{Usage}, 'usage';
    is eval { $r->insert([1,2,3], 1) }, undef, 'insert wo valid point';
    like $@, qr{asize=3, must be 2 or 4}, 'error';


    my $o = 1;

    my $or = \$o;

    ok my $id1 = $r->insert([1,2], $o), 'insert point';
    like $id1 => qr{^\d+$}, 'id';
    ok my $id2 = $r->insert([4,5,6,7], 2), 'insert rect';
    ok my $id3 = $r->insert([5,6], $or), 'insert REF';


    ok $r->remove([1,2], $id1), 'remove the first object';
    is $r->remove([1,2,3,4], 2000), undef, 'Can not remove by value';

    ok $r->remove([5,6], $id3), 'removed REF';
}

for my $r (DR::R->new(dimension => 3, dist_type => 'MANHATTAN', a => 'b')->new) {
    isa_ok $r => DR::R::, 'new $instance';
    is $r->{'constructor.ro.opts'}{dist_type}, 'MANHATTAN', 'dist_type';
    is $r->dimension, 3, 'dimension';
}
