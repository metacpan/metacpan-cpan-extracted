use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::Diff::Index;

# karr k146: an index on a partitioned table.
#
# pg_get_indexdef writes it CREATE INDEX name ON ONLY s.p USING ..., and an
# index made from that text is invalid until every partition has an index
# attached to it. So the diff writes, besides the text: a CREATE INDEX at each
# partition (named by the rule of the server for an index it names itself) and
# ALTER INDEX ... ATTACH PARTITION, a partition that is itself partitioned
# getting ON ONLY and its own partitions first.
#
# Without a server; t/180-diff-index-partitioned-live.t has it measured.

my $SRC_TABLES = {
  'public.p'   => { schema_name => 'public', table_name => 'p',   kind => 'p', partition_of => undef },
  'public.p1'  => { schema_name => 'public', table_name => 'p1',  kind => 'r', partition_of => 'public.p' },
  'public.p2'  => { schema_name => 'public', table_name => 'p2',  kind => 'p', partition_of => 'public.p' },
  'public.p2a' => { schema_name => 'public', table_name => 'p2a', kind => 'r', partition_of => 'public.p2' },
  'public.q'   => { schema_name => 'public', table_name => 'q',   kind => 'r', partition_of => undef },
};

sub entry {
  my ($table, $name, $columns, $def_columns, %more) = @_;
  return ($name => {
    index_name => $name, access_method => 'btree', is_unique => 0, is_primary => 0, is_valid => 1,
    definition => "CREATE INDEX $name ON " . ($table eq 'q' ? '' : 'ONLY ') . "public.$table USING btree ($def_columns)",
    predicate => undef, expressions => undef,
    columns => $columns, include_columns => [], storage_params => {},
    opclasses => {}, sort_options => {},
    constraint_name => undef, constraint_type => undef, referenced_by => [],
    %more,
  });
}

sub model { my $table = shift; return { "public.$table" => { map { @$_ } @_ } } }

