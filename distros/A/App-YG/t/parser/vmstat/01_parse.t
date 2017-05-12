use strict;
use warnings;
use Test::More;
use t::AppYGParserTest qw/can_parse parse_fail/;

my $parser_class = 'App::YG::Vmstat';
require_ok $parser_class;

note '----- OK -----';

can_parse(
    $parser_class,
    'procs -----------memory---------- ---swap-- -----io---- --system-- -----cpu------',
    [],
);

can_parse(
    $parser_class,
    ' r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st',
    [],
);

can_parse(
    $parser_class,
    ' 0  0 113024 202172  60952  80820    0    0     1     1    0    0  0  0 100  0  0',
    [
        "0",
        "0",
        "113024",
        "202172",
        "60952",
        "80820",
        "0",
        "0",
        "1",
        "1",
        "0",
        "0",
        "0",
        "0",
        "100",
        "0",
        "0",
    ],
);

done_testing;
