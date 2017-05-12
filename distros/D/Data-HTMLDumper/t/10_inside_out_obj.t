use Test::More tests => 1;
use Data::HTMLDumper;

my $inside_out = InsideOut->new();

my $hash = {
    'inside_out'     => $inside_out,
};

my $table = Dumper($hash);
my @table = split /\n/, $table;

my $expected_table = <<'EOJ';
<table border='1'>
<tr>  <td>  inside_out  </td>
<td>  <table border='1'>
<td><table border='1'><tr><td><table border='1'>
do{(\(my $o = 171800944))}
</table></td>
<td> isa InsideOut </td>
</tr></table></td>
    </table>
  </td> </tr>
</table>
EOJ
my @correct = split /\n/, $expected_table;

is_deeply(\@table, \@correct, "special chars in list element");

package InsideOut;

sub new {
    my $class = shift;

    return bless do{\(my $o     = 171800944)}, $class;
}
