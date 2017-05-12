# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#-------------------------------------------------------------------

use Test::More tests => 7;
BEGIN { use_ok('Data::HTMLDumper') };
# Do not use Data::Dumper, HTMLDumper does that for us, doing it again
# raises flags.

#-------------------------------------------------------------------

my $list = [
    "phil", "crow", "programmer"
];

my $table = Dumper($list);
my $expected_table = <<EOJ;
<table border='1'><tr><td>phil</td>
<td>crow</td>
<td>programmer</td>
</tr></table>
EOJ

is($table, $expected_table, "simple list");

$list = [
    "phil", "crow", "programmer",
];

$table = Dumper($list);

is($table, $expected_table, "simple list trailing comma");

#-------------------------------------------------------------------

my $first_hash = {
    name => "phil", id => "pcrow"
};
my $first_hash_table = Dumper($first_hash);
my $expected_first_hash = <<EOJ;
<table border='1'>
<tr>  <td>  name  </td>
<td>  <table border='1'><tr><td>phil</td></tr>
    </table>
  </td> </tr>
<tr>  <td>  id  </td>
<td>  <table border='1'><tr><td>pcrow</td></tr>
    </table>
  </td> </tr>
</table>
EOJ

@module_out  = map { s/\s+$//; $_ } split(/\n/, $first_hash_table);
@correct_out = split /\n/, $expected_first_hash;

is_deeply(\@module_out, \@correct_out, "simple hash");

#-------------------------------------------------------------------

$first_hash = {
    name => "phil", id => "pcrow",
};

$first_hash_table = Dumper($first_hash);
@module_out  = map { s/\s+$//; $_ } split(/\n/, $first_hash_table);

is_deeply(\@module_out, \@correct_out, "simple hash trailing comma");

#-------------------------------------------------------------------

my $hash = {
    phil => [
        { type => 'desk'},
        { type => 'home'},
        { type => 'pager'},
    ],
};

my $hash_of_one_list = <<"EOJ";
<table border='1'>
<tr>  <td>  phil  </td>
<td>  <table border='1'><tr>
<tr>  <td>  type  </td>
<td>  <table border='1'><tr><td>desk</td></tr>
    </table>
  </td> </tr>

<tr>  <td>  type  </td>
<td>  <table border='1'><tr><td>home</td></tr>
    </table>
  </td> </tr>

<tr>  <td>  type  </td>
<td>  <table border='1'><tr><td>pager</td></tr>
    </table>
  </td> </tr>
</tr>    </table>
  </td> </tr>
</table>
EOJ

my $module_out = Dumper($hash);
my @module_out = split /\n/, $module_out;
my @correct    = split /\n/, $hash_of_one_list;

is_deeply (\@module_out, \@correct, "hash of one list");

#-------------------------------------------------------------------

$hash = {
    phil => [
        { type => 'desk'},
        { type => 'home'},
        { type => 'pager'},
    ],
    frank => [
        { type => 'desk'},
        { type => 'pager'},
        { type => 'home'},
    ],
};

$module_out = Dumper($hash);
@module_out = split /\n/, $module_out;
chomp(@correct = <DATA>);

is_deeply (\@module_out, \@correct, "hash of lists");

#-------------------------------------------------------------------

__DATA__
<table border='1'>
<tr>  <td>  phil  </td>
<td>  <table border='1'><tr>
<tr>  <td>  type  </td>
<td>  <table border='1'><tr><td>desk</td></tr>
    </table>
  </td> </tr>

<tr>  <td>  type  </td>
<td>  <table border='1'><tr><td>home</td></tr>
    </table>
  </td> </tr>

<tr>  <td>  type  </td>
<td>  <table border='1'><tr><td>pager</td></tr>
    </table>
  </td> </tr>
</tr>    </table>
  </td> </tr>
<tr>  <td>  frank  </td>
<td>  <table border='1'><tr>
<tr>  <td>  type  </td>
<td>  <table border='1'><tr><td>desk</td></tr>
    </table>
  </td> </tr>

<tr>  <td>  type  </td>
<td>  <table border='1'><tr><td>pager</td></tr>
    </table>
  </td> </tr>

<tr>  <td>  type  </td>
<td>  <table border='1'><tr><td>home</td></tr>
    </table>
  </td> </tr>
</tr>    </table>
  </td> </tr>
</table>
