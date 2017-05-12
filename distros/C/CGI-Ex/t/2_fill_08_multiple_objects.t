# -*- Mode: Perl; -*-

=head1 NAME

2_fill_08_multiple_objects.t - Test CGI::Ex::Fill's ability to fill using multiple form objects

=cut

use strict;
use Test::More tests => 2;

use_ok('CGI::Ex::Fill');

SKIP: {

skip('CGI.pm not found', 1) if ! eval { require CGI };

my $hidden_form_in = qq{<INPUT TYPE="TEXT" NAME="foo1" value="nada">
<input type="hidden" name="foo2">};

my %fdat = (foo1 => 'bar1',
            foo2 => 'bar2');

my $q1 = CGI->new({ foo1 => 'bar1' });
my $q2 = CGI->new({ foo2 => 'bar2' });

my $output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                      [$q1, $q2]);
ok($output =~ m/^<input( (type="TEXT"|name="foo1"|value="bar1")){3}>\s*<input( (type="hidden"|name="foo2"|value="bar2")){3}>$/i,
   "Should match ($output)");

}; #end of SKIP
