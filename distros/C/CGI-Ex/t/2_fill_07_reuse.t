# -*- Mode: Perl; -*-

=head1 NAME

2_fill_02_hidden.t - Test CGI::Ex::Fill's ability to fill refill used fields

=cut

use strict;
use Test::More tests => 2;

use_ok('CGI::Ex::Fill');

my $hidden_form_in = qq{<INPUT TYPE="TEXT" NAME="foo1" value="nada">
<input type="hidden" name="foo2">};

my %fdat = (foo1 => ['bar1'],
	foo2 => 'bar2');

my $output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                      \%fdat);
my $output2 = CGI::Ex::Fill::form_fill($output,
                                       \%fdat);
ok($output2 =~ m/^<input( (type="TEXT"|name="foo1"|value="bar1")){3}>\s*<input( (type="hidden"|name="foo2"|value="bar2")){3}>$/i,
   "Should match ($output2)");
