use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::DDL;

# karr k121 (P12): a policy can be declared RESTRICTIVE, and two sources
# cannot declare one view.
#
# WHY it exists:
#
#  * CREATE POLICY ... AS RESTRICTIVE was something the diff could write (it
#    reads the kind off the database) and the install could not: pg_rls had
#    no key for it, so every declared policy came out permissive. A
#    restrictive policy narrows what the permissive ones let through, so a
#    schema that wanted one got the opposite on a fresh install.
#  * Two result classes that declare the same view -- the same relation name
#    -- were not an error: the first by source name won, silently, even when
#    it had no definition at all and the other one had. The view that was
#    created was not the one that was declared last, nor the one that had a
#    definition, and nothing said so.

my $n = 0;
sub table_class {
  my ($name, %more) = @_;
  my $class = 'T167::Result::T' . ++$n;
  eval qq{
    package $class;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('$name');
    1;
  } or die $@;
  $class->add_columns(id => { data_type => 'integer', is_nullable => 0 });
  $class->set_primary_key('id');
  $class->pg_rls($more{rls}) if $more{rls};
  return $class;
}
sub view_class {
  my ($name, $definition) = @_;
  my $class = 'T167::Result::V' . ++$n;
  eval qq{
    package $class;
    use base 'DBIO::Core';
    __PACKAGE__->table_class('DBIO::ResultSource::View');
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('$name');
    1;
  } or die $@;
  $class->add_columns(id => { data_type => 'integer', is_nullable => 1 });
  $class->result_source_instance->view_definition($definition) if defined $definition;
  return $class;
}
sub schema_class {
  my (%results) = @_;
  my $class = 'T167::Schema' . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Schema');
  $class->load_components('PostgreSQL');
  $class->register_class($_ => $results{$_}) for sort keys %results;
  return $class;
}
sub ddl { DBIO::PostgreSQL::DDL->install_ddl($_[0]) }
sub policies { my ($sql) = @_; return [ $sql =~ /^(CREATE POLICY [^\n]*;)$/mg ] }

# ---------------------------------------------------------------------------
# 1. restrictive => 1
# ---------------------------------------------------------------------------
{
  my $item = table_class('item', rls => {
    enable   => 1,
    policies => {
      p_open  => { using => 'true' },
      p_tight => { restrictive => 1, for => 'SELECT', roles => ['app_reader'], using => 'id > 0' },
      p_zero  => { restrictive => 0, using => 'true' },
      p_with  => { restrictive => 1, for => 'INSERT', with_check => 'id > 0' },
    },
  });
  my $sql = ddl(schema_class(Item => $item));
  note $sql;
  is_deeply(policies($sql), [
    'CREATE POLICY p_open ON item USING (true);',
    'CREATE POLICY p_tight ON item AS RESTRICTIVE FOR SELECT TO app_reader USING (id > 0);',
    'CREATE POLICY p_with ON item AS RESTRICTIVE FOR INSERT WITH CHECK (id > 0);',
    'CREATE POLICY p_zero ON item USING (true);',
  ], 'restrictive => 1 writes AS RESTRICTIVE, ahead of FOR; absent and 0 stay permissive')
    or diag $sql;
}

# ---------------------------------------------------------------------------
# 2. Two sources, one view
# ---------------------------------------------------------------------------
{
  my $base = table_class('base');
  my $first  = view_class(shared_v => undef);
  my $second = view_class(shared_v => 'SELECT id FROM base');
  my $schema = schema_class(Base => $base, AFirst => $first, BSecond => $second);
  my $err;
  ok(!eval { ddl($schema); 1 }, 'two sources declaring one view: no script') or diag ddl($schema);
  $err = $@;
  like($err, qr/refusing to write the install DDL: /, '... refused like the other declarations');
  like($err, qr/\bshared_v\b/, '... naming the view');
  like($err, qr/\bAFirst\b.*\bBSecond\b/s, '... and both sources, in source-name order');
  like($err, qr/\Q$first\E.*\Q$second\E/s, '... and their result classes');

  # Both with a definition, and the same definition: still two declarations.
  my $schema2 = schema_class(
    Base => $base,
    One  => view_class(same_v => 'SELECT id FROM base'),
    Two  => view_class(same_v => 'SELECT id FROM base'),
  );
  throws_ok { ddl($schema2) } qr/refusing to write the install DDL: .*\bsame_v\b.*\bOne\b.*\bTwo\b/s,
    'the same view with the same definition twice is refused as well';

  # Another schema (pg_schema) is another view.
  my $v_a = view_class(by_ns => 'SELECT id FROM base');
  my $v_b = view_class(by_ns => 'SELECT id FROM base');
  $v_a->pg_schema('a');
  $v_b->pg_schema('b');
  lives_ok { ddl(schema_class(Base => $base, A => $v_a, B => $v_b)) }
    'the same view name in two PostgreSQL schemas is two views';

  # One declaration is what it was.
  my $ok = ddl(schema_class(Base => $base, V => view_class(one_v => 'SELECT id FROM base')));
  like($ok, qr/^CREATE VIEW one_v AS SELECT id FROM base;$/m, 'a view declared once is written');
}

done_testing;
