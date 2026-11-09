use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use My::Schema;
use My::Test qw(deploy_schema);
use DBIO::GraphQL;
use DBIO::Exception::Server;

# Every resolver runs inside an error envelope: the client gets a class and a
# fixed message for a database refusal, "internal error" plus a correlation id
# for everything else, and the original text goes to the on_error hook only.
# What DBIO::GraphQL words for the client itself stays as it is.

my $LEAKY = 'DBI Exception: DBD::Pg::st execute failed: ERROR: duplicate key '
  . 'value violates unique constraint "authors_email_key" [for Statement '
  . '"INSERT INTO authors ( email, name) VALUES ( ?, ? )" with ParamValues: '
  . "1='dup\@x', 2='secret-name'] at /srv/app/lib/DBIO/GraphQL/Mutation.pm line 91";

sub server_error {
  my ($state) = @_;
  return DBIO::Exception::Server->new(message => $LEAKY, sqlstate => $state);
}

sub build {
  my (%opts) = @_;
  my $db = My::Schema->connect('dbi:SQLite:dbname=:memory:');
  deploy_schema($db);
  $db->resultset('Author')->create({ id => 1, name => 'Seed', email => 'seed@example.com' });
  my $r = DBIO::GraphQL->to_graphql($db, mutations => 1, %opts);
  return ($r->{execute}, $r->{context});
}

my $CREATE = 'mutation { createAuthor(name: "secret-name", email: "dup@x") { id } }';

sub assert_no_leak {
  my ($message, $label) = @_;
  unlike($message, qr/INSERT|dup\@x|secret-name|authors_email_key|DBI Exception|ParamValues/,
    "$label: no statement, bind value or constraint name");
  unlike($message, qr/ at \S+ line \d+/, "$label: no path and line");
  unlike($message, qr{/srv/app}, "$label: no file path");
}

# A database refusal is classified by its SQLSTATE
for my $case (
  [ '23505', 'UNIQUE_VIOLATION'      ],
  [ '23503', 'FOREIGN_KEY_VIOLATION' ],
  [ '23502', 'NOT_NULL_VIOLATION'    ],
  [ '23514', 'CHECK_VIOLATION'       ],
) {
  my ($state, $code) = @$case;
  my ($exec, $ctx) = build(on_error => sub { fail('on_error is for internal errors only') });
  no warnings 'redefine';
  local *DBIO::ResultSet::create = sub { die server_error($state) };
  my $res = $exec->($CREATE, undef, $ctx, {});

  my $err = $res->{errors}[0];
  is($err->{extensions}{code}, $code, "$state is $code");
  ok(length $err->{message}, "$code: fixed message");
  assert_no_leak($err->{message}, $code);
  ok(!exists $err->{extensions}{correlation_id}, "$code: no correlation id");
  ok(!defined $res->{data}{createAuthor}, "$code: data is null");
}

# Anything else is "internal error" with a correlation id; the hook gets the original
{
  my @seen;
  my ($exec, $ctx) = build(on_error => sub { push @seen, [@_] });
  no warnings 'redefine';
  local *DBIO::ResultSet::create = sub { die server_error('40001') };
  my $res = $exec->($CREATE, undef, $ctx, {});

  my $err = $res->{errors}[0];
  is($err->{message}, 'internal error', 'unclassified server error: internal error');
  is($err->{extensions}{code}, 'INTERNAL_ERROR', 'code INTERNAL_ERROR');
  like($err->{extensions}{correlation_id} // '', qr/\A[0-9a-f-]+\z/, 'a correlation id');
  assert_no_leak($err->{message}, 'internal error');

  is(scalar @seen, 1, 'the hook ran once');
  like("$seen[0][0]", qr/INSERT INTO authors.*dup\@x/s, 'the hook gets the original text');
  is($seen[0][1], $err->{extensions}{correlation_id}, 'and the same correlation id');
}

# A Perl error (not a database refusal) is an internal error too
{
  my @seen;
  my ($exec, $ctx) = build(on_error => sub { push @seen, [@_] });
  no warnings 'redefine';
  local *DBIO::ResultSet::create = sub { die "boom at /srv/app/lib/X.pm line 3.\n" };
  my $res = $exec->($CREATE, undef, $ctx, {});
  is($res->{errors}[0]{message}, 'internal error', 'plain die: internal error');
  like($seen[0][0], qr/boom/, 'the hook has the text');
}

# Without a hook the envelope warns with the id and the original text
{
  my ($exec, $ctx) = build();
  no warnings 'redefine';
  local *DBIO::ResultSet::create = sub { die server_error(undef) };
  my @warnings;
  my $res = do {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $exec->($CREATE, undef, $ctx, {});
  };
  my $id = $res->{errors}[0]{extensions}{correlation_id};
  is(scalar @warnings, 1, 'one warning');
  like($warnings[0], qr/\Q$id\E/, 'the warning has the correlation id');
  like($warnings[0], qr/INSERT INTO authors/, 'and the original text');
  assert_no_leak($res->{errors}[0]{message}, 'no hook');
}

# A hook that dies does not reach the client
{
  my ($exec, $ctx) = build(on_error => sub { die "hook failed with INSERT\n" });
  no warnings 'redefine';
  local *DBIO::ResultSet::create = sub { die server_error(undef) };
  my @warnings;
  my $res = do {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $exec->($CREATE, undef, $ctx, {});
  };
  is($res->{errors}[0]{message}, 'internal error', 'a failing hook: still internal error');
  unlike(join('', @warnings), qr/INSERT/, 'and its text is not echoed');
}

# The query path is wrapped too
{
  my @seen;
  my ($exec, $ctx) = build(on_error => sub { push @seen, [@_] });
  no warnings 'redefine';
  local *DBIO::ResultSet::all = sub { die server_error(undef) };
  my $res = $exec->('{ allAuthors { nodes { id } } }', undef, $ctx, {});
  is($res->{errors}[0]{message}, 'internal error', 'query: internal error');
  is($res->{errors}[0]{extensions}{code}, 'INTERNAL_ERROR', 'query: code');
  assert_no_leak($res->{errors}[0]{message}, 'query');
  like("$seen[0][0]", qr/INSERT INTO authors/, 'query: the hook has the original');
}

# What DBIO::GraphQL words for the client stays as it is
{
  my ($exec, $ctx) = build(on_error => sub { fail('client errors do not reach the hook') });

  my $res = $exec->('{ allAuthors(page: { take: 0 }) { total } }', undef, $ctx, {});
  is($res->{errors}[0]{message}, "DBIO::GraphQL: page 'take' must be >= 1 (got 0)",
    'validation error: unchanged');
  ok(!$res->{errors}[0]{extensions}, 'no extensions on it');

  $res = $exec->('mutation { updateAuthor(id: 999, name: "x") { id } }', undef, $ctx, {});
  is($res->{errors}[0]{message}, 'No Author row found for the supplied key(s)',
    'mutation not-found: unchanged');

  my ($exec2, $ctx2) = build(authorize => sub { 0 });
  $res = $exec2->('{ allAuthors { total } }', undef, $ctx2, {});
  is($res->{errors}[0]{message}, 'DBIO::GraphQL: not authorized', 'authorize: unchanged');
}

# The option is validated like the others
eval { DBIO::GraphQL->to_graphql(My::Schema->connect('dbi:SQLite:dbname=:memory:'), on_error => 'log') };
like($@, qr/'on_error' must be a code reference/, 'on_error must be a code reference');

done_testing;
