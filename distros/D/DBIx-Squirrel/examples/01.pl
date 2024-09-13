use DBIx::Squirrel database_entities => [qw/db get_artist_id_by_name/];
use DBIx::Squirrel::Iterator qw/iterator result result_offset/;

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

get_artist_id_by_name do {
    db->results(
        "SELECT ArtistId, Name FROM artists WHERE Name=? LIMIT 1" => sub {
            my($artist) = @_;
            print "----\n";
            print "Name: ", $artist->Name, "\n";
            return $artist;
        } => sub {print result_offset, " ", iterator, "\n"; result} => sub {$_->ArtistId}
    );
};

foreach my $name ("AC/DC", "Aerosmith", "Darling West", "Rush") {
    if (get_artist_id_by_name($name)->single) {
        print "ArtistId: $_\n";
    }
}

db->disconnect();
