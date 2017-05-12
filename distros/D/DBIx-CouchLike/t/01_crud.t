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
my $trace;
if ($ENV{TRACE}) {
    require IO::Scalar;
    $couch->{trace} = IO::Scalar->new(\$trace);
}
$couch->versioning( $ENV{VERSIONING} );

is $couch->table => "foo";
ok $couch->create_table;

ok !$couch->{id_generator}; # lazy
ok $couch->id_generator;
ok $couch->id_generator->get_id;

my $id = $couch->post({ foo => 1, bar => 2 });
ok $id;

my $obj = $couch->get($id);
ok $obj;
is_deeply $obj => { foo => 1, bar => 2, _id => $id };

ok $couch->put( $id, { foo => 2, bar => 3, baz => 4 } );
$obj = $couch->get($id);
ok $obj;
is_deeply $obj => { foo => 2, bar => 3, baz => 4, _id => $id };

$obj->{foo} = "FOO";
$obj->{bar} = "BAR";
delete $obj->{baz};
ok $couch->put($obj);
ok $obj = $couch->get($id);
is_deeply $obj => { foo => "FOO", bar => "BAR", _id => $id };

ok $couch->delete($id);
ok ! $couch->get($id);

ok $couch->post( "foo" => { a => "AAA" } );
eval {
    $couch->post( "foo" => { a => "AAA" } )
};
ok $@ && $@ =~ qr/(?:duplicate key value|is not unique)/;

# post with id
$id = $couch->post({ _id => "9999", foo => 1, bar => 2 });
is $id => "9999";
$obj = $couch->get("9999");
is_deeply $obj => { foo => 1, bar => 2, _id => "9999" };

# put with id (not exists)
$id = $couch->put({ _id => 1234, foo => 9999 });
is $id => 1234;
$obj = $couch->get(1234);
is_deeply $obj => { _id => 1234, foo => 9999 };

my @all = $couch->all;
is_deeply \@all => [
    { 'value' => { 'foo' => 9999 }, 'id' => '1234' },
    { 'value' => { 'bar' => 2, 'foo' => 1 }, 'id' => '9999' },
    { 'value' => { 'a' => 'AAA' }, id => 'foo' },
];

@all = $couch->all({ limit => 1 });
is_deeply \@all => [
    { 'value' => { 'foo' => 9999 }, 'id' => '1234' },
];

@all = $couch->all({ offset => 1, limit => 1 });
is_deeply \@all => [
    { 'value' => { 'bar' => 2, 'foo' => 1 }, 'id' => '9999' },
];

@all = $couch->all({ id_like => "1%" });
is_deeply \@all => [
    { 'value' => { 'foo' => 9999 }, 'id' => '1234' },
];

@all = $couch->all({ id_start_with => "1" });
is_deeply \@all => [
    { 'value' => { 'foo' => 9999 }, 'id' => '1234' },
];

@all = $couch->all({ id_in => ["1234", "foo"]});
is_deeply \@all => [
    { 'value' => { 'foo' => 9999 }, 'id' => '1234' },
    { 'value' => { 'a' => 'AAA' }, id => 'foo' },
];


$dbh->commit unless $ENV{DSN};
$dbh->disconnect;

diag($trace);
