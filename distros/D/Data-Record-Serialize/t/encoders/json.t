#!perl

use v5.10;

use Test2::V0;
use Test::Lib;
use Encode;
use JSON::PP ();
use charnames ':full';

use My::Test::Util -all;

use Data::Record::Serialize;

BEGIN {
    unless ( eval { require Data::Record::Serialize::Encode::json; 1 } ) {
        my $err = $@;
        if ( ref( $err ) eq 'Data::Record::Serialize::Error::json_backend' ) {
            skip_all( $err->msg );
        }
        else {
            skip_all( $@ );
        }
    }
}

use constant UNICODE_TEXT => "caf\N{MUSICAL SYMBOL G CLEF}";

sub encode_json_line {
    my ( $data, %attr ) = @_;

    my @encoded;
    my $encoder = Data::Record::Serialize->new(
        encode => 'json',
        sink   => 'array',
        output => \@encoded,
        fields => [ sort keys %{$data} ],
        %attr,
    );

    $encoder->send( { %{$data} } );

    return $encoded[-1];
}

subtest 'constructor' => sub {

    my $json = JSON::PP->new;

    my @output;
    my $s;
    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode  => 'json',
                sink    => 'array',
                output  => \@output,
                nullify => ['string2'],
                fields  => [ 'integer', 'number', 'string1', 'string2', 'bool' ],
                types   => { bool => 'B' },
            );
        },
        'constructor',
    ) or diag $@;

    subtest 'record does not require transformation' => sub {

        # prime types
        $s->send( {
            integer => 1,
            number  => 2.2,
            string1 => 'string',
            string2 => 'nyuck nyuck',
        } );

        my $got;

        # read and make sure round trip types are correct
        ok( lives { $got = $json->incr_parse( $output[-1] ) }, 'deserialize record' )
          or diag $@;

        is(
            $got,
            hash {
                field integer => 1;
                field number  => 2.2;
                field string1 => 'string';
                field string2 => 'nyuck nyuck';
                end;
            },
            'round-trip values',
        );


      SKIP: {
            skip 'Need Convert::Scalar' unless $have_Convert_Scalar;
            subtest 'output field values properly retained' => sub {
                ok( is_number( $got->{number} ),  'number' );
                ok( is_number( $got->{integer} ), 'integer' );
                ok( is_string( $got->{string1} ), 'string1' );
                ok( is_string( $got->{string2} ), 'string2' );
            };
        }

    };

    subtest 'record requires transformation' => sub {
        # now try something that needs numify & stringify
        $s->send( {
            integer => '1',
            number  => '2.2',
            string1 => 99,
            string2 => 'nyuck nyuck',
            bool    => 1,
        } );

        my $got;

        ok( lives { $got = $json->incr_parse( $output[-1] ) }, 'deserialize record' )
          or diag $@;

        is(
            $got,
            hash {
                field integer => 1;
                field number  => 2.2;
                field string1 => '99';
                field string2 => 'nyuck nyuck';
                field bool    => meta {
                    prop this => in_set(
                        meta { prop blessed => 'JSON::PP::Boolean'; },
                        meta { prop blessed => 'Types::Serialiser::Boolean'; },
                    );
                    prop this => T();
                };
                end;
            },
            'round-trip values',
        );

      SKIP: {
            skip 'Need Convert::Scalar' unless $have_Convert_Scalar;
            subtest 'output field values properly converted' => sub {
                ok( is_number( $got->{number} ),  'number' );
                ok( is_number( $got->{integer} ), 'integer' );
                ok( is_string( $got->{string1} ), 'string1' );
                ok( is_string( $got->{string2} ), 'string2' );
            };
        }
    };

};

my @tests = (
    [ pretty       => { a => 1 }, qq|{\n   "a" : 1\n}\n| ],
    [ space_before => { a => 1 }, q|{"a" :1}| ],
    [ space_after  => { a => 1 }, q|{"a": 1}| ],
);

for my $test ( @tests ) {
    my ( $option, $input, $output ) = @{$test};
    is( encode_json_line( $input, $option => 1 ), $output, $option );
}

subtest 'ascii' => sub {
    my $text         = UNICODE_TEXT;
    my %hash         = ( txt => $text );
    my $expected     = qq[{"txt":"$text"}];
    my $got_no_ascii = encode_json_line( \%hash, ascii => 0, utf8 => 0 );
    my $got_ascii    = encode_json_line( \%hash, ascii => 1, utf8 => 0 );


    is( $got_no_ascii, $expected, 'no ascii' );
    isnt( $got_ascii,              $expected,            'ascii' );
    isnt( length( $got_no_ascii ), length( $got_ascii ), 'lengths differ' );
    is( length( $got_ascii ), 25, 'ascii length is longer' );

};

