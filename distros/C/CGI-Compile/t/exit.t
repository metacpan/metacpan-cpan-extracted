use strict;
use Test::More tests => 2;
use CGI::Compile;
use t::Capture;
use lib "t";
use Exit;

my $sub = CGI::Compile->compile("t/exit.cgi");
my $out = capture_out($sub);
like $out, qr/Hello/;

pass "Not exiting";

Exit::main;

fail "Should exit";

