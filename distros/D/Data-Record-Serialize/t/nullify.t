#! perl

use Test2::V0;

use Test::Lib;

use Data::Record::Serialize;

subtest 'default behavior' => sub {

    my $drs;
    ok( lives { $drs = Data::Record::Serialize->new( encode => '+My::Test::Encode::store' ) },
        'construct object' )
      or note "Error: $@";

    is( $drs->nullified, [], 'no nullified fields prior to sending first record' );

    # prime @fields
    $drs->send( { integer => 1, string => q{}, number => q{} } );

    is( $drs->nullified, [], 'no nullified fields after sending first record' );

    is(
        $drs->output->[-1],
        hash {
            field integer => 1;
            field string  => q{};
            field number  => q{};
            end;
        },
        'no output fields nullified'
    );

};


subtest 'nullify boolean' => sub {

    my $drs;
    ok(
        lives {
            $drs = Data::Record::Serialize->new(
                encode  => '+My::Test::Encode::store',
                nullify => 1,
            )
        },
        'construct object',
    ) or note $@;

    # prime @fields
    $drs->send( { integer => 1, string => 'string', number => 2.2 } );

    # correct list of fields to be nullified
    is(
        $drs->nullified,
        bag {
            item 'integer';
            item 'string';
            item 'number';
            end;
        },
        'correct fields nullified'
    );

    # these will be nullified
    $drs->send( { integer => 1, string => q{}, number => q{} } );

    is(
        $drs->output->[-1],
        hash {
            field integer => 1;
            field string  => undef;
            field number  => undef;
            end;
        },
        'correct output fields nullified'
    );

    ok( lives { $drs->nullify( 0 ) }, 'reset nullify' );
    is( $drs->nullified, [], 'no fields nullified' );

    $drs->send( { integer => 1, string => q{}, number => q{} } );

    is(
        $drs->output->[-1],
        hash {
            field integer => 1;
            field string  => q{};
            field number  => q{};
            end;
        },
        'no output fields nullified'
    );

};

subtest 'bad field name' => sub {

    my $drs;
    ok(
        lives {
            $drs = Data::Record::Serialize->new(
                encode  => '+My::Test::Encode::store',
                nullify => ['foobar'] )
        },
        'construct object'
    ) or note $@;

    my $error;

    $error
      = dies { $drs->send( { integer => 1, string => q{}, number => q{} } ); };

    isa_ok(
        $error,
        ['Data::Record::Serialize::Error::Role::Base::fields'],
        'send: caught bad nullification field error',
    );
    like( $error, qr/foobar/, 'identified bad field name' );

    $error = dies { $drs->nullified };
    isa_ok(
        $error,
        ['Data::Record::Serialize::Error::Role::Base::fields'],
        'nullified: caught bad nullification field error',
    );
    like( $error, qr/foobar/, 'identified bad field name' );
};

subtest 'nullify sub' => sub {

    my $drs;
    ok(
        lives {
            $drs = Data::Record::Serialize->new(
                encode  => '+My::Test::Encode::store',
                nullify => sub { shift->numeric_fields },
            )
        },
        'construct object',
    ) or note $@;

    $drs->send( { integer => 1, string => 'string', number => 2.2 } );

    is(
        $drs->nullified,
        bag {
            item 'integer';
            item 'number';
            end;
        },
        'correct fields nullified',
    );

    $drs->send( { integer => 1, string => q{}, number => q{} } );

    is(
        $drs->output->[-1],
        hash {
            field integer => 1;
            field string  => q{};
            field number  => undef;
            end;
        },
        'correct output fields nullified',
    );

};

subtest 'nullify field selection specification' => sub {

    my $drs = Data::Record::Serialize->new(
        encode  => '+My::Test::Encode::store',
        fields  => [qw( integer string number boolean )],
        types   => { integer => 'I', string => 'S', number => 'N', boolean => 'B' },
        nullify => [qw( -integer -boolean )],
    );

    is(
        $drs->nullified,
        bag { item 'string'; item 'number'; end; },
        'initial exclusions select remaining fields'
    );

    $drs->send( { integer => q{}, string => q{}, number => q{}, boolean => 1 } );

    is(
        $drs->output->[-1],
        {
            integer => q{},
            string  => undef,
            number  => undef,
            boolean => 1,
        },
        'only selected fields are nullified',
    );
};

done_testing;
