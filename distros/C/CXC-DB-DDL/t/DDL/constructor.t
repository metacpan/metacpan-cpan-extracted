#! perl

use v5.26;
use Test2::V0;

use experimental 'signatures';
use Test::Lib;

use CXC::DB::DDL;
use CXC::DB::DDL::Util -all;
use CXC::DB::DDL::Constants -all;


sub test ( $label, @args ) {

    my $ctx = context();
    my $ddl;

    subtest $label => sub {
        my $ok = ok( lives { $ddl = CXC::DB::DDL->new( @args ) }, 'construct' );

        diag $@ unless $ok;

        $ok and is(
            $ddl,
            object {
                prop blessed => 'CXC::DB::DDL';
                call table => object {
                    prop blessed => 'CXC::DB::DDL::Table';
                    call fields => array {
                        item object {
                            prop blessed => 'CXC::DB::DDL::Field';
                        };
                        end;
                    };
                };
            },
            'structure',
        );
    };

    $ctx->release;
}

my %table = (
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

# CXC::DB::DDL->new( tables => [ $table, $table, ... ] );
test 'tables => [ \%table, ... ]', tables => [ \%table ];

# CXC::DB::DDL->new( tables => \%table );
test 'tables => \%table', tables => \%table;

# CXC::DB::DDL->new( { tables => $table } );
test '{ tables => \%table }', { tables => \%table };

# CXC::DB::DDL->new( { tables => [ $table, $table, ... ] } );
test '{ tables => [ \%table, ... ] }', { tables => [ \%table ] };

# CXC::DB::DDL->new( $table );
test '\%table', \%table;

# CXC::DB::DDL->new( [ $table, $table, ... ] );
test '[ \%table, ... ]', [ \%table ];

done_testing;

