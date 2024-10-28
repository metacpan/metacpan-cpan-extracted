#! perl

use v5.26;
use Test2::V0;

use experimental 'signatures';

use CXC::DB::DDL::Table;
use CXC::DB::DDL::Util -all;
use CXC::DB::DDL::Constants -all;


my %main = (
    name => 'cxc_db_ddl_test_db_main',
    xFIELDS(
        id => INTEGER(
            is_primary_key    => 1,
            is_auto_increment => 1,
        ),
        foo => INTEGER,
    ),
    constraints => [ {
            type   => UNIQUE,
            fields => '-all',
        },
        {
            type   => UNIQUE,
            fields => 'id',
        },
    ],
);

subtest 'constraint' => sub {

    my $ddl = CXC::DB::DDL::Table->new( \%main );

    is(
        $ddl->constraints,
        bag {
            item hash {
                field fields => bag { item 'id'; item 'foo'; end; };
                field type   => UNIQUE;
                end;
            };
            item hash {
                field fields => bag { item 'id'; };
                field type   => UNIQUE;
                end;
            };
            end;
        } ) or do { require Data::Dump; diag Data::Dump::pp( $ddl->constraints ) };

};

done_testing;
1;
