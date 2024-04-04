#! perl

use v5.10;
use Test2::V0;

my %SQL_TYPES;

use CXC::DB::DDL::Constants {
    into => \%SQL_TYPES,
    as   => sub { substr( $_, 0, 4, 'DDL_' ); $_ },
  },
  -sql_type_constants;

my %TYPE_FUNCS;
use CXC::DB::DDL::Util {
    into   => \%TYPE_FUNCS,
    prefix => 'DDL_'
  },
  -type_funcs;

is( [ keys %TYPE_FUNCS ], bag { item $_ for keys %SQL_TYPES }, 'types' );

for my $type ( keys %SQL_TYPES ) {

    subtest $type => sub {
        my $constant = $SQL_TYPES{$type}->();

        my $field = $TYPE_FUNCS{$type}->()->( 'foo' );
        isa_ok( $field, ['CXC::DB::DDL::Field'], 'object' );
        is( $field->data_type, [$constant], 'type' );
    };
}


done_testing;
