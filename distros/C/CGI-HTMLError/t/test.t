# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
$|=1;

BEGIN {
	warn "
=== Message from the safety and civil reassurance dept. ===

You will see some warnings output to STDERR during the
tests. This is normal and you are perfectly safe as long as
the tests say you are :-)

==================== Message ends =========================
";
}
use Test::More tests => 8;

use_ok('CGI::HTMLError');

$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';

my $output = `$^X t/crash.cgi`;

ok($output =~ /crash.cgi line 4/,"Line number captured");

ok($output =~ /^status: 500/i,"Server error set");

ok($output =~ /use CGI::HTMLError trace =&gt; 1/,"Source code");

ok($output =~ /\&CGI::HTMLError::show_source called at t\/crash.cgi line/,"Stacktrace");

$output = `$^X t/no_line_number.cgi`;

ok($output =~ /Exception caused at .*?no_line_number.cgi line 8/,"Filename from stack");

$output = `$^X t/last_digit.cgi`;

ok(index($output,'0015| <strong>die "here') >= 0,"higher line numbers");


delete $ENV{GATEWAY_INTERFACE};

$output = `$^X t/crash.cgi`;
ok($output eq '',"Silent on CLI");



