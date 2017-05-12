use Test::More tests => 1;

use Data::HTMLDumper;

#----------------------------------------------------------------

my $hash = { 'name' => 'value', 'attribute' => 'string' };
my $list = [ 'value', 'string' ];

my @dump = split /\n/, Dumper($hash, $list);

my @correct = split /\n/, q{<table border='1'>
<tr>  <td>  attribute  </td>
<td>  <table border='1'><tr><td>string</td></tr>
    </table>
  </td> </tr>
<tr>  <td>  name  </td>
<td>  <table border='1'><tr><td>value</td></tr>
    </table>
  </td> </tr>
</table>
<table border='1'><tr><td>value</td>
<td>string</td>
</tr></table>
};

is_deeply(\@dump, \@correct, "double call");

