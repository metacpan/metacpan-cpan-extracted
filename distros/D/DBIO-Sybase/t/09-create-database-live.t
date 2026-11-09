use strict;
use warnings;

use Test::More;
use DBI;
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;

# LIVE (karr k73). The server the live suite runs against has room, on its
# default devices, for the databases the suite makes. This file comes first
# among the live files so that a server without that room is named here, with
# its reason, before t/31, t/32, t/63 and t/66 die of it without a plan and
# t/62 loses the tests of its deploy section.
#
# WHY IT CAN FAIL: a database made by a plain CREATE DATABASE goes onto a
# default device and has at least the size of `model`. On the ASE image of
# maint/k8s/ase.yaml (16K pages) `model` is 24 MB, and the image's own start
# leaves 20 MB on `master`, its only default device:
#
#   Msg 1810: CREATE DATABASE failed because of incorrectly specified or
#   unavailable space. Total number of megabytes specified and available must
#   be at least 24 megabytes so Model Database can be copied to the new
#   database.
#
# The pod of maint/k8s/ase.yaml adds a default device of its own at start; a
# container started any other way needs one by hand (README.md, "Live tests").
#
# CLAIMED, in the shapes the suite uses:
#
#   1. A plain CREATE DATABASE -- no device, no size, what
#      DBIO::Sybase::Deploy sends for its temporary database -- is taken.
#   2. A second one beside it is taken too: t/31 and t/32 hold a database of
#      their own while DBIO::Sybase::Deploy->diff makes its temporary one.
#   3. With both gone, one of 48 MB `on default` is taken and has its 48 MB:
#      the largest database of the suite (t/63).
#
# NOT claimed: how much room there is beyond that, or that several live files
# could run at once -- the suite runs one file at a time.
#
# Needs a login allowed to CREATE DATABASE (sa on the docker/k8s ASE image).

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && $user;

my $dbh = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

# What the server says beside the error -- how much it could allocate, and on
# which device (Msg 1805, severity 10) -- is kept for the diagnosis and not
# printed.
my @said;
$dbh->{syb_err_handler} = sub {
  my ($number, $severity, $text) = @_[0, 1, 6];
  return 1 if $severity > 10;
  push @said, "Msg $number: $text" if defined $text;
  return 0;
};

$dbh->do('use master');

my $prefix = "dbio_k73_${$}_";

sub ours {
  ( my $like = $prefix ) =~ s/_/[_]/g;
  return @{ $dbh->selectcol_arrayref(
    "select name from master..sysdatabases where name like '$like%'"
  ) };
}

# Drops them, and returns what the server kept, each with its reason. The
# server may refuse a drop for a moment (Msg 3702, karr k74): repeated in
# t/lib/AseDatabase.pm.
sub drop_ours {
  return map { my $said = AseDatabase::drop($dbh, $_); $said ? "$_: $said" : () } ours();
}

sub megabytes { ( $dbh->selectrow_array(@_) )[0] }

# The reason, in the server's own numbers. status & 1 marks a default device;
# low and high are virtual pages of 2K.
sub why {
  my ($error) = @_;

  $error =~ s/\s+/ /g;
  diag "  $error";
  for my $line (@said) {
    $line =~ s/\s+/ /g;
    diag "  $line";
  }

  my $devices = eval { $dbh->selectall_arrayref(
    'select name, (high - low + 1) / 512 from master..sysdevices '
  . 'where status & 1 = 1 order by name'
  ) } || [];
  my $model = eval { megabytes(
    'select sum(size) * (@@maxpagesize / 1024) / 1024 from master..sysusages '
  . q{where dbid = db_id('model')}
  ) };

  diag '  default devices: ' . ( @$devices
    ? join( ', ', map { "$_->[0] ($_->[1] MB in all)" } @$devices )
    : '(none)' );
  diag '  model, the least a new database takes: '
     . ( defined $model ? "$model MB" : '(unknown)' );
  diag '  The server needs a default device with room for the databases of '
     . 'the live suite: maint/k8s/ase.yaml makes one at start, README.md '
     . '("Live tests") has the statements for any other server.';
}

# ASE does not refuse a size it cannot give: as long as there is room for
# `model` it makes the database with what is there and says so in Msg 1805
# only. So a size asked for is read back.
sub taken {
  my ($db, $megabytes, $name) = @_;

  @said = ();
  my $got;
  my $lived = eval {
    $dbh->do("create database $prefix$db"
      . ( $megabytes ? " on default = '${megabytes}M'" : '' ));
    $got = megabytes(
      'select sum(size) * (@@maxpagesize / 1024) / 1024 from master..sysusages '
    . "where dbid = db_id('$prefix$db')"
    );
    1;
  };
  my $error = $@;

  ok $lived && $got >= ( $megabytes // 0 ), $name
    or why( $lived
      ? "the server made the database with $got MB of the $megabytes asked for"
      : $error );
}

# what a run of this process id that died left behind
if (my @kept = drop_ours()) { die "in the way of this test: @kept\n" }

taken a => undef,
  'a plain CREATE DATABASE is taken: a default device has room for a '
  . 'database the size of model';

taken b => undef,
  'a second one beside it is taken: the database of a test and the '
  . 'temporary one of Deploy->diff at once';

is_deeply [ drop_ours() ], [], 'both are dropped again';

taken c => 48,
  'a database of 48 MB on default is made with 48 MB: the largest of the '
  . 'suite';

is_deeply [ drop_ours() ], [], 'it is dropped again';

# For a run that died on the way.
END {
  if ($dbh) {
    local $@;
    my @kept = eval { drop_ours() };
    diag "could not drop the databases of this test: $_" for ( $@ || () ), @kept;
  }
}

done_testing;
