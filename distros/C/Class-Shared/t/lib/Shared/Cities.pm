package Shared::Cities;

# A real-world target class: a read-only table of cities held by
# Database::Abstraction.  It is only loaded by a test that has checked that
# Database::Abstraction is installed, so it is not a dependency of this
# distribution.
#
# Database::Abstraction looks for a file named after the last part of the class
# (Cities.csv) in the directory it is given.

use strict;
use warnings;

use parent 'Database::Abstraction';

# Its default field separator is "!", so ask for a plain CSV.
#
# max_slurp_size => 0 makes every query go through SQL.  Database::Abstraction
# 0.57 can crash perl (a segmentation fault or an abort, depending on the size
# of the file) in the path that holds a small file in memory, so this keeps the
# test steady; it is nothing to do with Class::Shared, and the crash happens in
# an ordinary process with no backend.
sub new {
	my ($class, %args) = @_;

	return $class->SUPER::new(sep_char => ',', max_slurp_size => 0, %args);
}

# Purpose:       the cities with more than $minimum people, largest first.
# Why a method:  query() returns a builder object, and an object cannot be held
#                by a client of a shared backend: each call would return a
#                copy, and the chain could not be continued.  Running the whole
#                chain here, in the backend, returns only plain rows.
sub larger_than {
	my ($self, $minimum) = @_;

	return $self->query
		->where(population => { '>' => $minimum })
		->order_by('population DESC')
		->all;
}

1;
