#! perl

use Test2::V0;

use Test::Lib;

use Data::Record::Serialize;

use My::Test::Util -all;

subtest "default behavior" => sub {

    my $drs;
    ok(
        lives {
            $drs = Data::Record::Serialize->new( encode => '+My::Test::Encode::store', )
        },
        'construct object'
    ) or note $@;

    is( $drs->stringified, [], "no stringified fields prior to sending first record" );

    # prime @fields to get the correct types
    $drs->send( { number => 1.1, string => 'string', integer => 1 } );

    is( $drs->stringified, [], "no stringified fields after sending first record" );

    $drs->send( { number => 1.1, string => 3, integer => 1 } );

  SKIP: {
        skip 'Need Convert::Scalar' unless $have_Convert_Scalar;
        subtest "no output fields stringified" => sub {
            my $output = $drs->output->[-1];
            ok( is_number( $output->{number} ),  'number' );
            ok( is_number( $output->{integer} ), 'integer' );
            ok( is_number( $output->{string} ),  'string' );
        };
    }

};


subtest "stringify boolean" => sub {

    my $drs;
    ok(
        lives {
            $drs = Data::Record::Serialize->new(
                encode    => '+My::Test::Encode::store',
                stringify => 1
            )
        },
        'construct object'
    ) or note $@;

    # prime @fields to get the correct types
    $drs->send( { number => 1.1, string => 'string', integer => 1 } );

    # correct list of fields to be stringified
    is(
        $drs->stringified,
        bag {
            item 'string';
            end;
        },
        "correct fields stringified"
    );

    # these will be stringified
    $drs->send( { integer => 1, string => 3, number => 2.2 } );

  SKIP: {
        skip 'Need Convert::Scalar' unless $have_Convert_Scalar;
        subtest "proper output fields stringified" => sub {
            my $output = $drs->output->[-1];
            ok( is_number( $output->{number} ),  'number' );
            ok( is_number( $output->{integer} ), 'integer' );
            ok( is_string( $output->{string} ),  'string' );
        };
    }

    is(
        $drs->output->[-1],
        hash {
            field integer => 1;
            field string  => "3";
            field number  => 2.2;
            end;
        },
        "output fields survived"
    );

    ok( lives { $drs->stringify( 0 ) }, "reset stringify" );
    is( $drs->stringified, [], "no fields stringified" );

};

subtest "bad field name" => sub {

    my $drs;
    ok(
        lives {
            $drs = Data::Record::Serialize->new(
                encode    => '+My::Test::Encode::store',
                stringify => ['foobar'] )
        },
        'construct object'
    ) or note $@;

    my $error;

    $error
      = dies { $drs->send( { integer => 1, string => "", number => "" } ); };

    isa_ok(
        $error,
        ['Data::Record::Serialize::Error::Role::Base::fields'],
        "send: caught bad stringification field error"
    );
    like( $error, qr/foobar/, 'identified bad field name' );

    $error = dies { $drs->stringified };
    isa_ok(
        $error,
        ['Data::Record::Serialize::Error::Role::Base::fields'],
        "stringified: caught bad stringification field error"
    );
    like( $error, qr/foobar/, 'identified bad field name' );


};

subtest "stringify sub" => sub {

    my $drs;
    ok(
        lives {
            $drs = Data::Record::Serialize->new(
                encode    => '+My::Test::Encode::store',
                stringify => sub { shift->string_fields },
            )
        },
        'construct object'
    ) or note $@;

    # prime @fields to get the correct types
    $drs->send( { number => 1.1, string => 'string', integer => 1 } );

    is( $drs->stringified, ['string'], "correct fields stringified" );

    $drs->send( { integer => 1, string => 3, number => 2.2 } );

  SKIP: {
        skip 'Need Convert::Scalar' unless $have_Convert_Scalar;
        subtest "proper output fields stringified" => sub {
            my $output = $drs->output->[-1];
            ok( is_number( $output->{number} ),  'number' );
            ok( is_number( $output->{integer} ), 'integer' );
            ok( is_string( $output->{string} ),  'string' );
        };
    }

    is(
        $drs->output->[-1],
        hash {
            field integer => 1;
            field string  => "3";
            field number  => 2.2;
            end;
        },
        "output fields survived"
    );

};

done_testing;
