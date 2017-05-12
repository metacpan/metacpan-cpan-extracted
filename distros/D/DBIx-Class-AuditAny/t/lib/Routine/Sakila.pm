package # hide from PAUSE
     Routine::Sakila;
use strict;
use warnings;

use Test::Routine;
with 'Routine::Base';

use Test::More; 
use namespace::autoclean;

has 'test_schema_class', is => 'ro', default => 'TestSchema::Sakila';

test 'inserts' => { desc => 'Insert Test Data' } => sub {
	my $self = shift;
	my $schema = $self->Schema;
	
	
	$schema->txn_do(sub {
		ok(
			# Remove $ret to force VOID context (needed to test Storgae::insert_bulk codepath)
			do { my $ret = $schema->resultset('Language')->populate([
				[$schema->source('Language')->columns],
				[1,'English','2006-02-15 05:02:19'],
				[2,'Italian','2006-02-15 05:02:19'],
				[3,'Japanese','2006-02-15 05:02:19'],
				[4,'Mandarin','2006-02-15 05:02:19'],
				[5,'French','2006-02-15 05:02:19'],
				[6,'German','2006-02-15 05:02:19']
			]); 1; },
			"Populate Language rows"
		);
	});
	
	ok(
		# Remove $ret to force VOID context (needed to test Storgae::insert_bulk codepath)
		do { my $ret = $schema->resultset('Film')->populate([
			[$schema->source('Film')->columns],
			[1,'ACADEMY DINOSAUR','A Epic Drama of a Feminist And a Mad Scientist who must Battle a Teacher in The Canadian Rockies',2006,1,undef,6,'0.99',86,'20.99','PG','Deleted Scenes,Behind the Scenes','2006-02-15 05:03:42'],
[2,'ACE GOLDFINGER','A Astounding Epistle of a Database Administrator And a Explorer who must Find a Car in Ancient China',2006,1,undef,3,'4.99',48,'12.99','G','Trailers,Deleted Scenes','2006-02-15 05:03:42'],
[3,'ADAPTATION HOLES','A Astounding Reflection of a Lumberjack And a Car who must Sink a Lumberjack in A Baloon Factory',2006,2,undef,7,'2.99',50,'18.99','NC-17','Trailers,Deleted Scenes','2006-02-15 05:03:42']
		]); 1; },
		"Populate some Film rows"
	);
	
	ok( 
		$schema->resultset('Actor')->create({
			#actor_id => 1,
			first_name => 'PENELOPE', 
			last_name => 'GUINESS',
			film_actors => [
				{ film_id => 1 }
			]
		}),
		"Insert an Actor row with film_actors link"
	);
	
};


test 'updates_cascades' => { desc => 'Updates causing db-side cascades' } => sub {
	my $self = shift;
	my $schema = $self->Schema;
	
	ok(
		my $English = $schema->resultset('Language')->search_rs({ 
			name => 'English'
		})->first,
		"Find 'English' Language row"
	);
	
	ok(
		$English->update({ language_id => 100 }),
		"Change the PK of the 'English' Language row (should cascade)"
	);
	
};	

1;