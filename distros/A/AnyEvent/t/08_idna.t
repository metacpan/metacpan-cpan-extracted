use utf8;

use AnyEvent;
use AnyEvent::Util;

$| = 1; print "1..11\n";

print "ok 1\n";

print "ko-eka" eq (AnyEvent::Util::punycode_encode "\x{f6}ko" ) ? "" : "not ", "ok 2\n";
print "wgv71a" eq (AnyEvent::Util::punycode_encode "\x{65e5}\x{672c}") ? "" : "not ", "ok 3\n";

print "\x{f6}ko"  eq (AnyEvent::Util::punycode_decode "ko-eka") ? "" : "not ", "ok 4\n";
print "\x{65e5}\x{672c}" eq (AnyEvent::Util::punycode_decode "wgv71a") ? "" : "not ", "ok 5\n";

print "www.xn--ko-eka.eu"   eq (AnyEvent::Util::idn_to_ascii "www.\x{f6}ko.eu"  ) ? "" : "not ", "ok 6\n";
print "xn--1-jn6bt1b.co.jp" eq (AnyEvent::Util::idn_to_ascii "\x{65e5}\x{672c}1.co.jp" ) ? "" : "not ", "ok 7\n";
print "xn--tda.com"         eq (AnyEvent::Util::idn_to_ascii "xn--tda.com" ) ? "" : "not ", "ok 8\n";
print "xn--a-ecp.ru"        eq (AnyEvent::Util::idn_to_ascii "xn--a-ecp.ru") ? "" : "not ", "ok 9\n";
print "xn--wgv71a119e.jp"   eq (AnyEvent::Util::idn_to_ascii "\x{65e5}\x{672c}\x{8a9e}\x{3002}\x{ff2a}\x{ff30}") ? "" : "not ", "ok 10\n";

print "ok 11\n";
