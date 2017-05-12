# -*- mode:perl -*-
use strict;
use Test::More qw/ no_plan /;

use Test::Requires qw/ DBD::SQLite /;
BEGIN { use_ok 'DBIx::CouchLike' }

my $dbh = require 't/connect.pl';
ok $dbh;

my $couch = DBIx::CouchLike->new({ dbh => $dbh, table => "foo" });
isa_ok $couch => "DBIx::CouchLike";
ok $couch->can('dbh');
is $couch->dbh => $dbh;
ok $couch->dbh->ping;

is $couch->table => "foo";
ok $couch->create_table;

ok !$couch->{id_generator}; # lazy
ok $couch->id_generator;
ok $couch->id_generator->get_id;

my @id = $couch->post_multi(
    { foo => 1, bar => 2 },
    { foo => 3, bar => 4 },
);
is scalar @id => 2;
my $obj = $couch->get($id[0]);
ok $obj;
is_deeply $obj => { foo => 1, bar => 2, _id => $id[0] };

$obj = $couch->get($id[1]);
ok $obj;
is_deeply $obj => { foo => 3, bar => 4, _id => $id[1] };

my @obj = $couch->get_multi(@id);
ok @obj;
is_deeply \@obj => [
    { foo => 1, bar => 2, _id => $id[0] },
    { foo => 3, bar => 4, _id => $id[1] },
];
$dbh->commit;

@id = $couch->put_multi(
    { foo => 2, bar => 3, baz => 4, _id => $id[0] },
    { foo => 4, bar => 5, baz => 6, _id => $id[1] },
    { foo => 6, bar => 7, baz => 8 },
);
ok @id;
$obj = $couch->get($id[0]);
ok $obj;
is_deeply $obj => { foo => 2, bar => 3, baz => 4, _id => $id[0] };

@obj = $couch->get_multi(@id);
is_deeply \@obj => [
    { foo => 2, bar => 3, baz => 4, _id => $id[0] },
    { foo => 4, bar => 5, baz => 6, _id => $id[1] },
    { foo => 6, bar => 7, baz => 8, _id => $id[2] },
];

$dbh->commit unless $ENV{DSN};
$dbh->disconnect;
