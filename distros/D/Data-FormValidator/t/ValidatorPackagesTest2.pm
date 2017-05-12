package ValidatorPackagesTest2;

sub valid_multi_validator_success_expected {
	my $val = shift;
	return 1;
}

sub valid_multi_validator_failure_expected {
	return undef;
}

1;
