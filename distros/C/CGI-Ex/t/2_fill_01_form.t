# -*- Mode: Perl; -*-

=head1 NAME

2_fill_01_form.t - Test CGI::Ex::Fill's ability to fill hidden fields

=cut

use strict;
use Test::More tests => 2;

use_ok('CGI::Ex::Fill');

my $hidden_form_in = '
<INPUT TYPE="TEXT" NAME="foo1" value="nada">
<input type="hidden" name="foo2"/>
';

my %fdat = (foo1 => 'bar1',
            foo2 => '"bar2"');


my $output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                      \%fdat);
ok($output =~ m/^\s*<input( (type="TEXT"|name="foo1"|value="bar1")){3}>\s*<input( (type="hidden"|name="foo2"|value="&quot;bar2&quot;")){3}\s*\/>\s*$/i,
   "Basic case insensitive match worked ($output)");
