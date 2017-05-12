package # hide from PAUSE
     Routine::One;
use strict;
use warnings;

use Test::Routine;
with 'Routine::Base';

use Test::More; 
use namespace::autoclean;

has 'test_schema_class', is => 'ro', default => 'TestSchema::One';

test 'make_db_changes' => { desc => 'Make Database Changes' } => sub {
	my $self = shift;
	my $schema = $self->Schema;
	ok( 
		$schema->resultset('Contact')->create({
			first => 'John', 
			last => 'Smith' 
		}),
		"Insert a test row"
	);

	ok(
		my $Row = $schema->resultset('Contact')->search_rs({ last => 'Smith' })->first,
		"Find the test row"
	);

	ok(
		$Row->update({ last => 'Doe' }),
		"Update the test row"
	);

	ok(
		$Row->delete,
		"Delete the test row"
	);
};

1;