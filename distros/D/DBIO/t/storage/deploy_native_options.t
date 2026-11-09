# ABSTRACT: the options of deploy reach the native Deploy class (add_drop_table), unknown ones throw
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Deploy::Base;
use DBIO::Storage::Async;

# $schema->deploy and $storage->deploy used to take the native route and hand
# the Deploy class nothing but the schema: add_drop_table (and every other
# option) vanished without a word. Now add_drop_table reaches the Deploy class,
# where install drops the declared views and tables in front of the install
# DDL, and any other key throws instead of being dropped.

{
  package T::Dbh;
  sub new { bless { done => [] }, shift }
  sub do  { push @{ $_[0]{done} }, $_[1]; 1 }
}

{
  package T::Deploy;
  use base 'DBIO::Deploy::Base';
  our $dbh;
  sub _dbh         { $dbh }
  sub _install_ddl { 'CREATE TABLE made (id integer);' }
}

{
  package T::PlainStorage;
  use base 'DBIO::Storage::DBI';
  sub dbio_deploy_class { 'T::Deploy' }

  package T::LiteStorage;
  use base 'T::PlainStorage';
  sub _ddl_sql_dialect { 'sqlite' }

  package T::TickStorage;
  use base 'T::PlainStorage';
  sub _ddl_quote_ident { "`$_[1]`" }
}

$INC{'T/Deploy.pm'} = $INC{'T/PlainStorage.pm'} = $INC{'T/LiteStorage.pm'}
  = $INC{'T/TickStorage.pm'} = __FILE__;

sub schema_for {
  my ($storage_type) = @_;
  my $schema = DBIO::Test->init_schema(no_deploy => 1, storage_type => $storage_type);
  return $schema;
}

# the real storage deploy: the fake storage turns deploy into a no-op
sub storage_deploy { DBIO::Storage::DBI::deploy(@_) }

# runs one deploy, answers the statements that reached the handle
sub statements {
  my ($how, $schema, @args) = @_;
  local $T::Deploy::dbh = T::Dbh->new;
  local $SIG{__WARN__} = sub {};
  if ($how eq 'schema') { $schema->deploy(@args) }
  else                  { storage_deploy($schema->storage, $schema, undef, @args) }
  return @{ $T::Deploy::dbh->{done} };
}

for my $how (qw(schema storage)) {
  my $schema = schema_for('T::PlainStorage');

  my @plain = statements($how, $schema);
  is_deeply \@plain, ['CREATE TABLE made (id integer)'],
    "$how: without add_drop_table nothing is dropped";

  my @with = statements($how, $schema, { add_drop_table => 1 });
  is $with[0], 'DROP VIEW IF EXISTS year2000cds',
    "$how: the declared view is dropped first";
  is $with[-1], 'CREATE TABLE made (id integer)',
    "$how: the install DDL comes last, in the same batch";
  ok scalar(grep { $_ eq 'DROP TABLE IF EXISTS artist CASCADE' } @with),
    "$how: the tables are dropped, with CASCADE";
  ok !scalar(grep { /^DROP TABLE/ && $_ !~ /^DROP TABLE IF EXISTS \w+ CASCADE$/ } @with),
    "$how: every table drop is IF EXISTS ... CASCADE";
  my ($last_view) = grep { $with[$_] =~ /^DROP VIEW/ } reverse 0 .. $#with;
  my ($first_table) = grep { $with[$_] =~ /^DROP TABLE/ } 0 .. $#with;
  cmp_ok $last_view, '<', $first_table, "$how: all views go before the first table";

  my @off = statements($how, $schema, { add_drop_table => 0 });
  is scalar(@off), 1, "$how: add_drop_table => 0 drops nothing";

  throws_ok { statements($how, $schema, { add_drop_table => 1, bogus_key => 1 }) }
    qr/bogus_key/, "$how: an unknown option throws and names the key";
  throws_ok { statements($how, $schema, { version => 3 }) }
    qr/'version'.*current state/s, "$how: version throws, saying why";
  throws_ok { statements($how, $schema, 'add_drop_table') }
    qr/hash reference/, "$how: options that are no hash reference throw";
}

