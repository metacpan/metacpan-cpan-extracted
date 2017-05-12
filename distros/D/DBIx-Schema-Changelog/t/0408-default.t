use Test::More tests => 10;

use FindBin;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );
use strict;
use warnings;
use DBIx::Schema::Changelog::Driver::SQLite;
use DBIx::Schema::Changelog::Action::Column::Defaults;

require_ok('DBIx::Schema::Changelog::Driver::SQLite');
use_ok 'DBIx::Schema::Changelog::Driver::SQLite';

my $action = q~DBIx::Schema::Changelog::Action~;
require_ok( $action . '::Column::Defaults' );
use_ok $action. '::Column::Defaults';

my $driver = DBIx::Schema::Changelog::Driver::SQLite->new();
my $object = DBIx::Schema::Changelog::Action::Column::Defaults->new( driver => $driver );

can_ok( $object, @{ [ 'add', 'alter', 'drop' ] } );
#äisa_ok( $object, $action );

is( $object->add(), '', q~Add without params~ );
is( $object->add( { default => 'inc' } ), 'AUTOINCREMENT', q~Add param {default => 'inc'}~ );
is(
    $object->add( { default => 'current' } ),
    'DEFAULT CURRENT_TIMESTAMP',
    q~Add param {default => 'current'}~
);
is( $object->alter(), undef, q~Alter is not used~ );
is( $object->drop(),  undef, q~Drop is not used~ );
