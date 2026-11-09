use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use DBIO::GraphQL;
use My::Test qw(deploy_schema);

# WHY: to_graphql hands out whatever it is given. Without a trust model the
# generated API is full access to every source and column, read and write
# (karr k14). The rule under test: what leaves the boundary is chosen by the
# caller of to_graphql -- sources, hidden and readonly columns, opt-in
# mutations, an authorize hook before every resolver that touches the
# database, and switchable introspection.

{
  package TM::Result::User;
  use DBIO;
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id            => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    email         => { data_type => 'varchar', is_nullable => 0 },
    password_hash => { data_type => 'varchar', is_nullable => 1 },
    is_admin      => { data_type => 'integer', is_nullable => 0, default_value => 0 },
    tenant_id     => { data_type => 'integer', is_nullable => 0, default_value => 0 },
    secret        => { data_type => 'varchar', is_nullable => 1, is_serializable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(by_email => ['email']);
  __PACKAGE__->has_many(posts  => 'TM::Result::Post',  'user_id');
  __PACKAGE__->has_many(audits => 'TM::Result::Audit', 'user_id');
}
{
  package TM::Result::Post;
  use DBIO;
  __PACKAGE__->table('posts');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    user_id   => { data_type => 'integer', is_nullable => 0 },
    title     => { data_type => 'varchar', is_nullable => 0 },
    tenant_id => { data_type => 'integer', is_nullable => 0, default_value => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(user => 'TM::Result::User', 'user_id');
}
{
  package TM::Result::Audit;
  use DBIO;
  __PACKAGE__->table('audits');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    user_id => { data_type => 'integer', is_nullable => 0 },
    note    => { data_type => 'varchar', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(user => 'TM::Result::User', 'user_id');
}
{
  package TM::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class(User  => 'TM::Result::User');
  __PACKAGE__->register_class(Post  => 'TM::Result::Post');
  __PACKAGE__->register_class(Audit => 'TM::Result::Audit');
}
{
  package TM::Counter;
  use base 'DBIO::Storage::Statistics';
  sub query_start { push @{ $_[0]{sql} }, $_[1] }
  sub query_end   { }
}

my $counter = TM::Counter->new;
$counter->{sql} = [];

sub fresh {
  my (%opts) = @_;
  my $db = TM::Schema->connect('dbi:SQLite:dbname=:memory:');
  deploy_schema($db);
  $db->resultset('User')->create({ id => 1, email => 'a@x', password_hash => 'h1',
    tenant_id => 1, secret => 's1' });
  $db->resultset('User')->create({ id => 2, email => 'b@x', password_hash => 'h2',
    tenant_id => 2, secret => 's2' });
  $db->resultset('Post')->create({ id => 1, user_id => 1, title => 'p1', tenant_id => 1 });
  $db->resultset('Post')->create({ id => 2, user_id => 1, title => 'p2', tenant_id => 2 });
  $db->resultset('Post')->create({ id => 3, user_id => 2, title => 'p3', tenant_id => 2 });
  $db->resultset('Audit')->create({ id => 1, user_id => 1, note => 'n' });
  my $r = DBIO::GraphQL->to_graphql($db, %opts);
  $db->storage->debugobj($counter);
  $db->storage->debug(1);
  return ($db, $r);
}

sub gql {
  my ($db, $r, $q) = @_;
  $counter->{sql} = [];
  return $r->{execute}->($q, undef, $r->{context}, {});
}

sub sql_count { scalar @{ $counter->{sql} } }

sub error_like {
  my ($res, $re, $name) = @_;
  my $msg = join "\n", map { $_->{message} // "$_" } @{ $res->{errors} || [] };
  like($msg, $re, $name);
}

# --- mutations are opt-in ---------------------------------------------------

{
  my ($db, $r) = fresh();
  ok(!$r->{schema}->mutation, 'without the mutations option there is no Mutation type');
  my $res = gql($db, $r, 'mutation { deleteUser(id: 1) }');
  ok($res->{errors}, 'a mutation document against such a schema is an error');
  is($db->resultset('User')->count, 2, '... and deleted nothing');
}
{
  my ($db, $r) = fresh(mutations => 1);
  my $mf = $r->{schema}->mutation->fields;
  ok(exists $mf->{$_}, "mutations => 1 gives $_")
    for qw(createUser updateUser deleteUser createPost createAudit);
}
{
  my ($db, $r) = fresh(mutations => [qw(Post)]);
  my $mf = $r->{schema}->mutation->fields;
  is_deeply([ sort keys %$mf ], [qw(createPost deletePost updatePost)],
    'mutations => [Post] gives the Post mutations and no others');
}
{
  eval { fresh(mutations => [qw(Nope)]) };
  like($@, qr/Nope/, 'mutations naming an unknown source dies');
}

# --- source selection -------------------------------------------------------

{
  my ($db, $r) = fresh(except => [qw(Audit)], mutations => 1);
  my $s = $r->{schema};
  my $qf = $s->query->fields;
  ok(!exists $qf->{audit} && !exists $qf->{allAudits}, 'excluded source has no root queries');
  ok(!exists $s->mutation->fields->{createAudit}, '... and no mutations');
  ok(!$s->name2type->{Audit} && !$s->name2type->{AuditFilter}
     && !$s->name2type->{AuditConnection}, '... and no types');
  my $uf = $s->name2type->{User}->fields;
  ok(!exists $uf->{audits}, 'excluded source is gone as relationship target of another source');
  ok(exists $uf->{posts}, 'relationships to included sources stay');
  my $res = gql($db, $r, '{ user(id: 1) { email posts { title } } }');
  ok(!$res->{errors}, 'schema without the source still executes') or diag explain $res->{errors};
}
{
  my ($db, $r) = fresh(sources => [qw(User Post)]);
  ok(!$r->{schema}->name2type->{Audit}, 'sources => [...] leaves the others out');
  ok($r->{schema}->query->fields->{allUsers}, '... and keeps the listed ones');
}
{
  eval { fresh(sources => ['User'], except => ['Audit']) };
  like($@, qr/sources.*except|except.*sources/, 'sources together with except dies');
  eval { fresh(sources => ['Nope']) };
  like($@, qr/Nope/, 'sources naming an unknown source dies');
}

# --- hidden and readonly columns --------------------------------------------

{
  my ($db, $r) = fresh(
    mutations => 1,
    hide      => { User => [qw(password_hash)] },
    readonly  => { User => [qw(is_admin tenant_id)], Post => [qw(id)] },
  );
  my $s  = $r->{schema};
  my $uf = $s->name2type->{User}->fields;
  ok(!exists $uf->{password_hash}, 'hidden column is not a field');
  ok(!exists $uf->{secret}, 'is_serializable => 0 column is hidden without being named');
  ok(exists $uf->{is_admin} && exists $uf->{tenant_id}, 'readonly columns stay readable');

  my $ff = $s->name2type->{UserFilter}->fields;
  ok(!exists $ff->{password_hash} && !exists $ff->{secret}, 'hidden columns are no filter fields');
  ok(exists $ff->{is_admin}, 'readonly columns stay filterable');

  my $mf = $s->mutation->fields;
  for my $m (qw(createUser updateUser)) {
    my $a = $mf->{$m}{args};
    ok(!exists $a->{password_hash} && !exists $a->{secret}, "$m takes no hidden column");
    ok(!exists $a->{is_admin} && !exists $a->{tenant_id}, "$m takes no readonly column");
    ok(exists $a->{email}, "$m still takes a plain column");
  }
  ok(exists $mf->{$_}{args}{id}, "$_ keeps the primary key as identity")
    for qw(updateUser deleteUser updatePost deletePost);
  ok(!exists $mf->{createPost}{args}{id}, 'readonly on a primary key forbids setting it on create');

  my $res = gql($db, $r, '{ allUsers { nodes { id email password_hash } } }');
  ok(!exists $res->{data}{allUsers}{nodes}[0]{password_hash},
    'a hidden column in a query returns no value');
  ok(!grep({ /h[12]/ } map { values %$_ } @{ $res->{data}{allUsers}{nodes} }),
    '... and its data does not leak');

  $res = gql($db, $r, '{ allUsers(orderBy: { field: "password_hash" }) { nodes { id } } }');
  error_like($res, qr/password_hash/, 'ordering by a hidden column is refused');
  $res = gql($db, $r, '{ allUsers(orderBy: { field: "secret" }) { nodes { id } } }');
  error_like($res, qr/secret/, 'ordering by an is_serializable => 0 column is refused');

  $res = gql($db, $r, 'mutation { updateUser(id: 1, email: "n@x", is_admin: 1, tenant_id: 9) { id email is_admin tenant_id } }');
  is($res->{data}{updateUser}{email}, 'n@x', 'updateUser writes the plain column');
  is($res->{data}{updateUser}{is_admin}, 0, 'a readonly column sent by the client is not written');
  is($res->{data}{updateUser}{tenant_id}, 1, '... whichever one');

  $res = gql($db, $r, 'mutation { createUser(email: "c@x", is_admin: 1) { id is_admin } }');
  is($db->resultset('User')->find({ email => 'c@x' })->is_admin, 0,
    "createUser does not set a readonly column either");
}

# --- authorize: denial runs no SQL ------------------------------------------

{
  my @calls;
  my ($db, $r) = fresh(
    mutations => 1,
    authorize => sub { push @calls, [ @_ ]; return 0 },
  );
  for my $case (
    [ get      => '{ user(id: 1) { id } }' ],
    [ list     => '{ allUsers { total nodes { id } } }' ],
    [ create   => 'mutation { createPost(user_id: 1, title: "t") { id } }' ],
    [ update   => 'mutation { updatePost(id: 1, title: "t") { id } }' ],
    [ delete   => 'mutation { deletePost(id: 1) }' ],
  ) {
    my ($op, $q) = @$case;
    @calls = ();
    my $res = gql($db, $r, $q);
    error_like($res, qr/not authorized/, "$op: a false authorize is 'not authorized'");
    is(sql_count(), 0, "$op: no SQL ran") or diag explain $counter->{sql};
    is($calls[0][0], $op, "$op: authorize gets the operation");
  }
  is($db->resultset('Post')->count, 3, 'nothing was written');
}
{
  my @calls;
  my ($db, $r) = fresh(authorize => sub { push @calls, [ @_ ]; return 1 });
  my $res = gql($db, $r, '{ user(id: 1) { email posts { title } } }');
  is($res->{data}{user}{posts}[0]{title}, 'p1', 'a true authorize allows');
  my ($get, $rel) = @calls;
  is_deeply([ @$get[0, 1] ], [qw(get User)], 'get is asked with the source');
  is($get->[2]{id}, 1, '... and the arguments');
  is($get->[3], $db, '... and the context');
  is_deeply([ @$rel[0, 1, 4] ], [qw(relationship Post posts)],
    'relationship is asked with the target source and the relation name');
}
{
  my ($db, $r) = fresh(authorize => sub { $_[0] ne 'relationship' });
  my $res = gql($db, $r, '{ user(id: 1) { email posts { title } } }');
  error_like($res, qr/not authorized/, 'relationship denied');
  is(sql_count(), 1, 'relationship denied runs no SQL beyond the root lookup')
    or diag explain $counter->{sql};
}

# --- authorize: a hashref restricts ------------------------------------------

{
  my ($db, $r) = fresh(authorize => sub {
    $_[1] eq 'User' && $_[0] =~ /^(?:list|get)$/ ? { tenant_id => 1 } : 1
  });
  my $res = gql($db, $r, '{ allUsers { total nodes { id } } }');
  is($res->{data}{allUsers}{total}, 1, 'list: restriction applies to the total');
  is_deeply([ map { $_->{id} } @{ $res->{data}{allUsers}{nodes} } ], [1],
    'list: restriction applies to the nodes');
  $res = gql($db, $r, '{ allUsers(page: { take: 5 }) { total hasNextPage nodes { id } } }');
  is($res->{data}{allUsers}{total}, 1, 'list: restriction holds under pagination');

  $res = gql($db, $r, '{ user(id: 2) { id } }');
  ok(!$res->{errors} && !defined $res->{data}{user}, 'get: restricted-away row is null');
  $res = gql($db, $r, '{ user(id: 1) { id } }');
  is($res->{data}{user}{id}, 1, 'get: row inside the restriction is returned');
}
{
  my ($db, $r) = fresh(authorize => sub {
    $_[0] eq 'relationship' ? { tenant_id => 1 } : 1
  });
  my $res = gql($db, $r, '{ user(id: 1) { posts { title } } }');
  is_deeply([ map { $_->{title} } @{ $res->{data}{user}{posts} } ], ['p1'],
    'relationship: restriction applies to the related rows');
  $res = gql($db, $r, '{ a: post(id: 1) { user { id } } b: post(id: 3) { user { id } } }');
  ok(!$res->{errors}, 'single-valued relationship with restriction runs')
    or diag explain $res->{errors};
  is($res->{data}{a}{user}{id}, 1, 'single relationship: related row inside the restriction');
  ok(!defined $res->{data}{b}{user}, 'single relationship: related row outside it is null');
}
{
  my ($db, $r) = fresh(mutations => 1, authorize => sub {
    $_[1] eq 'User' && $_[0] =~ /^(?:update|delete)$/ ? { tenant_id => 1 } : 1
  });
  my $res = gql($db, $r, 'mutation { updateUser(id: 2, email: "z@x") { id } }');
  error_like($res, qr/row found/i, 'update: row outside the restriction is not found');
  is($db->resultset('User')->find(2)->email, 'b@x', '... and unchanged');

  $res = gql($db, $r, 'mutation { updateUser(id: 1, email: "y@x") { id email } }');
  is($res->{data}{updateUser}{email}, 'y@x', 'update: row inside the restriction is written');
  like(join(' ', grep { /^UPDATE/i } @{ $counter->{sql} }), qr/tenant_id/,
    'update: the restriction stands in the UPDATE statement itself');

  $res = gql($db, $r, 'mutation { deleteUser(id: 2) }');
  ok(!$res->{errors} && !$res->{data}{deleteUser}, 'delete: row outside the restriction deletes nothing (false)');
  is($db->resultset('User')->count, 2, '... both rows remain');
  like(join(' ', grep { /^DELETE/i } @{ $counter->{sql} }), qr/tenant_id/,
    'delete: the restriction stands in the DELETE statement itself');

  $res = gql($db, $r, 'mutation { deletePost(id: 1) }');
  ok($res->{data}{deletePost}, 'delete: unrestricted source still deletes');
}
{
  my ($db, $r) = fresh(mutations => 1, authorize => sub {
    $_[0] eq 'create' ? { tenant_id => 7, title => 'fixed' } : 1
  });
  $db->resultset('Post')->delete({ all => 1 });
  my $res = gql($db, $r, 'mutation { createPost(user_id: 1, title: "fixed") { id title tenant_id } }');
  ok(!$res->{errors}, 'create: matching client value passes') or diag explain $res->{errors};
  is($res->{data}{createPost}{tenant_id}, 7, 'create: restriction values are set as column values');
  $res = gql($db, $r, 'mutation { createPost(user_id: 1, title: "other") { id } }');
  ok($res->{errors}, 'create: a client value that differs from the restriction dies');
  is($db->resultset('Post')->count, 1, '... and wrote nothing');
}

# --- introspection ----------------------------------------------------------

{
  my ($db, $r) = fresh();
  ok(eval { DBIO::GraphQL->check_document($r, '{ __schema { types { name } } }'); 1 },
    'introspection is on by default');
}
{
  my ($db, $r) = fresh(introspection => 0);
  for my $q (
    '{ __schema { types { name } } }',
    '{ __type(name: "User") { name } }',
    '{ a: __schema { types { name } } }',
    '{ ...F } fragment F on Query { __schema { types { name } } }',
  ) {
    eval { DBIO::GraphQL->check_document($r, $q); 1 };
    like($@, qr/introspection/i, "introspection => 0 refuses: $q");
  }
  ok(eval { DBIO::GraphQL->check_document($r, '{ allUsers { total } }'); 1 },
    'a document without introspection passes');
  ok(eval { DBIO::GraphQL->check_document($r, '{ allUsers { __typename } }'); 1 },
    '__typename is not introspection of the schema');
}

done_testing;
