use lib qw'../lib lib t';
use TestConnector;
use DBIx::Struct (
    connector_module      => 'TestConnector',
    user_schema_namespace => "TST"
);
use Test::More;

package TST::Prim;
our @ISA = ("DBC::Prim");

package main;
my ($query, $bind);
ok(defined DBIx::Struct::connect('', '', ''), 'connected');
my $prim = one_row("prim", 1);
is(ref $prim, "TST::Prim", "prim from user schema (u-s)");
my $list = one_row("list", {id => 1});
ok($list && ref($list->refPlAssoc) eq 'DBC::PlAssoc', 'got back reference (db-s)');
ok($list && ref($list->refPlAssoc->Prim) eq 'TST::Prim', 'got back reference and direct reference (u-s)');
done_testing();

