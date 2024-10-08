use v5.24;
use Encode;
use utf8;

use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;
my $data = do { local $/; <DATA> };

is(stripe(qw(.+ cpanfile))->run->{result}, 0, "simple run");

is(stripe(qw(.+))->setstdin($data)->run->stdout, $data, "stdin");

delete $ENV{NO_COLOR};
my @esc = qw(
    48;5;28m
    48;5;88m
    48;5;22m
    48;5;52m
);
my @data = $data =~ /.+/g;
my $reset = "\e[m\e[K";
my $result = join "\n", do {
	map { "\e[" . $esc[$_ % @esc] . $data[$_] . $reset; } keys @data;
    }, '';
is(stripe(qw(--darkmode -- --color=always -Si -E [24680]$ -E [13579]$ --need=1 ))->setstdin($data)->run->stdout,
   $result, "numbers");

done_testing;

__DATA__
1
2
3
4
5
6
7
8
9
10
