# -*- Mode: Perl; -*-

=head1 NAME

2_fill_09_default_type.t - Test CGI::Ex::Fill's ability to set default falues

=cut

use strict;
use Test::More tests => 2;

use_ok('CGI::Ex::Fill');


my $hidden_form_in = qq{<INPUT NAME="foo1" value="nada">
<input type="hidden" name="foo2">};

my %fdat = (foo1 => 'bar1',
	foo2 => 'bar2');

my $output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                      \%fdat);
ok($output =~ m/^<input( (name="foo1"|value="bar1")){2}>\s*<input( (type="hidden"|name="foo2"|value="bar2")){3}>$/i,
   "Should match ($output)");
