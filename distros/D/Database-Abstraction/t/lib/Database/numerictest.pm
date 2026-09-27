package Database::numerictest;

use strict;
use warnings;

use Database::Abstraction;

our @ISA = ('Database::Abstraction');

sub new {
	my ($class, %args) = (shift, ref($_[0]) eq 'HASH' ? %{$_[0]} : @_);
	return $class->SUPER::new(sep_char => '!', %args);
}

1;
