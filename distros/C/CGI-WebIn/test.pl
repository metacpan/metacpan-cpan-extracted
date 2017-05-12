# Before `make install' is performed this script should be runnable with #
# `make test'. After `make install' it should work as `perl test.pl'     #
##########################################################################

use Test;
BEGIN { plan tests => 2 };
use CGI::WebIn;

ok(1); # If we made it this far, we're ok.

open(F,"test.pl"); binmode(F);
$/=undef;
$orig=<F>;
close(F);

my $s=$orig;
CGI::WebIn::URLEncode($s);
CGI::WebIn::URLDecode($s);

if($s ne $orig) { printf("Bad luck\n") } else { ok(2) }
