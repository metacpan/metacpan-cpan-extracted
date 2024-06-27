#! perl

use v5.10;
use Test2::V0;
use Test::Lib;

use strict;
use warnings;

my %base;
use CXC::DB::DDL::Util { into => \%base, }, -type_funcs;

# this creates support for DBD::MyTestDBD
use My::Field;

my %add_dbd;    # shouldn't change
use CXC::DB::DDL::Util { into => \%add_dbd, }, -type_funcs;

my %mixed;
use CXC::DB::DDL::Util {
    dbd  => 'MyTestDBD',
    into => \%mixed,
  },
  -type_funcs;

is( \%base, \%add_dbd, 'default symbol tables the same after adding new dbd' );

is(
    [ keys %mixed ],
    bag {
        item $_ for keys %base;
        item 'MTDB_INTEGER';
        item 'MTDB_REAL';
        end;
    },
    'found DBI & new types',
);

my %my_field;
use CXC::DB::DDL::Util {
    dbd  => 'MyTestDBD',
    into => \%my_field,
  },
  -type_funcs, -types;

use CXC::DB::DDL::Util { dbd => 'MyTestDBD', }, 'xTYPE';


for my $type ( qw( MTDB_INTEGER MTDB_REAL ) ) {

    subtest $type => sub {


        my $constant = do {
            ## no critic (TestingAndDebugging::ProhibitNoStrict)
            no strict 'refs';
            &{"DBD::MyTestDBD::$type"}();
        };

        subtest 'specific type function generator' => sub {
            my $field = $my_field{$type}->()->( 'foo' );

            is(
                $field,
                object {
                    prop blessed => 'My::Field';
                    call data_type => array {
                        item object {
                            prop blessed => 'My::Field::Type';
                            call name => $type;
                            call type => $constant;
                        };
                        end;
                    };
                },
            );
        };

        subtest 'generic type function generator' => sub {
            my $field = xTYPE( $my_field{"DBD_TYPE_$type"}->() )->( 'foo' );

            is(
                $field->data_type,
                array {
                    item object {
                        prop blessed => 'My::Field::Type';
                        call name => $type;
                        call type => $constant;
                    };
                    end;
                },
            );
        };


    };
}


done_testing;
