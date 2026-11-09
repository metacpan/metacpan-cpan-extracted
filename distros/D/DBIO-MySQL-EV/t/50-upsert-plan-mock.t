use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Test;
use DBIO::MySQL::EV::Storage;

# OFFLINE pin for karr k68: the ev upsert evaluates the WHOLE plan of the
# owning storage's _mysql_upsert_plan, as the sync DBIO::MySQL::Storage::insert
# does, and the LAST_INSERT_ID() read never replaces a value the caller gave.
#
#   1. a plan that cannot name the row (nameable false, identity wanted)
#      withholds the primary key from the returned columns -- core then
#      resolves undef, as the sync path does -- and says why, once
#   2. result => 'void' / 'count' (no_retrieve) asks for no identity: nothing
#      is withheld and nothing is said
#   3. an auto-increment value the caller supplied (defined, not a literal)
#      survives LAST_INSERT_ID(); an undef one and a literal one still take
#      the session's value
#   4. an insert without a supplied value is unchanged
#   5. a supplied auto-increment 0 means "generate" (MySQL's own rule) unless
#      the session's sql_mode has NO_AUTO_VALUE_ON_ZERO: LAST_INSERT_ID() is
#      then the id, otherwise 0 stays; the sql_mode is read only for a 0

{
  package K68::FakeConn;
  sub new { bless {}, $_[0] }
}
{
  package K68::FakePool;
  sub new      { bless {}, $_[0] }
  sub acquire  { Future->done(K68::FakeConn->new) }
  sub release  { }
  sub _lease   { 1 }
  sub shutdown { }
}
{
  package K68::MockExecutor;
  sub new { bless { calls => [], next_lii => 5, sql_mode => 'STRICT_TRANS_TABLES' }, $_[0] }
  sub execute {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{calls} }, $sql;
    return Future->done([ $self->{sql_mode} ]) if $sql =~ /\@\@SESSION\.sql_mode/;
    return Future->done([ $self->{next_lii} ]) if $sql =~ /LAST_INSERT_ID\(\)$/;
    return Future->done(1);
  }
}

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::MySQL::Storage',
);
my $storage = $schema->storage;
$storage->_async_mode('ev');
my $backend = $storage->_async_storage;
$backend->{pool}     = K68::FakePool->new;
$backend->{executor} = K68::MockExecutor->new;

my $source = $schema->source('Artist');
my $rs     = $schema->resultset('Artist');

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

# --- 1. supplied primary key + 'any': the plan cannot name the row
my $returned = $backend->insert_async(
  $source,
  { artistid => 77, name => 'Tom', rank => 1 },
  { on_conflict => { target => 'any', action => 'update', set => { rank => 1 } } },
)->get;
ok !exists $returned->{artistid},
  'the plan cannot name the row: the primary key is withheld from the returned columns';
is $returned->{name}, 'Tom', 'the rest of the supplied data comes back';
is scalar(grep { /cannot name the row it wrote/ } @warnings), 1,
  'the plan\'s reason is reported';

my $row = $rs->upsert_async(
  { artistid => 77, name => 'Tom', rank => 1 },
  { conflict_target => 'any' },
)->get;
ok !defined $row, 'upsert_async resolves undef where the row cannot be named, as the sync path';
is scalar(grep { /cannot name the row it wrote/ } @warnings), 1,
  'the same reason is reported once, not per call (carp_once)';

# --- 2. no_retrieve: nobody asks for the identity
@warnings = ();
$returned = $backend->insert_async(
  $source,
  { artistid => 78, name => 'Tim', rank => 1 },
  { no_retrieve => 1,
    on_conflict => { target => 'any', action => 'update', set => { rank => 1 } } },
)->get;
is $returned->{artistid}, 78,
  'no_retrieve: the primary key is not withheld (wants_identity is false)';
is scalar(@warnings), 0, 'no_retrieve: nothing is reported';

# --- 3. a supplied auto-increment value survives LAST_INSERT_ID()
$returned = $backend->insert_async($source, { artistid => 77, name => 'A' })->get;
is $returned->{artistid}, 77,
  'a plain insert with a supplied artistid returns it, not LAST_INSERT_ID() (5)';

$returned = $backend->insert_async($source, { artistid => undef, name => 'B' })->get;
is $returned->{artistid}, 5, 'an undef artistid takes the session\'s LAST_INSERT_ID()';

$returned = $backend->insert_async($source, { artistid => \'DEFAULT', name => 'C' })->get;
is $returned->{artistid}, 5, 'a literal artistid takes the session\'s LAST_INSERT_ID()';

# --- 4. unchanged: nothing supplied
$returned = $backend->insert_async($source, { name => 'D' })->get;
is $returned->{artistid}, 5, 'an insert without artistid still gets LAST_INSERT_ID()';

$row = $rs->upsert_async({ name => 'Tom', rank => 2 }, { conflict_target => 'any' })->get;
is $row && $row->artistid, 5, 'an upsert that can name the row still does';

# --- 5. a supplied 0 is "generate" unless NO_AUTO_VALUE_ON_ZERO
my $ex = $backend->{executor};
my $before = @{ $ex->{calls} };
$backend->insert_async($source, { artistid => 77, name => 'E' })->get;
is scalar(grep { /sql_mode/ } @{ $ex->{calls} }[$before .. $#{ $ex->{calls} }]), 0,
  'a non-zero artistid reads no sql_mode';

$returned = $backend->insert_async($source, { artistid => 0, name => 'F' })->get;
is $returned->{artistid}, 5,
  'artistid 0 is "generate": the id is the session\'s LAST_INSERT_ID()';

$returned = $backend->insert_async($source, { artistid => '0', name => 'F' })->get;
is $returned->{artistid}, 5, 'the string "0" is zero too';

$ex->{sql_mode} = 'STRICT_TRANS_TABLES,NO_AUTO_VALUE_ON_ZERO';
$returned = $backend->insert_async($source, { artistid => 0, name => 'G' })->get;
is $returned->{artistid}, 0, 'with NO_AUTO_VALUE_ON_ZERO the 0 stays';
$ex->{sql_mode} = 'STRICT_TRANS_TABLES';

@warnings = ();
$row = $rs->upsert_async(
  { artistid => 0, name => 'Tom', rank => 2 }, { conflict_target => 'any' },
)->get;
is $row && $row->artistid, 5,
  'an upsert with artistid 0 names the row like one without a primary key';
is scalar(@warnings), 0, 'and reports no reason';

done_testing;
