# -*- Mode: Perl; -*-

=head1 NAME

2_fill_19_complex.t - Test CGI::Ex::Fill's regex against difficult tags (with embeded html)

=cut

use strict;
use Test::More tests => 2;

use_ok('CGI::Ex::Fill');

my $string = qq{
<input attr="<br value='waw'>
<br>" type="hidden" name="foo1">
};

my %fdat = (foo1 => 'bar1');


CGI::Ex::Fill::form_fill(\$string,
                         \%fdat,
                         );

ok($string =~ m/ value="bar1"/,
   "Should match ($string)");
