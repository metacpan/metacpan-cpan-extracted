use Loud;

$a = 7;
$b = 'cat3';

for (1..3) {
	our $x : Loud = $a++;

	print "$x\n";

	$x = $b++;

	print "$x\n";
}
