# $generate * 3
# +2 (load and number generated)
use Test::More tests => 30002;
my $generate = 10000;

BEGIN {
use_ok( 'Data::Token' );
}

# Make sure they are uniue
my %dups = ();
for my $i (1..$generate) {
	my $t = token;
	if (!exists($dups{$t})) { $dups{$t} = 0 }
	$dups{$t} = $dups{$t} + 1;
}

cmp_ok (scalar(keys %dups), '==', $generate, "Invalid number of generated tokens (" .  scalar(keys %dups) . " of $generate)");
foreach my $token (keys %dups) {
	cmp_ok($dups{$token}, '==', 1, "Valid only once !");
	ok (length($token) > 5);
	# Complex enough?
	like ($token, qr/[a-zA-Z0-9]/);
}
