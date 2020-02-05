#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Differences;
use Sort::Naturally;
use Config::UCL;

# libucl-0.8.1/tests/test_basic.c
my $opt = {
    ucl_parser_flags => UCL_PARSER_KEY_LOWERCASE,
    ucl_parser_register_variables => [ ABI => "unknown" ],
};

#chdir "libucl-0.8.1/tests/basic" or die;
my @in = nsort glob "libucl-0.8.1/tests/basic/*.in";
for my $in (@in) {
    my $got = eval { ucl_load_file($in, $opt) };
    ok !$@, $in or diag $@.ucl_schema_error();
    my $res = $in =~ s/\.in$/.res/r;
    if ( -f $res ) {
        my $expected = ucl_load_file($res, $opt);
        eq_or_diff $got, $expected, $res or diag ucl_schema_error();
    }
}

done_testing;
