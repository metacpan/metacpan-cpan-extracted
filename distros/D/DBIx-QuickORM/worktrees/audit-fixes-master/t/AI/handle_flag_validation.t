use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# handle-read I4: handle() stored any -word argument as a flag with no
# validation, so a misspelled flag (e.g. -allow_overide) was silently ignored,
# quietly disabling the protection the caller asked for. Unknown flags now croak.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/x.sqlite";
{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});

like(
    dies { $con->handle('t', -allow_overide => 0) },
    qr/Unknown handle flag '-allow_overide'/,
    "a misspelled flag croaks instead of being silently ignored",
);

ok(lives { $con->handle('t', -allow_override => 0) }, "the correctly-spelled flag still works");
ok(lives { $con->handle('t', -unknown => sub { die 'x' }) }, "the -unknown umbrella flag is accepted");

done_testing;
