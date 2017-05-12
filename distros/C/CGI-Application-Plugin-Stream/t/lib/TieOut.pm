package TieOut;

sub TIEHANDLE {
	bless( \(my $scalar), $_[0]);
}

sub PRINT {
	my $self = shift;
	$$self .= join('', @_);
}

sub PRINTF {
	my $self = shift;
    my $fmt  = shift;
	$$self .= sprintf $fmt, @_;
}

sub read {
	my $self = shift;
	return substr($$self, 0, length($$self), '');
}

# Thanks, Makio!
sub FILENO { 1; }
sub BINMODE { 1; }

1;
