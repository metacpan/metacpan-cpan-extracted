use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp ();

plan skip_all => 'Set $ENV{DBIO_TEST_EXTENDED} to run this test'
  unless $ENV{DBIO_TEST_EXTENDED};

use DBIO::SQLite::Test;

plan tests => 2;
my $wait_for = 120;  # how many seconds to wait

for my $close (0,1) {

  my $tmp = File::Temp->new(
    UNLINK => 1,
    SUFFIX => '.db',
    TEMPLATE => 'DBIO-XXXXXX',
    EXLOCK => 0,  # important for BSD and derivatives
  );

  my $tmp_fn = $tmp->filename;
  close $tmp if $close;

  local $SIG{ALRM} = sub { die sprintf (
    "Timeout of %d seconds reached (tempfile still open: %s)",
    $wait_for, $close ? 'No' : 'Yes'
  )};

  alarm $wait_for;

  lives_ok (sub {
    my $schema = DBIO::Test::Schema->connect("DBI:SQLite:$tmp_fn");
    $schema->storage->dbh_do(sub { $_[1]->do('PRAGMA synchronous = OFF') });
    DBIO::SQLite::Test->deploy_schema($schema);
    DBIO::SQLite::Test->populate_schema($schema);
  });

  alarm 0;
}