# $dir is not refused on the native route
{
  my $schema = schema_for('T::PlainStorage');
  local $T::Deploy::dbh = T::Dbh->new;
  lives_ok { $schema->deploy({}, '/some/dir') } 'schema->deploy ignores $dir';
  lives_ok { storage_deploy($schema->storage, $schema, undef, {}, '/some/dir') }
    'storage->deploy ignores $dir';
}

# a schema without a storage (a class name): install with add_drop_table lives
{
  my $dbh = T::Dbh->new;
  local $T::Deploy::dbh = $dbh;
  local $SIG{__WARN__} = sub {};
  my $schema = schema_for('T::PlainStorage');
  my $deploy = T::Deploy->new(schema => ref $schema, add_drop_table => 1);
  lives_ok { $deploy->install } 'install with add_drop_table lives without a storage';
  ok scalar(grep { $_ eq 'DROP TABLE IF EXISTS artist CASCADE' } @{ $dbh->{done} }),
    'and drops with CASCADE, no sqlite special case without a storage';
}

# a class that overrides install owns the dropping: SUPER::install does not drop
{
  package T::DeployOwn;
  use base 'T::Deploy';
  sub install { my $self = shift; $self->_execute_ddl($self->_dbh, 'DROP TABLE mine;'); $self->SUPER::install(@_) }
}
{
  my $schema = schema_for('T::PlainStorage');
  local $SIG{__WARN__} = sub {};
  local $T::Deploy::dbh = T::Dbh->new;
  T::DeployOwn->new(schema => $schema, add_drop_table => 1)->install;
  is_deeply $T::Deploy::dbh->{done}, ['DROP TABLE mine', 'CREATE TABLE made (id integer)'],
    'install override + SUPER::install: no generic drop';
  local $T::Deploy::dbh = T::Dbh->new;
  T::Deploy->new(schema => $schema, add_drop_table => 1)->install;
  ok scalar(grep { /^DROP VIEW/ } @{ $T::Deploy::dbh->{done} }), 'class without override: generic drop';
}

# sqlite dialect: no CASCADE
{
  my $schema = schema_for('T::LiteStorage');
  my @with = statements('schema', $schema, { add_drop_table => 1 });
  ok scalar(grep { $_ eq 'DROP TABLE IF EXISTS artist' } @with), 'sqlite dialect: DROP TABLE without CASCADE';
  ok !scalar(grep { /CASCADE/ } @with), 'sqlite dialect: no CASCADE anywhere';
}

# quoting goes through the _ddl_quote_ident hook
{
  my $schema = schema_for('T::TickStorage');
  my @with = statements('schema', $schema, { add_drop_table => 1 });
  is $with[0], 'DROP VIEW IF EXISTS `year2000cds`', 'the hook of the storage quotes the view';
  ok scalar(grep { $_ eq 'DROP TABLE IF EXISTS `artist` CASCADE' } @with), 'and the tables';
}

# sync and async share the one function: same statements for the same schema
{
  my $schema = schema_for('T::PlainStorage');
  my $async  = DBIO::Storage::Async->new(undef);
  my $from_async = $async->_drop_statements_for($schema);
  my @with = statements('schema', $schema, { add_drop_table => 1 });
  my $from_sync = join "\n\n", grep { /^DROP / } @with;
  is_deeply [ map { "$_;" } split /\n\n/, $from_sync ], [ split /\n\n/, $from_async ],
    'sync and async drop the same statements for the same schema';
  is $from_async, DBIO::SQL::Util::_drop_statements(
    $schema, sub { DBIO::SQL::Util::_quote_ident($_[0]) }, { cascade => 1 },
  ), 'the async method is the shared function';
}

done_testing;
