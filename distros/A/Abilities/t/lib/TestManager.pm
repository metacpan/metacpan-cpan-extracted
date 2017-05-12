package TestManager;

use warnings;
use strict;

sub new { bless {}, shift }

sub add_objects {
	my $self = shift;

	foreach (@_) {
		$self->{$_->name} = $_;
	}

	return $self;
}

1;
