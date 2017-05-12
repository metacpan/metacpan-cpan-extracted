# -*- Mode: Perl; -*-

=head1 NAME

2_fill_16_ignore_fields.t - Test CGI::Ex::Fill's ability to fill ignore some fields

=cut

use strict;
use Test::More tests => 2;

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

my $output = CGI::Ex::Fill::form_fill($hidden_form_in, $q, undef, undef, ['asdf','foo1','asdf']);

my $is_selected = join(" ",map { m/selected/ ? "yes" : "no" } grep /option/, split ("\n",$output));

ok($is_selected eq "no no no yes yes no no no no no yes no",
   "Should match ($is_selected)");
