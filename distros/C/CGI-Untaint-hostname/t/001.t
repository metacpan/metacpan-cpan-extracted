# -*- cperl-mode -*-
use strict;
use blib;
use Test::More;
use Test::CGI::Untaint;
# t/001.t check domain name validation

my @extractable = qw/xyz abcdefg.com abc-defg.com abc123.com abc-123.com www.abc-123.com bc.def.g a1.b2.c3 abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwx-z.com/;
my @invalid = qw/abc_123.c @home.com ab\040c abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxz-12345.com/;
plan tests => @extractable + @invalid;
#see that each of these is extracted
my $case;
foreach $case (@extractable) {
  is_extractable($case,$case,"hostname") or diag("cannot extract $case\n");
}
foreach $case (@invalid) {
  unextractable($case,"hostname") or diag("unexpectedly extracted $case\n");
}



