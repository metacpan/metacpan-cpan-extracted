# -*- Mode: Perl; -*-

=head1 NAME

2_fill_03_checkbox.t - Test CGI::Ex::Fill's ability to fill checkboxes fields

=cut

use Test::More tests => 2;
use strict;

use_ok('CGI::Ex::Fill');

my $hidden_form_in = qq{<input type="checkbox" name="foo1" value="bar1">
<input type="checkbox" name="foo1" value="bar2">
<input type="checkbox" name="foo1" value="bar3">
<input type="checkbox" name="foo2" value="bar1">
<input type="checkbox" name="foo2" value="bar2">
<input type="checkbox" name="foo2" value="bar3">
<input type="checkbox" name="foo3" value="bar1">
<input type="checkbox" name="foo3" checked value="bar2">
<input type="checkbox" name="foo3" value="bar3">
<input type="checkbox" name="foo4" value="bar1">
<input type="checkbox" name="foo4" checked value="bar2">
<input type="checkbox" name="foo4" value="bar3">
<input type="checkbox" name="foo5">
<input type="checkbox" name="foo6">
<input type="checkbox" name="foo7" checked>
<input type="checkbox" name="foo8" checked>};

my %fdat = (foo1 => 'bar1',
           foo2 => ['bar1', 'bar2',],
	   foo3 => '',
	   foo5 => 'on',
	   foo6 => '',
	   foo7 => 'on',
	   foo8 => '');

my $output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                      \%fdat);

my $is_checked = join(" ",map { m/checked/i ? "yes" : "no" } split ("\n",$output));

ok($is_checked eq "yes no no yes yes no no no no no yes no yes no yes no",
   "Checkboxes should match ($is_checked)");

