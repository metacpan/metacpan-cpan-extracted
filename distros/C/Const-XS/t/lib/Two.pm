package Two;

use One qw/$one %two @three/;

sub new { bless {}, $_[0] }

sub one {
	return $one;
}

sub two {
	return \%two;
}

sub three {
	return \@three;
}

sub fail_one {
	$one = 'abc';
}

sub fail_two {
	$two{not_exists} = 1;
}

sub fail_three {
	pop @three;
}

1;
