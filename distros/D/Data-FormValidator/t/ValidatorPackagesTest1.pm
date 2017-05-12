package ValidatorPackagesTest1;

sub match_single_validator_success_expected {
	my $val = shift;
	return 1;
}

sub match_single_validator_failure_expected {
	return undef;
}

sub filter_single_filter_remove_whitespace {
	my $val = shift;
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
    return $val;
}

1;
