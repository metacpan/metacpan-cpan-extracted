package Database::test5;

use strict;
use warnings;

use Database::Abstraction;

our @ISA = ('Database::Abstraction');

sub new
{
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	return $class->SUPER::new(id => 'ID', sep_char => ',', %args);
}

1;
1;
