#! perl

use Test2::V0;

use Test::Lib;

use Data::Record::Serialize;

use My::Test::Util -all;

subtest 'default behavior' => sub {

    my $drs;
    ok(
        lives {
            $drs = Data::Record::Serialize->new( encode => '+My::Test::Encode::store', )
        },
        'construct object'
    ) or note $@;

    is( $drs->numified, [], 'no numified fields prior to sending first record' );

    # prime @fields to get the correct types
    $drs->send( { number => 1.1, string => 'string', integer => 1 } );

    is( $drs->numified, [], 'no numified fields after sending first record' );

    $drs->send( { number => '1.1', string => 3, integer => '1' } );

  SKIP: {
        skip 'Need Convert::Scalar' unless $have_Convert_Scalar;
        subtest 'no output fields numified' => sub {
            my $output = $drs->output->[-1];
            ok( is_string( $output->{number} ),  'number' );
            ok( is_string( $output->{integer} ), 'integer' );
            ok( is_number( $output->{string} ),  'string' );
        };
    }

};


subtest 'numify boolean' => sub {

    my $drs;
    ok(
        lives {
            $drs = Data::Record::Serialize->new(
                encode => '+My::Test::Encode::store',
                numify => 1
            )
        },
        'construct object'
    ) or note $@;

    # prime @fields to get the correct types
    $drs->send( { number => 1.1, string => 'string', integer => 1 } );

    # correct list of fields to be numified
    is(
        $drs->numified,
        bag {
            item 'number';
            item 'integer';
            end;
        },
        'correct fields numified'
    );

    # these will be numified
    $drs->send( { integer => '1', string => 3, number => '2.2' } );

  SKIP: {
        skip 'Need Convert::Scalar' unless $have_Convert_Scalar;
        subtest 'proper output fields numified' => sub {
            my $output = $drs->output->[-1];
            ok( is_number( $output->{number} ),  'number' );
            ok( is_number( $output->{integer} ), 'integer' );
            ok( is_number( $output->{string} ),  'string' );
        };
    }

    is(
        $drs->output->[-1],
        hash {
            field integer => 1;
            field string  => '3';
            field number  => 2.2;
            end;
        },
        'output fields survived'
    );

    ok( lives { $drs->numify( 0 ) }, 'reset numify' );
    is( $drs->numified, [], 'no fields numified' );

};

subtest 'bad field name' => sub {

    my $drs;
    ok(
        lives {
            $drs = Data::Record::Serialize->new(
                encode => '+My::Test::Encode::store',
                numify => ['foobar'] )
        },
        'construct object'
    ) or note $@;

    my $error;

    $error
      = dies { $drs->send( { integer => 1, string => q{}, number => q{} } ); };

    isa_ok(
        $error,
        ['Data::Record::Serialize::Error::Role::Base::fields'],
        'send: caught bad numification field error'
    );
    like( $error, qr/foobar/, 'identified bad field name' );

    $error = dies { $drs->numified };
    isa_ok(
        $error,
        ['Data::Record::Serialize::Error::Role::Base::fields'],
        'numified: caught bad numification field error'
    );
    like( $error, qr/foobar/, 'identified bad field name' );


};

subtest 'numify sub' => sub {

    my $drs;
    ok(
        lives {
            $drs = Data::Record::Serialize->new(
                encode => '+My::Test::Encode::store',
                numify => sub { shift->numeric_fields },
            )
        },
        'construct object'
    ) or note $@;

    # prime @fields to get the correct types
    $drs->send( { number => 1.1, string => 'string', integer => 1 } );

    # correct list of fields to be numified
    is(
        $drs->numified,
        bag {
            item 'number';
            item 'integer';
            end;
        },
        'correct fields numified'
    );

    $drs->send( { integer => '1', string => 3, number => '2.2' } );

  SKIP: {
        skip 'Need Convert::Scalar' unless $have_Convert_Scalar;
        subtest 'proper output fields numified' => sub {
            my $output = $drs->output->[-1];
            ok( is_number( $output->{number} ),  'number' );
            ok( is_number( $output->{integer} ), 'integer' );
            ok( is_number( $output->{string} ),  'string' );
        };
    }

    is(
        $drs->output->[-1],
        hash {
            field integer => 1;
            field string  => 3;
            field number  => 2.2;
            end;
        },
        'output fields survived'
    );

};

subtest 'numify field selection specification' => sub {

    my $drs = Data::Record::Serialize->new(
        encode => '+My::Test::Encode::store',
        fields => [qw( integer string number )],
        types  => { integer => 'I', string => 'S', number => 'N' },
        numify => [qw( + -integer )],
    );

    is( $drs->numified, ['number'], 'load all and exclude one numeric field' );

    $drs->send( { integer => '2', string => 'text', number => '4.5' } );

    is(
        $drs->output->[-1],
        {
            integer => '2',
            string  => 'text',
            number  => 4.5,
        },
        'only selected field is numified',
    );
};

done_testing;
