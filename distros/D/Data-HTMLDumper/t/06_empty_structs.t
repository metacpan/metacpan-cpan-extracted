use Test::More tests => 3;

use Data::HTMLDumper;

#----------------------------------------------------------------

my $hash = { '.name' => "value" };

my @dump = split /\n/, Dumper($hash);

my @correct = split /\n/, q{<table border='1'>
<tr>  <td>  .name  </td>
<td>  <table border='1'><tr><td>value</td></tr>
    </table>
  </td> </tr>
</table>
};

is_deeply(\@dump, \@correct, "key has a dot");

#----------------------------------------------------------------

$hash = { name => [] };

@dump = split /\n/, Dumper($hash);
@correct = split /\n/, q{<table border='1'>
<tr>  <td>  name  </td>
<td>  <table border='1'><tr><td>NO_ELEMENTS</td></tr>    </table>
  </td> </tr>
</table>
};

is_deeply(\@dump, \@correct, "empty array");

#----------------------------------------------------------------

$hash = { name => {} };

@dump = split /\n/, Dumper($hash);
@correct = split /\n/, q{<table border='1'>
<tr>  <td>  name  </td>
<td>  <table border='1'><tr><td>NO_PAIRS</td></tr>
    </table>
  </td> </tr>
</table>
};

is_deeply(\@dump, \@correct, "empty hash");
