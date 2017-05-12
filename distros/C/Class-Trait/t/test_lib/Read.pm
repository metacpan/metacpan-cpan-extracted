package Read;

use strict;
use warnings;

sub new {
	my ($_class) = @_;
	my $class = ref($_class) || $_class;
	my $reader = {};
	bless($reader, $class);
	return $reader;
}

sub read {
	my ($self) = @_;
	return "value read from Read::read method";
}

1;

__DATA__
