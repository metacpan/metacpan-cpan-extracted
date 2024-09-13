use DBIx::Squirrel;

$dbh = DBIx::Squirrel->connect('dbi:SQLite:dbname=t/data/chinook.db', '', '');

$artists = $dbh->results(
    'SELECT Name FROM artists ORDER BY Name' => sub {$_->Name}
);

print "$_\n" while $artists->next();

$dbh->disconnect();
