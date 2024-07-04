#! perl

use v5.10;
use Test2::V0;

use strict;
use warnings;

## no critic (BuiltinFunctions::ProhibitStringyEval)
## no critic (ErrorHandling::RequireCheckingReturnValueOfEval
use constant HAVE_DBD_PG => eval ' use DBD::Pg (); 1; ';

BEGIN {
    # run this in a BEGIN block so the
    #  use CXC::DB::DDL::Field::Pg;
    # doen't get run if DBD::Pg is not available.
    skip_all( 'DBD::Pg not available' ) unless HAVE_DBD_PG;
}


use CXC::DB::DDL::Field::Pg;
use CXC::DB::DDL::Util { dbd => 'Pg' }, -type_funcs;

subtest 'PG_JSONB' => sub {
    my $field = PG_JSONB()->( 'foo' );
    isa_ok( $field, ['CXC::DB::DDL::Field::Pg'], 'object' );
    is(
        $field => object {
            call data_type => array {
                item object {
                    prop blessed => 'CXC::DB::DDL::Field::PgType';
                    call name => 'PG_JSONB';
                    call type => DBD::Pg::PG_JSONB;
                };
                end;
            };
            call [ type_name => undef ] => 'JSONB';
        },
        'type',
    );
};

subtest 'DBI SQL_INTEGER' => sub {
    my $field = INTEGER()->( 'foo' );
    isa_ok( $field, ['CXC::DB::DDL::Field'], 'object' );
    is( $field->data_type => [DBI::SQL_INTEGER], 'type' );
};

done_testing;
