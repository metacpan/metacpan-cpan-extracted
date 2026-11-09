use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp ();

use DBIO::SQLite::Test;

plan tests => 2;
my $wait_for = 120;  # how many seconds to wait

for my $close (0,1) {

  my $tmp = File::Temp->new(
    UNLINK => 1,
    SUFFIX => '.db',
    TEMPLATE => 'DBIO-XXXXXX',
    TMPDIR => 1,  # the file belongs in the temp dir, not the dist root
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
    my $schema = DBIO::Test::Schema->clone;
    $schema->storage_type('DBIO::SQLite::Storage');
    $schema = $schema->connect("DBI:SQLite:$tmp_fn");
    $schema->storage->dbh_do(sub { $_[1]->do('PRAGMA synchronous = OFF') });
    DBIO::Test->deploy_schema($schema);
    DBIO::Test->populate_schema($schema);
  });

  alarm 0;
}
