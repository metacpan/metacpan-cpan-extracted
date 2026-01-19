use strict;
use warnings;
use Test::More;

use Datafile::Array qw(parse_csv_line);

my @tests = (
    ['a,b,c'                  => ['a','b','c']],
    ['"a","b","c"'            => ['a','b','c']],
    ['a,"b,c",d'              => ['a','b,c','d']],
    ['a,"b""c",d'             => ['a','b"c','d']],
    ['"unclosed'              => ['unclosed']],
    ['""'                     => ['']],
    ['"",""'                  => ['','']],
    ['a; b; c'                => ['a',' b',' c'], ';'],
);

for my $t (@tests) {
    my ($line, $expected, $delim) = @$t;
    $delim //= ',';
    my @got = parse_csv_line($line, $delim);
    is_deeply(\@got, $expected, "parse: $line");
}

done_testing;
