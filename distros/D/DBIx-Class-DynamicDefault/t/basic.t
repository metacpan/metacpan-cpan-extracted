use strict;
use warnings;
use Test::More tests => 14;
use DBICx::TestDatabase;

BEGIN { use_ok('DBIx::Class::DynamicDefault') }

use FindBin;
use lib "$FindBin::Bin/lib";

my $schema = DBICx::TestDatabase->new('TestSchema');
my $rs     = $schema->resultset('Table');
my $rs2    = $schema->resultset('Affe');

my $row = $rs->create({ fred => 'affe' });

is($row->quux, 1, 'default on create with methodname');
is($row->garply, undef, 'no default on create');
is($row->corge, 'create', 'default on create with coderef');

$row->update({ fred => 'moo' });

is($row->quux, 1, 'no default on update');
is($row->garply, $$, 'default on update with coderef');
is($row->corge, 'update2', 'default on update with methodname');

$row->garply(-42);
$row->update;

is($row->garply, -42, 'defaults don\'t get set when a value is specified explicitly on update');

$row->update;
is($row->corge, 'update3', 'no default on update without changes');

$row = $rs->create({ quux => -23, fred => 'zomtec' });

is($row->quux, -23, 'defaults don\'t get set when a value is specified explicitly on create');

$row = $rs2->create({ moo => 0, kooh => '123' });

is($row->moo, 0, 'no default on create');
is($row->kooh, '123', 'no default on create');

$row->update;

is($row->moo, 1, 'default on update without changes and always_update');
is($row->kooh, 'zomtec', 'on update default without always_update if another col is changed due to always_update');
