use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Deploy;

# karr k120 (2, 3) -- the install script is a script: every piece of it is a
# statement the server takes, in an order that can be run, and the deploy
# runs every one of them.
#
# WHY it exists: the end of the script -- the foreign keys from belongs_to,
# the settings, the search_path, the views -- had never met a server or the
# way L<DBIO::Deploy::Base> runs it. That way was, then: cut the script at
# every semicolon and leave out a piece that begins with "--".
#
#   -- skipped FK for rel customer: non-column condition     <- no semicolon:
#   ALTER TABLE b ADD CONSTRAINT ... FOREIGN KEY ...;        <- one piece with it, left out
#   ALTER DATABASE CURRENT SET app.x = 'y';                  <- database "current" does not exist
#   SET search_path TO app, public;
#   CREATE VIEW a_top AS SELECT id FROM z_base;              <- lands in app; z_base does not exist yet
#   CREATE VIEW z_base AS SELECT id FROM item;
#
# Since core k326 the deploy reads the script as SQL: a comment ahead of a
# statement is taken off it, a piece that is only a comment is no statement,
# and a semicolon in a comment ends nothing -- so there
#
#   CREATE INDEX i ON t (a) -- a note;                       <- the semicolon is the comment's:
#   CREATE INDEX j ON t (b);                                 <- one statement with the line above
#
# is one statement, which the server refuses. The script has to be right
# under both readings, and what the deploy does with it is asked of the
# deploy: run_by_deploy below hands the script to its own _execute_ddl and
# takes down what that passes to the database handle.
#
# What is held here, without a database (t/102-...-live.t holds each against
# a server):
#
#  1. a note in the script takes nothing with it: the deploy runs every
#     statement of the script, each as a statement of its own, and no note --
#     while the note is still there to be read;
#  2. a setting is a statement that needs no database name, one statement
#     for the deploy whatever its value holds, the value a literal;
#  3. the views stand behind the tables and the foreign keys and ahead of the
#     settings (the script no longer ends with SET search_path, karr k121), each behind the views its
#     deploy_depends_on names -- and a circle of those is refused, naming the
#     views;
#  4. the semicolon that ends a statement ends it: it does not stand in a
#     comment the declared SQL closes with -- not for a reader of the whole
#     script, and not for the deploy.

# A database handle that runs nothing and takes down what it is given.
{
  package T102::Handle;
  sub new { return bless { done => [] }, $_[0] }
  sub do  { push @{ $_[0]{done} }, $_[1]; return 1 }
}

