# No real tests, but only a notice to the user.

if ($ENV{INTERACTIVE_TEST})
{
    system $^X, "./examples/demo-widgets";
} else {
    print "\n";
    print "-"x70 . "\n";
    print "All load tests were successful. If you want to\n";
    print "do an interactive test, then run:\n";
    print "\n";
    print "  make test INTERACTIVE_TEST=1\n";
    print "\n";
    print "-"x70 . "\n";
    print "\n";
}
