# -*- mode:perl -*-
use strict;
use Test::More qw/ no_plan /;

BEGIN { use_ok 'DBIx::CouchLike::IdGenerator' }

my $gen = DBIx::CouchLike::IdGenerator->new;
isa_ok $gen => "DBIx::CouchLike::IdGenerator";
ok $gen->can('get_id');

my %id;
for ( 1 .. 2000 ) {
    my $new = $gen->get_id;
    ok $new, "get_id";
    ok !ref $new, "no ref";
    ok !$id{$new}, "got_id is not exists";
    $id{$new} = 1;
}