# The statements the deploy runs of a script, in its order: what
# DBIO::PostgreSQL::Deploy's own _execute_ddl hands to $dbh->do. The schema
# behind it has a PostgreSQL storage and no connection -- its connect dies,
# so the handle is not the storage's and the statements are run on it bare.
{
  package T102::Unconnected;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
my $DEPLOY = DBIO::PostgreSQL::Deploy->new(
  schema => T102::Unconnected->connect(sub { die "an offline test has no server\n" }),
);
sub run_by_deploy {
  my ($sql) = @_;
  my $handle = T102::Handle->new;
  $DEPLOY->_execute_ddl($handle, $sql);
  return @{ $handle->{done} };
}

my $n = 0;
sub table_class {
  my ($name, %more) = @_;
  my $class = 'T102::Result::T' . ++$n;
  eval qq{
    package $class;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('$name');
    1;
  } or die $@;
  $class->add_columns(
    id => { data_type => 'integer', is_nullable => 0 },
    a  => { data_type => 'integer', is_nullable => 1 },
    %{ $more{columns} // {} },
  );
  $class->set_primary_key('id');
  return $class;
}
sub view_class {
  my ($name, $definition, @depends_on) = @_;
  my $class = 'T102::Result::V' . ++$n;
  eval qq{
    package $class;
    use base 'DBIO::Core';
    __PACKAGE__->table_class('DBIO::ResultSource::View');
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('$name');
    1;
  } or die $@;
  $class->add_columns(id => { data_type => 'integer', is_nullable => 1 });
  $class->result_source_instance->view_definition($definition);
  $class->result_source_instance->deploy_depends_on([@depends_on]) if @depends_on;
  return $class;
}
sub schema_class {
  my (%results) = @_;
  my $class = 'T102::Schema' . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Schema');
  $class->load_components('PostgreSQL');
  $class->register_class($_ => $results{$_}) for sort keys %results;
  return $class;
}
sub ddl { DBIO::PostgreSQL::DDL->install_ddl($_[0]) }

# The position of the first statement that matches, among the statements the
# deploy runs.
sub at {
  my ($sql, $match) = @_;
  my @run = run_by_deploy($sql);
  my ($at) = grep { $run[$_] =~ $match } 0 .. $#run;
  return $at;
}

# ---------------------------------------------------------------------------
# 1. A skipped foreign key takes nothing with it -- and two it refuses
# ---------------------------------------------------------------------------
{
  my $customer = table_class('customer');
  my %fk = (columns => { customer_id => { data_type => 'integer', is_nullable => 1 } });

  # One reason to skip -- a condition that is no column equality -- with
  # something that has to run behind it. By source name: A (skipped), B (a
  # foreign key), D (a foreign key) -- and behind them the views. The other
  # two reasons the script used to note, a foreign class that is not loaded
  # and a table outside the deploy, are refused (karr k120, decision
  # 2026-10-12) and are asked below.
  my $a = table_class('a_weird', %fk);
  $a->belongs_to(customer => $customer, sub { {} });
  my $b = table_class('b_order', %fk);
  $b->belongs_to(customer => $customer, 'customer_id');
  my $d = table_class('d_order', %fk);
  $d->belongs_to(customer => $customer, 'customer_id');
  $_->pg_fk_constraints_from_rels(1) for $a, $b, $d;

  my $schema = schema_class(A => $a, B => $b, D => $d, Customer => $customer,
    V => view_class(behind_the_keys => 'SELECT id FROM customer'));
  $schema->pg_search_path(qw( app public ));
  my $sql = ddl($schema);
  note $sql;

  like($sql, qr/^-- skipped FK for rel customer: non-column condition$/m,
    'a belongs_to that is no column equality is still noted in the script');

  # Four tables, two foreign keys, the view: every
  # statement of the script, and of the note nothing -- neither as a piece
  # sent for itself nor as the head of the statement behind it.
  my @run = run_by_deploy($sql);
  is(scalar @run, 7, 'the deploy runs the seven statements of the script, with a note among them')
    or diag explain \@run;
  is_deeply([ grep { /skipped FK/ } @run ], [], 'and hands the database no note')
    or diag explain \@run;

  for my $expect (
    [ qr/\AALTER TABLE b_order ADD CONSTRAINT b_order_customer_id_fkey FOREIGN KEY /, 'the foreign key behind the note' ],
    [ qr/\AALTER TABLE d_order ADD CONSTRAINT d_order_customer_id_fkey FOREIGN KEY /, 'the foreign key behind it' ],
    [ qr/\ACREATE VIEW behind_the_keys AS /,                                         'the view behind the keys' ],
  ) {
    my ($match, $what) = @$expect;
    is(scalar(grep { $_ =~ $match } @run), 1, "$what is a statement the deploy runs");
  }

  # The two that are refused: no script at all, and the message names the
  # table, the relationship and what is missing.
  my $c = table_class('c_ghost', %fk);
  $c->belongs_to(ghost => 'T102::Result::NeverLoaded', { 'foreign.id' => 'self.customer_id' });
  my $e = table_class('e_orphan', %fk);
  $e->belongs_to(target => table_class('not_deployed'), 'customer_id');
  $_->pg_fk_constraints_from_rels(1) for $c, $e;
  my $unloaded = eval { ddl(schema_class(Customer => $customer, C => $c)) };
  like($@, qr/refusing to write the install DDL: relationship 'ghost' of c_ghost .*T102::Result::NeverLoaded, which is not loaded/,
    'a foreign class that is not loaded refuses the script, by table, relationship and class');
  ok(!defined $unloaded, '... and no script is written');
  my $outside = eval { ddl(schema_class(Customer => $customer, E => $e)) };
  like($@, qr/refusing to write the install DDL: relationship 'target' of e_orphan .*not_deployed.*not part of this schema deploy/,
    'a table outside the deploy refuses the script, by table, relationship and target');
  ok(!defined $outside, '... and no script is written');

  # A note is one line whatever the names in it hold, and has no semicolon:
  # past a line break it would be SQL for every reader, and a deploy that
  # does not read comments (core before k326) cut it at a semicolon. What a
  # note holds is a relationship name, and add_relationship takes any string.
  my $odd = table_class('odd', %fk);
  $odd->result_source_instance->add_relationship("far\naway; DROP TABLE customer", $customer, sub { {} },
    { is_depends_on => 1, accessor => 'single' });
  $odd->pg_fk_constraints_from_rels(1);
  my $odd_sql = ddl(schema_class(Customer => $customer, Odd => $odd));
  note $odd_sql;
  like($odd_sql, qr/^-- skipped FK for rel far away<semicolon> DROP TABLE customer: non-column condition$/m,
    'the relationship name is in the note, as one line without a semicolon');
  my @odd_run = run_by_deploy($odd_sql);
  is(scalar @odd_run, 2,
    'a relationship name with a line break and a semicolon in a note: the deploy runs the two tables')
    or diag explain \@odd_run;
  unlike(join("\n", @odd_run), qr/DROP TABLE|away/,
    '... and nothing of it among the statements');
  (my $odd_read = $odd_sql) =~ s/--[^\n]*//g;
  unlike($odd_read, qr/DROP TABLE|away/,
    '... nor outside the comment for whoever reads the script as one piece');
}

# ---------------------------------------------------------------------------
# 2. Settings
# ---------------------------------------------------------------------------
{
  my $schema = schema_class(Item => table_class('item'));
  my %settings = (
    'default_text_search_config' => 'pg_catalog.german',
    'app.greeting'               => q{it's; me},
    'app.tag'                    => 'a $dbio$ b $$ c',
  );
  $schema->pg_settings({%settings});
  my $sql = ddl($schema);
  note $sql;

  unlike($sql, qr/ALTER DATABASE CURRENT\b/,
    'no ALTER DATABASE CURRENT: PostgreSQL has no such statement');

  my @set = grep { /ALTER DATABASE/ } run_by_deploy($sql);
  is(scalar @set, 3, 'each setting is one statement for the deploy, whatever its value holds')
    or diag explain [ run_by_deploy($sql) ];
  for my $key (sort keys %settings) {
    my ($stmt) = grep { index($_, $key) >= 0 } @set;
    ok($stmt, "$key has its statement") or next;
    like($stmt, qr/current_database\(\)/, '... which asks the server for the database it runs in');
    (my $literal = $settings{$key}) =~ s/'/''/g;
    cmp_ok(index($stmt, "'$literal'"), '>=', 0, '... and carries the value as a literal');
  }
  unlike($sql, qr/'it's/, 'an apostrophe in a value does not end its literal');

  is(ddl($schema), $sql, 'a second call writes the same script');
  unlike(ddl(schema_class(Item => table_class('item'))), qr/ALTER DATABASE/,
    'a schema without settings gets no such statement');
}

# ---------------------------------------------------------------------------
# 3. Views: where they stand, and in which order
# ---------------------------------------------------------------------------
{
  my $customer = table_class('customer');
  my $order = table_class('an_order', columns => { customer_id => { data_type => 'integer', is_nullable => 1 } });
  $order->belongs_to(customer => $customer, 'customer_id');
  $order->pg_fk_constraints_from_rels(1);

  # By source name the view that reads comes first (ATop, ZBase), and by its
  # own name as well (a_top, z_base).
  my $base = view_class(z_base => 'SELECT id FROM customer');
  my $top  = view_class(a_top  => 'SELECT id FROM z_base', $base);
  my $schema = schema_class(ATop => $top, ZBase => $base, Customer => $customer, Order => $order);
  $schema->pg_search_path(qw( app public ));
  $schema->pg_settings({ 'app.x' => 'y' });
  my $sql = ddl($schema);
  note $sql;

  my %at = (
    table  => at($sql, qr/\ACREATE TABLE an_order /),
    key    => at($sql, qr/\AALTER TABLE an_order ADD CONSTRAINT /),
    base   => at($sql, qr/\ACREATE VIEW z_base /),
    top    => at($sql, qr/\ACREATE VIEW a_top /),
    set    => at($sql, qr/ALTER DATABASE/),
  );
  is(scalar(grep { defined } values %at), 5, 'the script has all of them') or diag explain \%at;
  for my $order (
    [ table => 'base', 'the views stand behind the tables' ],
    [ key   => 'base', '... and behind the foreign keys' ],
    [ base  => 'top',  'a view stands behind the view its deploy_depends_on names, against the order of the names' ],
    [ top   => 'set',  'the views stand ahead of the settings' ],
  ) {
    my ($first, $then, $why) = @$order;
    cmp_ok($at{$first} // 99, '<', $at{$then} // -1, $why);
  }
  is(at($sql, qr/\ASET search_path /), undef,
    'the script holds no SET search_path, whatever pg_search_path declares (karr k121)');
  is(at($sql, qr/ALTER DATABASE/), scalar(() = run_by_deploy($sql)) - 1,
    'the last statement is the last setting');
}

sub view_order { [ ddl($_[0]) =~ /^CREATE VIEW (\S+)/mg ] }

{
  my $item = table_class('item');

  # Without a declaration the order is the one of the source names, as before.
  is_deeply(
    view_order(schema_class(Item => $item,
      B => view_class(v_one => 'SELECT 1 AS id'), A => view_class(v_two => 'SELECT 2 AS id'))),
    [qw( v_two v_one )], 'views that name no other view come in the order of their source names');

  # A chain, declared against the names; a view two others read.
  my $c = view_class(v_c => 'SELECT id FROM item');
  my $b = view_class(v_b => 'SELECT id FROM v_c', $c);
  my $a = view_class(v_a => 'SELECT id FROM v_b', $b);
  my $d = view_class(v_d => 'SELECT id FROM v_c UNION SELECT id FROM v_a', $c, $a);
  is_deeply(view_order(schema_class(Item => $item, A => $a, B => $b, C => $c, D => $d)),
    [qw( v_c v_b v_a v_d )], 'a chain of three and a view on two of them: each behind all it names');

  # deploy_depends_on set on the source of the connected schema is an
  # arrayref; set on the class before it is registered it has become a hash.
  my $late_base = view_class(z_late => 'SELECT id FROM item');
  my $late_top  = view_class(a_late => 'SELECT id FROM z_late');
  my $late = schema_class(Item => $item, ATop => $late_top, ZBase => $late_base);
  $late->source('ATop')->deploy_depends_on([$late_base]);
  is(ref $late->source('ATop')->deploy_depends_on, 'ARRAY', 'precondition: an arrayref on the registered source');
  is_deeply(view_order($late), [qw( z_late a_late )], '... is read like the hash a class declaration becomes');

  # What deploy_depends_on names besides deployed views puts nothing in
  # order: a table is there before every view, and a class this schema does
  # not deploy is not the script's to create.
  my $virtual = view_class(v_virtual => 'SELECT 1 AS id');
  $virtual->result_source_instance->is_virtual(1);
  my $mixed = view_class(a_mixed => 'SELECT id FROM item', $item, 'T102::Result::Nowhere', $virtual);
  lives_and {
    is_deeply(view_order(schema_class(Item => $item, Mixed => $mixed, Virtual => $virtual)), ['a_mixed']);
  } 'a table, a class that is not registered and a virtual view in deploy_depends_on order nothing';
}

# A circle cannot be created in any order.
{
  my $item = table_class('item');
  my $one = view_class(v_one => 'SELECT id FROM v_two');
  my $two = view_class(v_two => 'SELECT id FROM v_three');
  my $three = view_class(v_three => 'SELECT id FROM v_one');
  $three->pg_schema('app');
  $one->result_source_instance->deploy_depends_on([$two]);
  $two->result_source_instance->deploy_depends_on([$three]);
  $three->result_source_instance->deploy_depends_on([$one]);
  my $schema = schema_class(Item => $item, One => $one, Two => $two, Three => $three,
    Fine => view_class(v_fine => 'SELECT id FROM item'));

  throws_ok { ddl($schema) } qr/\Arefusing to write the install DDL: /, 'views that name one another in a circle are refused';
  my $message = $@;
  like($message, qr/\bview \Q$_\E\b/, "the refusal names $_") for qw( v_one v_two app.v_three );
  like($message, qr/\Q$_\E/, "... and its class $_") for $one, $two, $three;
  like($message, qr/deploy_depends_on/, '... and says where the circle is declared');
  unlike($message, qr/v_fine/, 'a view that is not part of it is not named');

  my $self = view_class(v_self => 'SELECT 1 AS id');
  $self->result_source_instance->deploy_depends_on([$self]);
  throws_ok { ddl(schema_class(Item => $item, Self => $self)) }
    qr/\Arefusing to write the install DDL: .*\bview v_self\b/s, 'and so is a view that names itself';
}

# ---------------------------------------------------------------------------
# 4. The semicolon that ends a statement ends it
# ---------------------------------------------------------------------------
{
  {
    package T102::PgSchema::Public;
    use base 'DBIO::PostgreSQL::PgSchema';
    __PACKAGE__->pg_function('touch' => q{
      CREATE FUNCTION touch() RETURNS trigger AS $$ BEGIN RETURN NEW; END; $$ LANGUAGE plpgsql -- for the triggers
    });
  }
  my $item = table_class('item');
  $item->pg_extra_ddl(
    'CREATE INDEX item_tail_idx ON item (a) -- a note behind it',
    'CREATE INDEX item_plain_idx ON item (a, id);',
  );
  my $schema = schema_class(Item => $item,
    V => view_class(v_noted => "SELECT id FROM item -- every one of them"));
  $schema->pg_schemas('public');
  $schema->pg_schema_class(public => 'T102::PgSchema::Public');
  my $sql = ddl($schema);
  note $sql;

  # The script the way psql or a single do() reads it: a line comment runs
  # to the end of its line and takes a semicolon in it along. (The body of
  # the function is put aside first; its semicolons end nothing.)
  (my $read = $sql) =~ s/\$\$.*?\$\$/<body>/gs;
  $read =~ s/--[^\n]*//g;
  my @statements = grep { length } map { s/\A\s+|\s+\z//gr } split /;/, $read;
  for my $expect (
    [ qr/\ACREATE FUNCTION touch\(\) RETURNS trigger AS <body> LANGUAGE plpgsql\z/, 'a function that closes with a comment' ],
    [ qr/\ACREATE INDEX item_tail_idx ON item \(a\)\z/,       'a pg_extra_ddl statement that closes with a comment' ],
    [ qr/\ACREATE INDEX item_plain_idx ON item \(a, id\)\z/,  'the pg_extra_ddl statement behind it' ],
    [ qr/\ACREATE VIEW v_noted AS SELECT id FROM item\z/,     'a view whose definition closes with a comment' ],
  ) {
    my ($match, $what) = @$expect;
    is(scalar(grep { $_ =~ $match } @statements), 1, "$what is a statement of its own")
      or diag explain \@statements;
  }
  unlike($sql, qr/;;/, 'a statement declared with its semicolon does not get a second one');

  # ... and the way the deploy reads it. A deploy that reads comments (core
  # k326) takes a semicolon in one for part of it, like the server; the one
  # before cut at every semicolon. Either runs each of these for itself.
  my @run = run_by_deploy($sql);
  for my $expect (
    [ qr/\ACREATE FUNCTION touch\(\) /,                       'the function that closes with a comment' ],
    [ qr/\ACREATE TABLE item /,                               'the table behind it' ],
    [ qr/\ACREATE INDEX item_tail_idx ON item \(a\)/,         'the pg_extra_ddl statement that closes with a comment' ],
    [ qr/\ACREATE INDEX item_plain_idx ON item \(a, id\)\z/,  'the pg_extra_ddl statement behind it' ],
    [ qr/\ACREATE VIEW v_noted AS SELECT id FROM item/,       'the view whose definition closes with a comment' ],
  ) {
    my ($match, $what) = @$expect;
    is(scalar(grep { $_ =~ $match } @run), 1, "$what is a statement the deploy runs for itself")
      or diag explain \@run;
  }
  is(scalar @run, 5, 'and those five are all it runs: no two of them as one') or diag explain \@run;
}

done_testing;
