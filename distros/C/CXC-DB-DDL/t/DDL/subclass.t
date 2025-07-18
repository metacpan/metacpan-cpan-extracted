#! perl

use v5.26;
use Test2::V0;

use experimental 'signatures';
use Test::Lib;

use My::SubClass1::DDL;
use My::SubClass2::DDL;
use CXC::DB::DDL::Util -all;
use CXC::DB::DDL::Constants -all;


my %main = (
    name   => 'table1',
    fields => [ {
            name              => 'id',
            data_type         => SQL_INTEGER,
            is_primary_key    => 1,
            is_auto_increment => 1,
        },
    ],
    constraints => [ {
            type   => UNIQUE,
            fields => '-all',
        },
        {
            type   => UNIQUE,
            fields => ['id'],
        },
    ],
);

subtest 'table' => sub {
    my $ddl = My::SubClass1::DDL->new( \%main );

    is(
        $ddl,
        object {
            call table => object {
                prop blessed => 'My::SubClass1::Table';
                call fields => array {
                    item object {
                        prop blessed => 'CXC::DB::DDL::Field';
                    };
                    end;
                };
            };
        },
    );

};

subtest 'field' => sub {
    my $ddl = My::SubClass2::DDL->new( \%main );

    is(
        $ddl,
        object {
            call table => object {
                prop blessed => 'My::SubClass2::Table';
                call fields => array {
                    item object {
                        prop blessed => 'My::SubClass2::Field';
                    };
                    end;
                };
            };
        },
    );

};

done_testing;

