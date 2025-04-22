use DBIx::Squirrel database_entities => [qw/db artists/];
use DBIx::Squirrel::it qw/database result result_offset/;

db( DBIx::Squirrel->connect(
    "dbi:SQLite:dbname=./t/data/chinook.db",
    "",
    "", {
        PrintError     => !!0,
        RaiseError     => !!1,
        sqlite_unicode => !!1,
    },
) );

artists( db->results(
    [
        'SELECT ArtistId, Name',
        'FROM artists',
        'LIMIT 10',
    ] => sub {
        my($artist) = @_;
        printf "---- %s\n", database;
        printf "%4d Name: %s\n", result_offset, $artist->Name;
        return $artist;
    } => sub {
        $_->Name;
    },
) );

artists->all();

db->disconnect();
