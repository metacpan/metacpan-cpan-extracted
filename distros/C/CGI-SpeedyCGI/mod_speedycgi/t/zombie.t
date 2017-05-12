#
# The frontend (esp mod_speedycgi) can leave killed backends around as zombies.
# Zombies still appear valid according to kill(2), and since speedy uses kill
# to check on whether backends are still running, they appear to speedy to
# be valid backends.
#

use lib 't';
use ModTest;

my $scr = 'speedy/zombie';

ModTest::test_init(5, [$scr]);

print "1..1\n";

my $one = &ModTest::html_get("/$scr");
sleep 1;
my $two = &ModTest::html_get("/$scr");

## print STDERR "one=$one two=$two\n";

if ($one > 0 && $two > 0 && $one != $two) {
    print "ok\n";
} else {
    print "not ok\n";
}
