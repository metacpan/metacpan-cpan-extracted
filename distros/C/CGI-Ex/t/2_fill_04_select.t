# -*- Mode: Perl; -*-

=head1 NAME

2_fill_04_select.t - Test CGI::Ex::Fill's ability to fill select fields

=cut

use strict;
use Test::More tests => 5;

use_ok('CGI::Ex::Fill');

my $hidden_form_in = qq{<select multiple name="foo1">
	<option value="0">bar1</option>
	<option value="bar2">bar2</option>
	<option value="bar3">bar3</option>
</select>
<select multiple name="foo2">
	<option value="bar1">bar1</option>
	<option value="bar2">bar2</option>
	<option value="bar3">bar3</option>
</select>
<select multiple name="foo3">
	<option value="bar1">bar1</option>
	<option selected value="bar2">bar2</option>
	<option value="bar3">bar3</option>
</select>
<select multiple name="foo4">
	<option value="bar1">bar1</option>
	<option selected value="bar2">bar2</option>
	<option value="bar3">bar3</option>
</select>};
my $q = {
    foo1 => '0',
    foo2 => ['bar1', 'bar2',],
    foo3 => '',
};

my $output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                      $q);

my $is_selected = join(" ",map { m/selected/ ? "yes" : "no" } grep /option/, split ("\n",$output));

ok($is_selected eq "yes no no yes yes no no no no no yes no",
   "Selected should match ($is_selected)");


$hidden_form_in = qq{<select multiple name="foo1">
	<option>bar1</option>
	<option>bar2</option>
	<option>bar3</option>
</select>
<select multiple name="foo2">
	<option> bar1</option>
	<option> bar2</option>
	<option>bar3</option>
</select>
<select multiple name="foo3">
	<option>bar1</option>
	<option selected>bar2</option>
	<option>bar3</option>
</select>
<select multiple name="foo4">
	<option>bar1</option>
	<option selected>bar2</option>
	<option>bar3  </option>
</select>};

$q = {
    foo1 => 'bar1',
    foo2 => ['bar1', 'bar2',],
    foo3 => '',
};

$output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                   $q);

$is_selected = join(" ",map { m/selected/ ? "yes" : "no" } grep /option/, split ("\n",$output));

ok($is_selected eq "yes no no yes yes no no no no no yes no",
   "Selected should match ($is_selected)");

# test empty option tag

$hidden_form_in = qq{<select name="x"><option></select>};

$output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                   $q);
ok($output eq qq{<select name="x"><option></select>},
   "Should match ($output)");

$hidden_form_in = qq{<select name="foo1"><option><option value="bar1"></select>};
$output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                   $q);
ok($output =~ m!^<select name="foo1"><option><option( selected(="selected")?| value="bar1"){2}></select>$!,
   "Should match ($output)");

