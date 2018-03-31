#!perl

use Test2::V0;

use Data::Record::Serialize;

use Test::Lib;


subtest 'empty args' => sub {

    my $error;
    isa_ok(
        ( $error = dies { Data::Record::Serialize->new } ),
        ['Data::Record::Serialize::Error::attribute::value'],
        'error class',
    );

    like( $error->msg, qr/<encode>/, "error mesage" );

};

subtest 'bad types' => sub {

    for my $type ( [ scalar =>   1 ],
                   [ 'hash; illegal type', { foo => 'Q' }, ],
                   [ 'array; illegal type', [ foo => 'N', bar => 'Q' ] ],
                 ) {

        my ( $label, $type ) = @$type;
        subtest $label => sub {

            my $error
              = dies { Data::Record::Serialize->new( encode => 'null', types => $type ) };
            isa_ok( $error, ['Error::TypeTiny::Assertion'], 'error class' );

            is( $error->attribute_name, 'types', "attribute name" );
        };

    }
};



subtest "encode includes sink ; don't specify sink" => sub {

    my $error;

    isa_ok( (
            $error = dies {
                Data::Record::Serialize->new(
                    encode => 'both',
                    sink   => 'stream'
                  )
            }
        ),
        ['Data::Record::Serialize::Error::attribute::value'],
        'error class',
    );

    like( $error, qr/don't specify a sink/, "error message" );
};


ok(
    lives {
        Data::Record::Serialize->new(
            encode => 'ddump',
            sink   => 'stream'
        );
    },
    'encode + sink'
) or diag $@;

ok(
    lives {
        Data::Record::Serialize->new( encode => 'ddump' );
    },
    'encode + default sink'
) or diag $@;

done_testing;
