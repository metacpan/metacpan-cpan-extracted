use strict;
use warnings;
use Test::More;

# LIVE (core k388): a '?' in a literal or a comment in front of a BLOB
# comparison does not move the cast.
#
# WHY: the cast CAST(? AS VARCHAR ...) has to sit on the placeholder of the
# BLOB comparison. The placeholders are found by core's one scanner
# (DBIO::Storage::DBI::NoBindVars::placeholder_offsets); a '?' the scanner
# took for a placeholder would put the cast on the wrong one, and DBD::Firebird
# would die on the BLOB parameter or compare the wrong value. The right row
# must be found with a literal and a comment before the comparison.
#
# WARNING: creates and drops the table "k388_doc".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live BLOB compare test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Firebird::Deploy;

{
  package K388Doc::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('Firebird');

  package K388Doc::Schema::Result::Doc;
  use DBIO 'Core';
  __PACKAGE__->table('k388_doc');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    v  => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package main;
  K388Doc::Schema->register_class(Doc => 'K388Doc::Schema::Result::Doc');
}

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on |problem parsing SQL_/ };

my $schema = K388Doc::Schema->connect($dsn, $user, $pass, { quote_names => 1, on_connect_call => 'use_softcommit' });
eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach Firebird server: $@";

sub cleanup { eval { $schema->storage->dbh->do('DROP TABLE "k388_doc"') } }
cleanup();

ok eval { DBIO::Firebird::Deploy->new(schema => $schema)->install; 1 },
  'install' or diag $@;

my $rs = $schema->resultset('Doc');
$rs->create({ id => 1, v => 'hello' });
$rs->create({ id => 2, v => 'wor?d' });

is $rs->search({ v => 'hello' })->count, 1, 'a text BLOB is found by a bound value';

my @ids = eval {
  $rs->search({ -and => [ \q{'a?b' = 'a?b' /* ? */}, { v => 'wor?d' } ] })->get_column('id')->all;
};
is_deeply \@ids, [2], "a '?' in a literal and a comment before the comparison: the right row"
  or diag $@;

cleanup();
done_testing;
