package Test;

use Moo;
use MyApp::Schema;

our $dsn    = "dbi:SQLite::memory:";
our $schema = MyApp::Schema->connect($dsn);

sub initialize
{
    my $dbh = $schema->storage->dbh;
    my ($sql, $in);

    open ($in, "<", "t/sql/sqlite.sql");
    { local $/ = undef; $sql = <$in>; }
    close $in;

    $dbh->do($_) for split(/\n\n/, $sql);

    return $schema;
}

1;

