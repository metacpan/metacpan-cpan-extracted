#!perl

use Test2::V0;

use Data::Dumper;
use Data::Record::Serialize;

use Test::Lib;


subtest "illegal types" => sub {

    my $err;

    isa_ok(
        $err = dies {
            Data::Record::Serialize->new(
                encode => 'null',
                types  => { a => 'Q' },
            );
        },
        ['Error::TypeTiny'],
        'throws on error'
    );

    like( $err, qr/did not pass type constraint/, 'error message' );

};


subtest "types from first record" => sub {
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new( encode => '+My::Test::Encode::types_nis', );
        },
        'create serializer'
    ) or diag $@;

    $s->send( { string => 'string', integer => 2, float => 3.2 } );

    is(
        $s->types,
        {
            string  => 'S',
            integer => 'I',
            float   => 'N',
        },
        'derived input types',
    );

    is(
        $s->output_types,
        {
            string  => 's',
            integer => 'i',
            float   => 'n',
        },
        'derived output types',
    );

};

subtest "allow type fields to differ from fields" => sub {

    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode       => '+My::Test::Encode::types_nis',
                types        => { a => 'N' },
                fields       => [qw( b )],
                default_type => 'S',
            );
        },
        'create serializer'
    ) or diag $@;

    is(
        $s->types,
        {
            a => 'N',
            b => 'S',
        },
        'retain type for non-existent field',
    );

    is( $s->output_types, { b => 's' }, 'no output type for non-existent field', );
};


subtest "type lists follow output fields if numify/stringify/nullify is boolean" => sub {

    subtest 'default type' => sub {

        my $s;

        ok(
            lives {
                $s = Data::Record::Serialize->new(
                    encode       => '+My::Test::Encode::store',
                    types        => { a => 'N', b => 'S' },
                    fields       => [qw( b )],
                    default_type => 'S',
                    numify       => 1,
                    stringify    => 1,
                    nullify      => 1,
                );
            },
            'create serializer'
        ) or diag $@;

        is( $s->numified,    [],    'numified' );
        is( $s->nullified,   ['b'], 'nullified' );
        is( $s->stringified, ['b'], 'nullified' );

    };

    subtest 'specified types' => sub {

        my $s;

        ok(
            lives {
                $s = Data::Record::Serialize->new(
                    encode    => '+My::Test::Encode::store',
                    types     => { a => 'N', b => 'S' },
                    fields    => 'all',
                    numify    => 1,
                    stringify => 1,
                    nullify   => 1,
                );
            },
            'create serializer'
        ) or diag $@;


        subtest 'before send' => sub {
            is( $s->numified,    [], 'numified' );
            is( $s->nullified,   [], 'nullified' );
            is( $s->stringified, [], 'stringified' );
        };

        $s->send( { b => 'foo' } );

        subtest 'after send' => sub {
            is( $s->numified,    [],    'numified' );
            is( $s->nullified,   ['b'], 'nullified' );
            is( $s->stringified, ['b'], 'nullified' );
        };

    };

    subtest 'types from data' => sub {

        my $s;

        ok(
            lives {
                $s = Data::Record::Serialize->new(
                    encode    => '+My::Test::Encode::store',
                    fields    => [qw( b )],
                    numify    => 1,
                    stringify => 1,
                    nullify   => 1,
                );
            },
            'create serializer'
        ) or diag $@;


        $s->send( { a => 1, b => 'foo' } );

        is( $s->numified,    [],    'numified' );
        is( $s->nullified,   ['b'], 'nullified' );
        is( $s->stringified, ['b'], 'nullified' );

    };


};


subtest "fold I type into N" => sub {

    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => '+My::Test::Encode::types_ns',
                types  => { a => 'I' },
            );
        },
        'create serializer'
    );

    is(
        $s->types,
        {
            a => 'I',
        },
        'retain unsupported integer type',
    );

    is(
        $s->output_types,
        {
            a => 'n',
        },
        'I transformed to N upon output',
    );
};

subtest "encoder mapped types " => sub {

    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => '+My::Test::Encode::types_nis',
                types  => {
                    string => 'S',
                    flat   => 'N',
                    int    => 'I',
                },
            );
        },
        'create serializer'
    );

    is(
        $s->types,
        {
            string => 'S',
            flat   => 'N',
            int    => 'I',
        },
        'input types remain the same',
    );

    is(
        $s->output_types,
        {
            string => 's',
            flat   => 'n',
            int    => 'i',
        },
        'output types transformed by encoder typemap',
    );
};

subtest "encoder mapped types, auto map I => N " => sub {

    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => '+My::Test::Encode::types_ns',
                types  => {
                    string => 'S',
                    flat   => 'N',
                    int    => 'I',
                },
            );
        },
        'create serializer'
    );

    is(
        $s->types,
        {
            string => 'S',
            flat   => 'N',
            int    => 'I',
        },
        'input types remain the same',
    );

    is(
        $s->output_types,
        {
            string => 's',
            flat   => 'n',
            int    => 'n',
        },
        'output types transformed by encoder typemap; I mapped to N',
    );
};


done_testing;
