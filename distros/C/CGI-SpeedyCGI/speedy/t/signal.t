
# Bug: signals aren't reset between perl interpreter runs.

# The shutdown test script sets SIGTERM to ignore.  If we send a TERM signal
# to speedy after we run the test script, it should exit cleanly and call the
# shutdown handler.

print "1..1\n";

my $scr = 't/scripts/shutdown';
my $testf = "/tmp/speedy.shutdown_done.$$";

unlink $testf;
utime time, time, $scr;
sleep 2;
my $pid = `$ENV{SPEEDY} -- -r2 $scr $testf`;
sleep 1;
$pid && kill 15, $pid;
sleep 1;
print -f $testf ? "ok\n" : "not ok\n";
unlink $testf;
