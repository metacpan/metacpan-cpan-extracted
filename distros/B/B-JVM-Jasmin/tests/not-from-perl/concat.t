print "1..2\n";

$x = "";
$y = "o";

$x .= $y;

$y = "1";

$x .= "k" . " " . ($y .= "\n");

print $x;

$y = " ";

print "o" . "k" . ($y .= '2') . "\n";
