# -*- Mode: Perl; -*-

=head1 NAME

2_fill_06_radio.t - Test CGI::Ex::Fill's ability to fill radio fields

=cut

use strict;
use Test::More tests => 2;

use_ok('CGI::Ex::Fill');

my $hidden_form_in = qq{<INPUT TYPE="radio" NAME="foo1" value="bar1">
<input type="radio" name="foo1" value="bar2">
<input type="radio" name="foo1" value="bar3">
<input type="radio" name="foo1" checked value="bar4">};

my %fdat = (foo1 => 'bar2');

my $output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                      \%fdat);
my $is_checked = join(" ",map { m/checked/ ? "yes" : "no" } split ("\n",$output));
ok($is_checked eq 'no yes no no',
   "Should match ($is_checked)");
