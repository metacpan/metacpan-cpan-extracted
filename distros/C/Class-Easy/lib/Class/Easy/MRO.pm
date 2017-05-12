package Class::Easy;

use Class::Easy::Import;

sub __get_linear_isa_dfs {
	my $classname = shift;
	
	my @lin = ($classname);
	my %stored;
	foreach my $parent (@{"$classname\::ISA"}) {
		my $plin = __get_linear_isa_dfs($parent);
		foreach (@$plin) {
			next if exists $stored{$_};
			push(@lin, $_);
			$stored{$_} = 1;
		}
	}
	return \@lin;
}

sub __get_linear_isa {
	my ($classname, $type) = @_;
	die "mro::get_mro requires a classname"
		if !defined $classname;
	
	$type ||= exists $Class::C3::MRO{$classname} ? 'c3' : 'dfs';
	if($type eq 'dfs') {
		return __get_linear_isa_dfs($classname);
	} elsif($type eq 'c3') {
		return [Class::C3::calculateMRO($classname)];
	}
	die "type argument must be 'dfs' or 'c3'";
}

1;