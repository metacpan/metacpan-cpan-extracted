use Test::More tests => 2;
use Data::HTMLDumper;

my $list = [
    "EJ Crow & Sons", "Quality > Price", "Our Time < Your Time",
];

my $table = Dumper($list);
my @table = split /\n/, $table;

my $expected_table = <<EOJ;
<table border='1'><tr><td>EJ Crow &amp; Sons</td>
<td>Quality &gt; Price</td>
<td>Our Time &lt; Your Time</td>
</tr></table>
EOJ
my @correct = split /\n/, $expected_table;

is_deeply(\@table, \@correct, "special chars in list element");

#----------------------------------------------------------

my $hash = { 'key+funky_chars&*@!#%^' => 'forty-two' };
@table = split /\n/, Dumper($hash);

my @correct_table = split /\n/,
q{<table border='1'>
<tr>  <td>  key+funky_chars&amp;*@!#%^  </td>
<td>  <table border='1'><tr><td>forty-two</td></tr>
    </table>
  </td> </tr>
</table>
};

is_deeply(\@table, \@correct_table, "special chars in hash key");
