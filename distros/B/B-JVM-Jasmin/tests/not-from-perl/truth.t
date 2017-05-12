
print "1..7\n";

# False tests

$x = "";
if ($x) { print "not ok 1\n"; } else { print "ok 1\n"; }

$x = "0";
if ($x) { print "not ok 2\n"; } else { print "ok 2\n"; }

# True tests

$x = "foo";
if ($x) { print "ok 3\n"; } else { print "not ok 3\n"; }

$x = "0.0";
if ($x) { print "ok 4\n"; } else { print "not ok 4\n"; }

$x = "0.00";
if ($x) { print "ok 5\n"; } else { print "not ok 5\n"; }

$x = "00";
if ($x) { print "ok 6\n"; } else { print "not ok 6\n"; }

$x = "0.";
if ($x) { print "ok 7\n"; } else { print "not ok 7\n"; }
