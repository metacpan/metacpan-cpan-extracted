use Test::More tests => 1;

use strict;
use Data::HTMLDumper;

#----------------------------------------------------------------

$Data::HTMLDumper::Sortkeys = 1;

my $hash = { name => 'phil', id => 'pcrow' };

my @dump = split /\n/, Dumper($hash);

my @correct = split /\n/, q{<table border='1'>
<tr>  <td>  id  </td>
<td>  <table border='1'><tr><td>pcrow</td></tr>
    </table>
  </td> </tr>
<tr>  <td>  name  </td>
<td>  <table border='1'><tr><td>phil</td></tr>
    </table>
  </td> </tr>
</table>
};

is_deeply(\@dump, \@correct, "sorted keys");

