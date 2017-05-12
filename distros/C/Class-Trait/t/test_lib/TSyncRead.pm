
package TSyncRead;

use strict;
use warnings;

use Fcntl qw(:flock);

use Class::Trait 'base';

our @REQUIRES = ("read");

sub read {
	my ($self) = @_;
	$self->lock();
	my $value = $self->SUPER::read();
	$self->unlock();
	return $value;
}

sub lock { }
sub unlock { }

1;

__DATA__