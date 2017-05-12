use strict;
use warnings;

use Test::Most tests => 9;

use_ok 'App::Mimosa::Schema::BCS';

my $schema = App::Mimosa::Schema::BCS->connect( "dbi:SQLite::memory:");

isa_ok $schema, 'DBIx::Class::Schema', 'schema object';

$schema->deploy;
ok 1, 'deploy did not die';

isa_ok $schema->resultset('Mimosa::SequenceSet'), 'DBIx::Class::ResultSet', 'we have a Mimosa::SequenceSet resultset';

is $schema->resultset('Mimosa::SequenceSet')->count, 0,
'no rows in the sequenceset table right now';

is $schema->resultset('Mimosa::SequenceSet')->search_related('sequence_set_organisms')->count, 0,
'SequenceSet has sequence_set_organisms rel';

is $schema->resultset('Mimosa::SequenceSetOrganism')->count, 0,
'no rows in the sequenceset_organism table right now';

is $schema->resultset('Organism')->search_related('mimosa_sequence_sets')->count, 0,
'organism has mimosa_sequence_sets rel';

is $schema->resultset('Mimosa::Job')->count, 0, 'no jobs by default';
