package # hide from PAUSE
     Routine::Base;
use strict;
use warnings;

use Test::Routine;

# This is the *base* routine for initializing a test database
# It is intended to be composed under additional Routines for
# attaching auditors, running a script of changes and then
# interrogating those changes in the collector


use Test::More; 
use namespace::autoclean;

use SQL::Translator 0.11016;
use Module::Runtime;

has 'test_schema_class', is => 'ro', isa => 'Str', required => 1;

has 'test_schema_dsn', is => 'ro', isa => 'Str', default => sub{'dbi:SQLite::memory:'};
has 'test_schema_connect', is => 'ro', isa => 'ArrayRef', lazy => 1, default => sub {
	return [ (shift)->test_schema_dsn, '', '', {
		AutoCommit			=> 1,
		on_connect_call	=> 'use_foreign_keys'
	}];
};

sub new_test_schema {
	my $self = shift;
	my $class = shift;
	Module::Runtime::require_module($class);
	my $s = $class->connect(@{$self->test_schema_connect});
	$s->deploy();
	return $s;
}


has 'Schema' => (
	is => 'ro', isa => 'Object', lazy => 1, 
	clearer => 'reset_Schema',
	builder => 'build_Schema'
);


sub build_Schema {
	my $self = shift;
	ok(
		my $schema = $self->new_test_schema($self->test_schema_class),
		"Initialize Test Database"
	);
	return $schema;
}



1;