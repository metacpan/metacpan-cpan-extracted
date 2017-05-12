#
# Test for two bugs:
#
# mod_speedycgi mixes up the speedy options on the #! line in the script
#
# mod_speedycgi can't switch tempbase between scripts because it holds open
# the tempfile.


use lib 't';
use ModTest;

my $scr1 = 'speedy/pid2';
my $scr2 = 'speedy/pid';

ModTest::test_init(5, [$scr1, $scr2]);

print "1..1\n";

my $one = &ModTest::html_get("/$scr1");
sleep 1;
my $two = &ModTest::html_get("/$scr2");

## print STDERR "one=$one two=$two\n";

if ($one > 0 && $two > 0 && $one != $two) {
    print "ok\n";
} else {
    print "not ok\n";
}
