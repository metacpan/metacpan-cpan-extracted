use Test::More tests => 1;
use Data::HTMLDumper;

warn "Ignore warnings, undef test in progress.\n";

my $hash = {
    attribute => "avalue", property => { 1, 2, 3 }
};

my $table = Dumper($hash);
my @table = split /\n/, $table;

my $expected_table = <<EOJ;
<table border='1'>
<tr>  <td>  attribute  </td>
<td>  <table border='1'><tr><td>avalue</td></tr>
    </table>
  </td> </tr>
<tr>  <td>  property  </td>
<td>  <table border='1'>
<tr>  <td>  1  </td>
<td>  <table border='1'><tr><td>2</td></tr>
    </table>
  </td> </tr>
<tr>  <td>  3  </td>
<td>  <table border='1'><tr><td>undef</td></tr>
    </table>
  </td> </tr>
    </table>
  </td> </tr>
</table>
EOJ
my @correct = split /\n/, $expected_table;

is_deeply(\@table, \@correct, "hash with undef");

