use strict;
use Test::More;

BEGIN { require 't/base.include' }

SKIP: {
    eval {
        require JSON;
        JSON->import(qw/decode_json/);
    };
    skip "JSON not installed", 1 if $@;

    my $dump = p( decode_json(input) );
    is( $dump, expected, "whatever's powering JSON, it works" );

}

done_testing;
