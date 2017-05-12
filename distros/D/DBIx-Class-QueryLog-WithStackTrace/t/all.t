#!perl

use strict;
use warnings;
use Test::More tests => 9;

use DBIx::Class::QueryLog::WithStackTrace;

use lib qw(t/lib);
use File::Temp;
my $dbname = File::Temp->new()->filename();
END { unlink($dbname); }

my $schema = setup_db();

my $ql = DBIx::Class::QueryLog::WithStackTrace->new;
ok($ql->isa('DBIx::Class::QueryLog::WithStackTrace'), 'new');
ok($ql->isa('DBIx::Class::Storage::Statistics'), "extends base debug object");

$schema->storage()->debugobj($ql);
$schema->storage()->debug(1);

my $row = sub1($schema);
ok($row->somedata() eq 'two', "can retrieve data from db (sanity check that tests are good)");

ok(scalar(@{ $ql->log }) == 1, 'log count w/1 query');

my @queries = @{ $ql->log };
isa_ok($queries[0], 'DBIx::Class::QueryLog::WithStackTrace::Query',
  "logged query is a DBIx::Class::QueryLog::WithStackTrace::Query");

my @frames = $queries[0]->stacktrace()->frames();

SKIP: {
  skip "Devel::StackTrace can't filter a list of frames yet", 1;
  use Data::Dumper; local $Data::Dumper::Indent = 1;
  is($#frames, 2, "only three frames") || warn(Dumper($queries[0]->stacktrace()));
};

foreach my $tuple (
  [-3 => 'DBIx::Class::ResultSet::find'],
  [-2 => 'main::sub2'],
  [-1 => 'main::sub1'],
) {
  is($frames[$tuple->[0]]->subroutine(), $tuple->[1], "stack element ".(4 + $tuple->[0])." looks good (".$tuple->[1].")");
}

# some noise to get some depth into that stack
sub sub1 { sub2(@_) }
sub sub2 { shift()->resultset('Hlagh')->find(1) }

sub setup_db {
  use DBI;
  use DCQWTestSchema;

  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", '', '');
  $dbh->do("
      CREATE TABLE hlagh (
          pk INT,
          somedata VARCHAR(256),
          PRIMARY KEY (pk)
      )
  ");
  $dbh->do("
      INSERT INTO hlagh (pk, somedata) VALUES (1, 'two')
  ");
  return DCQWTestSchema->connect(
      "dbi:SQLite:dbname=$dbname"
  );
}
