package Algorithm::TrunkClassifier::Util;

use warnings;
use strict;

our $VERSION = 'v1.0.1';

#Description: Sorts two arrays in accending order based on values in the first
#Parameters: (1) Numerical array reference, (2) second array reference
#Return value: None
sub dataSort($ $){
	my ($numArrayRef, $secondArrayRef) = @_;
	my $limiter = 1;
	for(my $outer = 0; $outer < scalar(@{$numArrayRef}); $outer++){
		for(my $inner = 0; $inner < scalar(@{$numArrayRef}) - $limiter; $inner++){
			if(${$numArrayRef}[$inner] > ${$numArrayRef}[$inner+1]){
				my $buffer = ${$numArrayRef}[$inner];
				${$numArrayRef}[$inner] = ${$numArrayRef}[$inner+1];
				${$numArrayRef}[$inner+1] = $buffer;
				$buffer = ${$secondArrayRef}[$inner];
				${$secondArrayRef}[$inner] = ${$secondArrayRef}[$inner+1];
				${$secondArrayRef}[$inner+1] = $buffer;
			}
		}
		$limiter++;
	}
}

return 1;
