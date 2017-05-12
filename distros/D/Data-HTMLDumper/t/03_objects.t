use Test::More tests => 1;
use Data::HTMLDumper;

#-------------------------------------------------------------------

my $object = Trivial->new();

my $table  = Dumper($object);

my $expected_table;

my $list = [
    "some", "words", "and an object", $object
];

$table = Dumper($list);
my @table = split /\n/, $table;

$expected_table = <<EOJ;
<table border='1'><tr><td>some</td>
<td>words</td>
<td>and an object</td>

<td><table border='1'><tr><td><table border='1'>
<tr>  <td>  attribute  </td>
<td>  <table border='1'><tr><td>value</td></tr>
    </table>
  </td> </tr>
<tr>  <td>  property  </td>
<td>  <table border='1'><tr><td>5</td></tr>
    </table>
  </td> </tr>
</table></td>
<td> isa Trivial </td>
</tr></table></td>
</tr></table>
EOJ

my @correct = split /\n/, $expected_table;

is_deeply(\@table, \@correct, "blessings");

#------------------------------------------------------------

package Trivial;

sub new {
    my $class = shift;
    return bless { attribute => "value", property => 5 }, $class;
}

#------------------------------------------------------------

