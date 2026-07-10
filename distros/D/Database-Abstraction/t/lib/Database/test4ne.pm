package Database::test4ne;

# no_entry CSV using test4.csv, keyed by 'cardinal' column.
# Used by extended_tests.t to cover the CSV no_entry slurp paths.

use strict;
use warnings;

use Database::Abstraction;

our @ISA = ('Database::Abstraction');

sub new
{
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	return $class->SUPER::new(no_entry => 1, id => 'cardinal', sep_char => ',', dbname => 'test4', %args);
}

1;
