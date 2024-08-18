use DBIx::Squirrel database_entities => [qw/db get_artist_by_id/];
use DBIx::Squirrel::Transform::IO         qw/stdout/;
use DBIx::Squirrel::Transform::JSON::Syck qw/as_json/;

db do {
    DBIx::Squirrel->connect(
        "dbi:SQLite:dbname=./t/data/chinook.db",
        "",
        "",
        {   PrintError     => !!0,
            RaiseError     => !!1,
            sqlite_unicode => !!1,
        },
    );
};

get_artist_by_id do {
    db->results("SELECT * FROM artists WHERE ArtistId=? LIMIT 1" => as_json(), stdout("%s\n"))->reset({});
};

foreach my $id (1 .. 9) {
    get_artist_by_id($id)->single;
}

db->disconnect();
