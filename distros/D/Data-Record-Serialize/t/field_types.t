#!perl

use Test::More;
use Test::Fatal;

use Data::Dumper;
use Data::Record::Serialize;

use lib 't/lib';


subtest "illegal types" => sub {

    my $err;
    isa_ok(
        $err = exception {
            Data::Record::Serialize->new(
                encode => 'null',
                types  => { a => 'Q' },
            );
        },
        'Error::TypeTiny',
        'throws on error'
    );

    like( $err, qr/did not pass type constraint/, 'error message' );

};


subtest "types from first record" => sub {
    my $s;

    is(
        exception {
            $s = Data::Record::Serialize->new( encode => 'types_nis', );
        },
        undef,
        'create serializer'
    );

    $s->send( { string => 'string', integer => 2, float => 3.2 } );

    is_deeply(
        $s->types,
        {
            string  => 'S',
            integer => 'I',
            float   => 'N',
        },
        'derived input types',
    );

    is_deeply(
        $s->output_types,
        {
            string  => 'S',
            integer => 'I',
            float   => 'N',
        },
        'derived output types',
    );

};

subtest "allow type fields to differ from fields" => sub {
    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode => 'types_nis',
                types  => { a => 'N' },
                fields => [qw( b )],
            );
        },
        undef,
        'create serializer'
    );

    is_deeply(
        $s->types,
        {
            a => 'N',
	    b => 'S',
        },
        'retain type for non-existent field',
    );

    is_deeply( $s->output_types, { b => 'S' }, 'no output type for non-existent field', );
};


subtest "fold I type into N" => sub {

    my $s;

    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode => 'types_ns',
                types  => { a => 'I' },
            );
        },
        undef,
        'create serializer'
    );

    is_deeply(
        $s->types,
        {
            a => 'I',
        },
        'retain unsupported integer type',
    );

    is_deeply(
        $s->output_types,
        {
            a => 'N',
        },
        'I transformed to N upon output',
    );
};

subtest "encoder mapped types " => sub {

    my $s;

    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode => 'types_map',
                types  => {
                    string => 'S',
                    flat   => 'N',
                    int    => 'I',
                },
            );
        },
        undef,
        'create serializer'
    );

    is_deeply(
        $s->types,
        {
            string => 'S',
            flat   => 'N',
            int    => 'I',
        },
        'input types remain the same',
    );

    is_deeply(
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

    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode => 'types_map_ns',
                types  => {
                    string => 'S',
                    flat   => 'N',
                    int    => 'I',
                },
            );
        },
        undef,
        'create serializer'
    );

    is_deeply(
        $s->types,
        {
            string => 'S',
            flat   => 'N',
            int    => 'I',
        },
        'input types remain the same',
    );

    is_deeply(
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
