use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# handle-read I3: and(), or(), and the join family lacked the void-context guard
# every other immutator has, so `$h->and({...});` in void context silently did
# nothing. They now croak like the rest.

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
    $dbh->do('CREATE TABLE u (id INTEGER PRIMARY KEY, t_id INTEGER REFERENCES t(id))');
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $h   = $con->handle('t');

# The trailing "; 1" forces the immutator into void context.
like(dies { $h->and({id => 1}); 1 }, qr/void context/, "and() croaks in void context");
like(dies { $h->or({id => 1}); 1 },  qr/void context/, "or() croaks in void context");
like(dies { $h->left_join('u'); 1 }, qr/void context/, "left_join() croaks in void context");
like(dies { $h->inner_join('u'); 1 }, qr/void context/, "inner_join() croaks in void context");

ok(lives { my $x = $h->and({id => 1}); $x }, "and() still works in non-void context");

done_testing;