sub create_sql {
  my ($source, $target, $src_tables) = @_;
  my @ops = DBIO::PostgreSQL::Diff::Index->diff($source, $target, $src_tables // $SRC_TABLES, $src_tables // $SRC_TABLES);
  return [ map { split /\n/, $_->as_sql } @ops ];
}

# 1. The index of a partitioned table: the text, then the partitions.
{
  my $sql = create_sql({}, model(p => [ entry(p => 'p_tag', ['tag'], 'tag') ]),
    { %$SRC_TABLES, 'other.p3' => { schema_name => 'other', table_name => 'p3', kind => 'r', partition_of => 'public.p' } });
  is_deeply($sql, [
    'CREATE INDEX p_tag ON ONLY public.p USING btree (tag);',
    'CREATE INDEX p3_tag_idx ON other.p3 USING btree (tag);',
    'ALTER INDEX public.p_tag ATTACH PARTITION other.p3_tag_idx;',
    'CREATE INDEX p1_tag_idx ON public.p1 USING btree (tag);',
    'ALTER INDEX public.p_tag ATTACH PARTITION public.p1_tag_idx;',
    'CREATE INDEX p2_tag_idx ON ONLY public.p2 USING btree (tag);',
    'CREATE INDEX p2a_tag_idx ON public.p2a USING btree (tag);',
    'ALTER INDEX public.p2_tag_idx ATTACH PARTITION public.p2a_tag_idx;',
    'ALTER INDEX public.p_tag ATTACH PARTITION public.p2_tag_idx;',
  ], 'a partitioned table: ON ONLY, every partition has an index, attached; deeper levels first')
    or diag explain $sql;
}

# 2. A plain table is written as the text, nothing more.
{
  my $sql = create_sql({}, model(q => [ entry(q => 'q_tag', ['tag'], 'tag') ]));
  is_deeply($sql, ['CREATE INDEX q_tag ON public.q USING btree (tag);'], 'a plain table: the text alone');
}

# 3. Unique, partial, expression, several columns, quoted names: the text of
#    the parent carries over; the name follows the rule of the server.
{
  my $tables = { %$SRC_TABLES, 'public.p1' => { %{ $SRC_TABLES->{'public.p1'} }, table_name => 'P 1' } };
  my $parent = { entry(p => 'p_u', ['a', 'b'], 'a, b DESC', is_unique => 1) };
  $parent->{p_u}{definition} = 'CREATE UNIQUE INDEX p_u ON ONLY public.p USING btree (a, b DESC) INCLUDE (c) WHERE (a > 0)';
  my $sql = create_sql({}, model(p => [ %$parent ]), $tables);
  is($sql->[1], 'CREATE UNIQUE INDEX "P 1_a_b_idx" ON public."P 1" USING btree (a, b DESC) INCLUDE (c) WHERE (a > 0);',
    'unique, include, partial, quoted partition name');
  is($sql->[2], 'ALTER INDEX public.p_u ATTACH PARTITION public."P 1_a_b_idx";', '... attached');

  my $expr = { entry(p => 'p_e', [undef], 'lower(name)') };
  $sql = create_sql({}, model(p => [ %$expr ]));
  is($sql->[1], 'CREATE INDEX p1_expr_idx ON public.p1 USING btree (lower(name));', 'an expression key is "expr" in the name');
}

# 4. A name the schema holds already gets the number the server would add.
{
  my $source = { "public.p1" => { p1_tag_idx => { entry(p1 => "p1_tag_idx", ["tag"], "tag") }->{p1_tag_idx} } };
  my $sql = create_sql($source, model(p => [ entry(p => "p_tag", ["tag"], "tag") ]));
  like(join("\n", @$sql), qr/CREATE INDEX p1_tag_idx1 ON public\.p1 /, "a taken name: numbered");
}

# 5. A name beyond 63 bytes is shortened the way the server does.
{
  my $long = 'x' x 70;
  my $tables = { %$SRC_TABLES, 'public.p1' => { %{ $SRC_TABLES->{'public.p1'} }, table_name => $long } };
  my $sql = create_sql({}, model(p => [ entry(p => 'p_tag', ['tag'], 'tag') ]), $tables);
  my ($name) = $sql->[1] =~ /\ACREATE INDEX (\S+) ON /;
  is(length $name, 63, 'a long name is cut to 63 bytes');
  like($name, qr/_tag_idx\z/, '... the suffix stays');
}

# 6. A changed index is dropped and created, the copies at the partitions go
#    with the drop (no statement of theirs).
{
  my $old = model(p => [ entry(p => 'p_tag', ['tag'], 'tag') ]);
  my $new = model(p => [ entry(p => 'p_tag', ['tag', 'b'], 'tag, b') ]);
  my $sql = create_sql($old, $new);
  is($sql->[0], 'DROP INDEX public.p_tag;', 'changed: the drop');
  is($sql->[1], 'CREATE INDEX p_tag ON ONLY public.p USING btree (tag, b);', '... the create');
  like($sql->[2], qr/\ACREATE INDEX p1_tag_b_idx ON public\.p1 /, '... partitions follow');
}

# 7. An index both models have is compared as before: nothing.
is_deeply(create_sql(model(p => [ entry(p => 'p_tag', ['tag'], 'tag') ]), model(p => [ entry(p => 'p_tag', ['tag'], 'tag') ])), [],
  'the same index on both sides: no operation');

# 8. A partition the target drops gets no index.
{
  my $sql;
  my @ops = DBIO::PostgreSQL::Diff::Index->diff({}, model(p => [ entry(p => 'p_tag', ['tag'], 'tag') ]),
    $SRC_TABLES, { 'public.p' => $SRC_TABLES->{'public.p'}, 'public.p1' => $SRC_TABLES->{'public.p1'} });
  $sql = [ map { split /\n/, $_->as_sql } @ops ];
  unlike(join("\n", @$sql), qr/p2|p3/, 'a partition the target no longer has gets no index');
}

done_testing;
