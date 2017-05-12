sub swallow_stderr {
	my ($code) = @_;

	# We can't use the three-arg form with >& because perl 5.6 doesn't seem
	# to support that.
	open my $old_stderr, '>&STDERR';
	close STDERR;

	$code->();

	open STDERR, ">&$old_stderr";
}

1;
