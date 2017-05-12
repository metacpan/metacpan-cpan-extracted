# -*- Mode: Perl; -*-

=head1 NAME

2_fill_18_coderef.t - Test CGI::Ex::Fill's ability to use coderef callbacks

=cut

use strict;
use Test::More tests => 4;

use_ok('CGI::Ex::Fill');

my $ok2 = 0;
my $ok3 = 0;

my $hidden_form_in = qq{<input type="hidden" name="foo1">
<input type="hidden" name="foo2" value="ack">};

my %fdat = (foo1 => sub { $ok2 ++; return 'bar1' },
            );
my $cdat = sub {
  $ok3 ++;
  my $key = shift;
  return ($key eq 'foo2') ? 'bar2' : '';
};

my $output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                      [\%fdat, $cdat]);

ok($ok2);
ok($ok3);

ok($output =~ m/^<input( (type="hidden"|name="foo1"|value="bar1")){3}>\s*<input( (type="hidden"|name="foo2"|value="bar2")){3}>$/,
   "Should match ($output)");

