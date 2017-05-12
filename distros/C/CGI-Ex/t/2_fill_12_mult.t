# -*- Mode: Perl; -*-

=head1 NAME

2_fill_12_mult.t - Test CGI::Ex::Fill's ability to fill multiple instances of the same field name

=cut

use strict;
use Test::More tests => 4;

use_ok('CGI::Ex::Fill');

my $hidden_form_in = qq{<INPUT TYPE="TEXT" NAME="foo1" value="cat1">
<input type="text" name="foo1" value="cat2"/>};

my %fdat = (foo1 => ['bar1','bar2']);

my $output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                      \%fdat);
ok($output =~ m/^<input( (type="TEXT"|name="foo1"|value="bar1")){3}>\s*<input( (type="text"|name="foo1"|value="bar2")){3}\s*\/>$/i,
   "Should match ($output)");


%fdat = (foo1 => ['bar1']);

$output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                   \%fdat);
ok($output =~ m/^<input( (type="TEXT"|name="foo1"|value="bar1")){3}>\s*<input( (type="text"|name="foo1"|value="")){3}\s*\/>$/i,
   "Should match ($output)");

%fdat = (foo1 => 'bar1');

$output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                   \%fdat);
ok($output =~ m/^<input( (type="TEXT"|name="foo1"|value="bar1")){3}>\s*<input( (type="text"|name="foo1"|value="bar1")){3}\s*\/>$/i,
   "Should match ($output)");
