package Class::Easy;

require B;

sub get_coderef_info ($) {
	my ($coderef) = @_;
	ref $coderef or return;
	my $cv = B::svref_2object($coderef);
	$cv->isa('B::CV') or return;
	# bail out if GV is undefined
	$cv->GV->isa('B::SPECIAL') and return;
	
	return ($cv->GV->STASH->NAME, $cv->GV->NAME);
};

1;