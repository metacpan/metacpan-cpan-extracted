use strict;
use Test::More;

BEGIN { require 't/base.include' }

SKIP: {
    eval {
        require JSON::Parser;
        JSON::Parser->import;
    };
    skip 'Needs JSON::Parser', 1 if $@;

    my $parser = JSON::Parser->new;
    is( p( $parser->jsonToObj(input) ),
        expected, "JSON:Parser, from_json, live" );
}

my $emulated = {
    'gamma' => bless( { 'value' => 'true' },  'JSON::NotString' ),
    'alpha' => bless( { 'value' => 'true' },  'JSON::NotString' ),
    'zeta'  => bless( { 'value' => 'false' }, 'JSON::NotString' ),
    'beta'  => bless( { 'value' => 'false' }, 'JSON::NotString' )
};

is( p($emulated), expected, "JSON::Parser, emulated" );

done_testing;
