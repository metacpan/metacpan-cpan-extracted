use Test::More tests => 2;
BEGIN { use_ok("Acme::POE::Tree") };

my $oldout;
if (open $oldout, ">&STDOUT") {
	if (open STDOUT, ">", "/dev/tty") {
		# yay
	}
	else {
		open STDOUT, ">&", $oldout;
		$oldout = undef;
	}
}

Acme::POE::Tree->new({ run_for => 5 })->run();

if ($oldout) {
	open STDOUT, ">&", $oldout;
	$oldout = undef;
}

pass("tree ran");
