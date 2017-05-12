
print "1..4\n";

$x = "f";

$y = $x ne "f";

if ($y ne "1") { print "ok 1\n" } else { print "not ok 1\n" }

$z = $x ne "ggo";

if ($z ne "") { print "ok 2\n" } else { print "not ok 2\n" }


$y = $x eq "f";

if ($y eq "1") { print "ok 3\n" } else { print "not ok 3\n" }

$z = $x eq "ggo";

if ($z eq "") { print "ok 4\n" } else { print "not ok 4\n" }
