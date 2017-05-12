package Class::Easy::Log::Tie;

sub print_stderr {
	my $this   = shift;
	my $stderr = $this->{STDERR};
	
	if (!defined $stderr) {
		# enabled, but no logging
	} elsif (ref($stderr) eq 'SCALAR') {
		$$stderr .= $_[0] ;
	} elsif (ref($stderr) eq 'CODE') {
		&$stderr($_[0]);
	} else {
		print $stderr $_[0];
	}
	
	return 1;
}

sub TIESCALAR {
	my $class = shift;
	bless ({STDERR => $_[0]}, $class);
}

sub TIEHANDLE {
	my $class = shift;
	bless ({STDERR => $_[0]}, $class);
}

sub STORE {
	my $this = shift;
	
	$this->print_stderr (join ("", @_));
	return 1;
}


sub PRINT {
	my $this = shift;
	
	$this->print_stderr (join ("", @_));
	return 1;
}

sub PRINTF {
	&PRINT ($_[0], sprintf ($_[1], @_[2..$#_]));
}

sub READ {}
sub FETCH {}
sub READLINE {}
sub GETC {}
sub WRITE {}
sub FILENO {}
sub CLOSE {}
sub DESTROY {}

1;