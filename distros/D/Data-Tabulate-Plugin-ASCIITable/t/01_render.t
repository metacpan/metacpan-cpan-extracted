#!perl -T

use Data::Tabulate::Plugin::ASCIITable;
use Test::More;

eval "use Data::Tabulate";
plan skip_all => "Data::Tabulate is not installed" if $@;

plan tests => 1;
my @array     = (1..10);
my $tabulator = Data::Tabulate->new();
my $html      = $tabulator->render('ASCIITable',{data => [@array]});

my $check     = q~.----+---+---.
| 1  | 2 | 3 |
| 4  | 5 | 6 |
| 7  | 8 | 9 |
| 10 |   |   |
'----+---+---'
~;

is($html,$check);
