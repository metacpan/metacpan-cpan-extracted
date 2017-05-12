# -*- Mode: Perl; -*-

=head1 NAME

2_fill_05_textarea.t - Test CGI::Ex::Fill's ability to fill textarea fields

=cut

use strict;
use Test::More tests => 3;

use_ok('CGI::Ex::Fill');

my $hidden_form_in = qq{<TEXTAREA NAME="foo">blah</TEXTAREA>};

my %fdat = (foo => 'bar>bar');

my $output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                      \%fdat);
ok($output eq '<TEXTAREA NAME="foo">bar&gt;bar</TEXTAREA>',
   "Output should match ($output)");

# empty fdat test

%fdat = (foo => '');

$output = CGI::Ex::Fill::form_fill($hidden_form_in,
                                   \%fdat);
ok($output eq '<TEXTAREA NAME="foo"></TEXTAREA>',
   "Output should match ($output)");
