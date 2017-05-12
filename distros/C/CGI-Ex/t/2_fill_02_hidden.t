# -*- Mode: Perl; -*-

=head1 NAME

2_fill_02_hidden.t - Test CGI::Ex::Fill's ability to fill hidden fields

=cut

use strict;
use Test::More tests => 2;

use_ok('CGI::Ex::Fill');

my $hidden_form_in = qq{<input type="hidden" name="foo1">
<input type="hidden" name="foo2" value="ack">};

my %fdat = (foo1a => 'bar1a',
            foo2  => ['bar2','bar3'],
            );


my $output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                      \%fdat);
ok($output =~ m/^<input( (type="hidden"|name="foo1"|value="")){3}>\s*<input( (type="hidden"|name="foo2"|value="bar2")){3}>$/,
   "Hidden should've matched ($output)");

