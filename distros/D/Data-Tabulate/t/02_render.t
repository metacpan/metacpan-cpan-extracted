#!perl -T

use Data::Tabulate;
use Test::More;

eval "use Data::Tabulate::Plugin::HTMLTable 0.201";
plan skip_all => "Data::Tabulate::Plugin::HTMLTable is not installed" if $@;

plan tests => 1;
my @array     = (1..10);
my $tabulator = Data::Tabulate->new();
my $html      = $tabulator->render('HTMLTable',{data => [@array]});

my $check     = q~
<table>
<tbody>
<tr><td>1</td><td>2</td><td>3</td></tr>
<tr><td>4</td><td>5</td><td>6</td></tr>
<tr><td>7</td><td>8</td><td>9</td></tr>
<tr><td>10</td><td>&nbsp;</td><td>&nbsp;</td></tr>
</tbody>
</table>
~;

is($html,$check);