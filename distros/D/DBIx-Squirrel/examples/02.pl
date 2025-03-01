use DBIx::Squirrel database_entities => [qw/db get_artist_by_id/];
use DBIx::Squirrel::Transform::IO         qw/stderr/;
use DBIx::Squirrel::Transform::JSON::Syck qw/as_json/;
use DBIx::Squirrel::it                    qw/iterator result result_offset/;

db do {
    DBIx::Squirrel->connect(
        "dbi:SQLite:dbname=./t/data/chinook.db",
        "",
        "",
        {
            PrintError     => !!0,
            RaiseError     => !!1,
            sqlite_unicode => !!1,
        },
    );
};

get_artist_by_id do {
    db->results( [
        'SELECT *',            # Long queries may be split into
        'FROM artists',        # multiple strings inside an array,
        'WHERE ArtistId=?',    # making code easier to read
        'LIMIT 1',
    ] )->slice( {} );
};

for my $id ( 1 .. 9 ) {
    get_artist_by_id( $id => (
        sub {
            print STDERR result_offset, " ";     # result_offset is "0" (consider it a row_id)
            print STDERR iterator,      "\n";    # the iterator instance "DBIx::Squirrel::rs=HASH(0xXXXXXXXX)"
            result;                              # Return the result to next stage
        },
        as_json(),                               # transform the result into JSON
        stderr("%s\n"),
    ) )->single();
}

db->disconnect();
