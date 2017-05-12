#
# This file is part of DBIx-Class-Graph
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package 
  TestLib;
use strict;
use warnings;
use TestLib::Schema;

sub new {
	my $self = shift;
	my $schema = TestLib::Schema->connect("dbi:SQLite::memory:");
	$schema->deploy;
	my $t = $schema->populate(
		"Simple",
		[
			[qw(title vaterid id)],
			[ "root",     0, 1 ],
			[ "child",    1, 2 ],
			[ "child",    1, 3 ],
			[ "child",    1, 4 ],
			[ "subchild", 3, 5 ],
			[ "subchild", 3, 6 ]    
		]
	);
	
	$t = $schema->populate(
		"SimpleSucc",
		[
			[qw(title childid id)],
			[ "root",     3, 1 ],
			[ "root",     3, 2 ],
			[ "child",    5, 3 ],
			[ "root",    5, 4 ],
			[ "subchild", 0, 5 ],
			[ "subchild", 0, 6 ]    
		]
	);	
	$t = $schema->populate(
		"Complex",
		[
			[qw(title id_foo)],
			[ "root",     1 ],
			[ "root",     2 ],
			[ "child",    3 ],
			[ "root",    4 ],
			[ "subchild", 5 ],
			[ "subchild", 6 ]    
		]
	);	
	$t = $schema->populate(
		"ComplexMap",
		[
			[qw(parent child id)],
			[ 0, 1, 1 ],
			[ 1, 2, 2 ],
			[ 1, 3, 3 ],
			[ 1, 4, 4 ],
			[ 3, 5, 5 ],
			[ 2, 5, 6 ],
			[ 3, 6, 7 ]    
		]
	);
	return bless( { schema => $schema }, $self );
}

sub get_schema {
	my $self = shift;
	return $self->{schema};
}
1;
