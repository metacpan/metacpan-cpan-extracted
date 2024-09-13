use DBIx::Squirrel;

$dbh = DBIx::Squirrel->connect('dbi:SQLite:dbname=./t/data/chinook.db', '', '');

$artists = $dbh->results(
    'SELECT * FROM artists ORDER BY ArtistId' => sub {
        my($result) = @_;
        printf STDERR "# %3d. %s\n", $result->ArtistId, $result->Name
            if !!$ENV{DEBUG};
        $result;
    } => sub {
        return $_->Name;
    }
);

@artists = $artists->all();

$dbh->disconnect();
