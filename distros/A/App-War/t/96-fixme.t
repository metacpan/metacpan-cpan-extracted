use strict;
use warnings FATAL => 'all';
use Test::More;

eval 'use Test::Fixme';
plan skip_all => "Test::Fixme required for fixme tests" if $@;
run_tests(
    filename_match => qr/war|\.(?:pl|pm|txt)$/i,
    match => qr/[F]IXME/,
);
#run_tests(filename_match => qr{war});
