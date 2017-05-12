#!perl -w

# Make sure we can connect and disconnect cleanly.
# All tests are stopped if we cannot make the first connect.

use Test::More;
use DBI;
use strict;
$|=1;

if (defined $ENV{DBI_DSN}) {
    plan tests => 9;
}
else {
    plan skip_all => 'Cannot run test unless DBI_DSN is defined. See the README file.';
}


# Trapping a connection error can be tricky, but we only have to do it this
# thoroughly one time. We are trapping two classes of errors: the first is
# when we truly do not connect, usually a bad DBI_DSN; the second is an
# invalid login, usually a bad DBI_USER or DBI_PASS.

my $dbh;
eval {
    $dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                        {RaiseError => 1, PrintError => 1, AutoCommit => 0});
};
if ($@) {
    if (!$DBI::errstr) {
        print STDOUT "Bail out! Could not connect: $@\n";
    }
    else {
        print STDOUT "Bail out! Could not connect: $DBI::errstr\n";
    }
    exit;                       # Force a hasty exit
}

pass('Established a connection to the database');

my $pgversion = DBD::PgPP::pgpp_server_version($dbh);

like($pgversion, qr/^[0-9._]+\z/, "Found PostgreSQL version as $pgversion");

ok($dbh->disconnect, 'Disconnect from the database');

# Connect two times. From this point onward, do a simpler connection check
ok($dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                       {RaiseError => 1, PrintError => 0, AutoCommit => 0}),
   'Connected with first database handle');

my $dbh2;
ok($dbh2 = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                        {RaiseError => 1, PrintError => 0, AutoCommit => 0}),
   'Connected with second database handle');

my $sth = $dbh->prepare('SELECT * FROM dbd_pg_test');
ok($dbh->disconnect, 'Disconnect with first database handle');
ok($dbh2->disconnect, 'Disconnect with second database handle');
ok($dbh2->disconnect, 'Disconnect again with second database handle');

eval { $sth->execute };
ok($@, 'Execute fails on a disconnected statement');

END {
    no warnings qw<uninitialized>;
    diag "\n".
     "Program       Version\n".
     "DBD::PgPP     $DBD::PgPP::VERSION\n".
     "PostgreSQL    $pgversion\n".
     "DBI           $DBI::VERSION";
}

exit 0;
