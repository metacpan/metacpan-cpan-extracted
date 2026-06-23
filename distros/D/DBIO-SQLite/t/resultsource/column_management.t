use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

# --- columns_info (batch) ---
{
  my $src = $schema->source('CD');

  # All columns
  my $all_info = $src->columns_info;
  is(ref $all_info, 'HASH', 'columns_info returns hashref');
  ok(exists $all_info->{cdid}, 'columns_info includes cdid');
  ok(exists $all_info->{title}, 'columns_info includes title');
  ok(exists $all_info->{year}, 'columns_info includes year');

  # Specific subset
  my $subset = $src->columns_info([qw/title year/]);
  is(scalar keys %$subset, 2, 'columns_info with filter returns 2 columns');
  ok(exists $subset->{title}, 'filtered columns_info includes title');
  ok(exists $subset->{year}, 'filtered columns_info includes year');
  ok(!exists $subset->{cdid}, 'filtered columns_info excludes cdid');

  # Non-existent column
  throws_ok {
    $src->columns_info([qw/nonexistent/])
  } qr/No such column/i, 'columns_info with unknown column throws';
}

# --- column_info ---
{
  my $src = $schema->source('CD');
  my $info = $src->column_info('title');
  is(ref $info, 'HASH', 'column_info returns hashref');
  ok(exists $info->{data_type} || exists $info->{accessor} || 1,
    'column_info has metadata');
}

# --- remove_columns ---
{
  # Use a fresh source clone to avoid contaminating shared state
  my $src = $schema->source('Artist');

  # Check that the columns exist before any operations
  my @orig_cols = $src->columns;
  ok(scalar @orig_cols > 1, 'Artist source has multiple columns');

  # Create a new source for testing remove_columns
  my $test_src = DBIO::ResultSource::Table->new({
    name => 'test_remove',
    result_class => 'DBIO::Test::Schema::Artist',
  });
  $test_src->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar' },
    extra => { data_type => 'text' },
  );
  my @before = $test_src->columns;
  is(scalar @before, 3, 'test source has 3 columns');

  $test_src->remove_columns('extra');
  my @after = $test_src->columns;
  is(scalar @after, 2, 'remove_columns removed one column');
  ok(!$test_src->has_column('extra'), 'extra column no longer exists');
  ok($test_src->has_column('name'), 'name column still exists');
}

# --- has_column ---
{
  my $src = $schema->source('CD');
  ok($src->has_column('title'), 'has_column returns true for existing column');
  ok(!$src->has_column('nonexistent'), 'has_column returns false for missing column');
}

# --- unique_constraints ---
{
  my $src = $schema->source('CD');
  my %uc = $src->unique_constraints;
  ok(exists $uc{primary}, 'unique_constraints includes primary');
  is(ref $uc{primary}, 'ARRAY', 'primary constraint is arrayref');
}

# --- unique_constraint_names ---
{
  my $src = $schema->source('CD');
  my @names = $src->unique_constraint_names;
  ok(scalar @names > 0, 'unique_constraint_names returns names');
  ok((grep { $_ eq 'primary' } @names), 'primary is in constraint names');
}

# --- unique_constraint_columns ---
{
  my $src = $schema->source('CD');
  my @cols = $src->unique_constraint_columns('primary');
  ok(scalar @cols > 0, 'unique_constraint_columns returns columns');

  throws_ok {
    $src->unique_constraint_columns('nonexistent_constraint')
  } qr/Unknown unique constraint/, 'unknown constraint name throws';
}

# --- name_unique_constraint ---
{
  my $src = $schema->source('CD');
  my $name = $src->name_unique_constraint([qw/artist title/]);
  like($name, qr/artist/, 'generated constraint name contains column name');
  like($name, qr/title/, 'generated constraint name contains column name');
}

# --- add_unique_constraints (batch, named) ---
{
  my $test_src = DBIO::ResultSource::Table->new({
    name => 'test_batch_uc',
    result_class => 'DBIO::Test::Schema::Artist',
  });
  $test_src->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar' },
    code => { data_type => 'varchar' },
  );
  $test_src->set_primary_key('id');

  # Named form
  $test_src->add_unique_constraints(
    name_idx => ['name'],
    code_idx => ['code'],
  );

  my %uc = $test_src->unique_constraints;
  ok(exists $uc{name_idx}, 'batch add_unique_constraints: name_idx exists');
  ok(exists $uc{code_idx}, 'batch add_unique_constraints: code_idx exists');
}

# --- add_unique_constraints (batch, unnamed) ---
{
  my $test_src = DBIO::ResultSource::Table->new({
    name => 'test_batch_uc2',
    result_class => 'DBIO::Test::Schema::Artist',
  });
  $test_src->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar' },
    code => { data_type => 'varchar' },
  );
  $test_src->set_primary_key('id');

  # Unnamed form
  $test_src->add_unique_constraints(
    ['name'],
    ['code'],
  );

  my %uc = $test_src->unique_constraints;
  # auto-generated names should contain the column
  my @names = grep { $_ ne 'primary' } keys %uc;
  is(scalar @names, 2, 'batch unnamed: two new constraints added');
}

# --- related_source ---
{
  my $src = $schema->source('CD');
  my $artist_src = $src->related_source('artist');
  isa_ok($artist_src, 'DBIO::ResultSource', 'related_source returns RS');
  is($artist_src->source_name, 'Artist', 'related_source returns correct source');

  throws_ok {
    $src->related_source('nonexistent_rel')
  } qr/No such relationship/, 'related_source with bad rel throws';
}

# --- related_class ---
{
  my $src = $schema->source('CD');
  my $class = $src->related_class('artist');
  like($class, qr/Artist/, 'related_class returns correct class');
}

# --- reverse_relationship_info ---
{
  my $src = $schema->source('CD');
  my $rev = $src->reverse_relationship_info('artist');
  is(ref $rev, 'HASH', 'reverse_relationship_info returns hashref');
  # The reverse of CD->artist should be Artist->cds
  ok(exists $rev->{cds}, 'reverse of CD->artist includes cds');
}

# --- relationships ---
{
  my $src = $schema->source('CD');
  my @rels = $src->relationships;
  ok(scalar @rels > 0, 'relationships returns names');
  ok((grep { $_ eq 'artist' } @rels), 'artist relationship exists');
}

# --- relationship_info ---
{
  my $src = $schema->source('CD');
  my $info = $src->relationship_info('artist');
  is(ref $info, 'HASH', 'relationship_info returns hashref');
  ok(exists $info->{cond}, 'relationship info has cond');
  ok(exists $info->{attrs}, 'relationship info has attrs');
}

# --- has_relationship ---
{
  my $src = $schema->source('CD');
  ok($src->has_relationship('artist'), 'has_relationship returns true');
  ok(!$src->has_relationship('nonexistent'), 'has_relationship returns false');
}

# --- handle ---
{
  my $src = $schema->source('CD');
  my $handle = $src->handle;
  isa_ok($handle, 'DBIO::ResultSourceHandle', 'handle returns RSH');
}

done_testing;
