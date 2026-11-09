use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::ResultSet ();

# karr k61 -- resultset_class promotion and value inflation must share ONE
# pgvector-type detection site. The two used to carry independent regexes with
# different whitespace tolerance: InflateColumn::Vector's helper allowed edge
# spaces (\A\s*...\s*\z), the inline regex in DBIO::PostgreSQL::Result did not.
#
# The visible bug: a column declared with edge spaces (' vector(3) ') was
# inflated/deflated (the helper matched) but NOT promoted (the inline regex did
# not), so nearest_neighbors silently went missing -- yet ADR 0006 says
# declaring the column is the whole opt-in. This test pins that a padded
# declaration promotes; without the fix (register_column calling the shared
# _pgvector_type_info helper) it is red.

{
  package WS::Result::Padded;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('padded');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    embedding => { data_type => ' vector(3) ' },   # edge whitespace
  );
  __PACKAGE__->set_primary_key('id');
}

is(
  WS::Result::Padded->result_source_instance->resultset_class,
  'DBIO::PostgreSQL::ResultSet',
  "a pgvector data_type with edge whitespace (' vector(3) ') promotes resultset_class",
);

# The same tolerance must hold for the dimensionless and other pgvector spellings.
{
  package WS::Result::PaddedHalf;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('padded_half');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    half => { data_type => "  halfvec  " },        # padded, dimensionless
  );
  __PACKAGE__->set_primary_key('id');
}

is(
  WS::Result::PaddedHalf->result_source_instance->resultset_class,
  'DBIO::PostgreSQL::ResultSet',
  'a padded dimensionless halfvec promotes too',
);

# And a non-pgvector type still must not promote, padded or not.
{
  package WS::Result::NotVector;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('not_vector');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer' },
    indexed => { data_type => ' tsvector ' },       # full-text, not pgvector
  );
  __PACKAGE__->set_primary_key('id');
}

is(
  WS::Result::NotVector->result_source_instance->resultset_class,
  'DBIO::ResultSet',
  'a padded tsvector is still not a pgvector type -- no promotion',
);

done_testing;