subtest 'utf8' => sub {
    my $text            = UNICODE_TEXT;
    my %hash            = ( txt => $text );
    my $expected_perl   = qq[{"txt":"$text"}];
    my $expected_octets = encode( 'UTF-8', $expected_perl );
    my $got_perl        = encode_json_line( \%hash, utf8 => 0 );
    my $got_octets      = encode_json_line( \%hash, utf8 => 1 );

    is( $got_octets, $expected_octets, 'got(encoded) == expected(encoded)' );
    is( $got_perl,   $expected_perl,   'got(perl) == expected(perl)' );
    isnt( $got_octets, $expected_perl, 'got(encoded) != expected(perl)' );
};

{
    package MyTest::WithTOJSON;
    sub new     { bless {}, shift }
    sub TO_JSON { return { x => 1 } }
}

{
    package MyTest::TypedWithTOJSON;

    use overload
      q{""}    => sub { 'stringified' },
      q{0+}    => sub { 42 },
      fallback => 1;

    sub new     { bless {}, shift }
    sub TO_JSON { return { x => 1 } }
}

subtest 'object' => sub {
    my $data       = { obj => MyTest::WithTOJSON->new };
    my $typed_data = { obj => MyTest::TypedWithTOJSON->new };

    is(
        encode_json_line(
            $data,
            stringify     => 0,
            allow_blessed => 1,
        ),
        q|{"obj":null}|,
        q{allow_blessed},
    );

    is(
        encode_json_line(
            $data,
            stringify       => 0,
            allow_blessed   => 1,
            convert_blessed => 1,
        ),
        q|{"obj":{"x":1}}|,
        'convert_blessed',
    );

    my @typed_tests = ( {
            label           => 'string type, stringify enabled',
            type            => 'S',
            stringify       => 1,
            numify          => 1,
            allow_blessed   => 0,
            convert_blessed => 0,
            expected        => q|{"obj":"stringified"}|,
        },
        {
            label           => 'stringify takes precedence over blessed options',
            type            => 'S',
            stringify       => 1,
            numify          => 1,
            allow_blessed   => 1,
            convert_blessed => 1,
            expected        => q|{"obj":"stringified"}|,
        },
        {
            label           => 'number type, numify enabled',
            type            => 'N',
            stringify       => 1,
            numify          => 1,
            allow_blessed   => 0,
            convert_blessed => 0,
            expected        => q|{"obj":42}|,
        },
        {
            label           => 'numify takes precedence over blessed options',
            type            => 'N',
            stringify       => 1,
            numify          => 1,
            allow_blessed   => 1,
            convert_blessed => 1,
            expected        => q|{"obj":42}|,
        },
    );

    for my $test ( @typed_tests ) {
        is(
            encode_json_line(
                $typed_data,
                types           => { obj => $test->{type} },
                stringify       => $test->{stringify},
                numify          => $test->{numify},
                allow_blessed   => $test->{allow_blessed},
                convert_blessed => $test->{convert_blessed},
            ),
            $test->{expected},
            $test->{label},
        );
    }

    for my $type ( qw( S N ) ) {
        my %attr = ( types => { obj => $type } );
        $attr{stringify} = 0 if $type eq 'S';
        $attr{numify}    = 0 if $type eq 'N';

        like(
            dies { encode_json_line( $typed_data, %attr ) },
            qr/(?:blessed|object)/i, "$type type without conversion or allow_blessed is rejected",
        );

        is(
            encode_json_line( $typed_data, %attr, allow_blessed => 1 ),
            q|{"obj":null}|, "$type type with conversion disabled uses allow_blessed",
        );

        is(
            encode_json_line( $typed_data, %attr, convert_blessed => 1 ),
            q|{"obj":{"x":1}}|, "$type type with conversion disabled uses convert_blessed alone",
        );

        is(
            encode_json_line(
                $typed_data,
                %attr,
                allow_blessed   => 1,
                convert_blessed => 1,
            ),
            q|{"obj":{"x":1}}|,
            "$type type with conversion disabled uses convert_blessed",
        );
    }

    subtest 'field selectors preserve objects for TO_JSON' => sub {
        my $encoded = encode_json_line( {
                string_obj2 => MyTest::WithTOJSON->new,
                num_obj2    => MyTest::WithTOJSON->new,
            },
            types => {
                string_obj2 => 'S',
                num_obj2    => 'N',
            },
            stringify       => ['-string_obj2'],
            numify          => ['-num_obj2'],
            allow_blessed   => 1,
            convert_blessed => 1,
        );

        is(
            JSON::PP->new->decode( $encoded ),
            {
                string_obj2 => { x => 1 },
                num_obj2    => { x => 1 },
            },
            'TO_JSON receives objects excluded from stringify and numify',
        );
    };
};

done_testing;
