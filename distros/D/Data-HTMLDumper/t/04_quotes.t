use Test::More tests => 1;
use Data::HTMLDumper;

my $list = [
    "EJ's Sons", "Quality > Price", "Our Time < Your Time",
];

my $table = Dumper($list);
my @table = split /\n/, $table;

my $expected_table = <<EOJ;
<table border='1'><tr><td>EJ's Sons</td>
<td>Quality &gt; Price</td>
<td>Our Time &lt; Your Time</td>
</tr></table>
EOJ
my @correct = split /\n/, $expected_table;

is_deeply(\@table, \@correct, "single quote");

