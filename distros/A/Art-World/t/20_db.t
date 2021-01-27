use Test::More tests => 1;
SKIP: {
    skip 'The DBI is not yet implemented', 1;

# use Data::Dump;
# use BSON::Document;
# use Data::Dump::Tree;
# use MongoDB::Client;
# use MongoDB::Database;
# use MongoDB::Collection;
# use MongoDB::Cursor;
# use Art::Agent::Artist;
# use Art::ODM;

# say  $*CWD;
# my $plan = 7;

# # As far as I know, the module shouldn't be installed in a "Art-World"
# # directory on Gitlab-CI
# plan :skip-all<These tests must be executed with a running MongoDB>
#               unless $*CWD ~~ m/ \/Art\-World /;

# my $mongo = Art::ODM.new(
#     client-uri => 'mongodb://127.0.0.1:27017',
#     database-name => 'art-worlds'
# );

# does-ok $mongo, Art::Behavior::Connectable;
# isa-ok $mongo.database, 'MongoDB::Database';

# my MongoDB::Collection $artist-coll = $mongo.database.collection('artists');

# my MongoDB::Cursor $cursor = $artist-coll.find;

# my @artists;

# while $cursor.fetch -> BSON::Document $artist-doc {
#     my $artist = Art::Agent::Artist.new(
#         name => $artist-doc<name>,
#         database => $mongo.database
#     );
#     @artists.push($artist);
# }

# ok @artists[1].name eq "Seb Hu-Rillettes",
# @artists[0].name ~ ' has been found in the database';
# ok @artists[0].name eq "Amelia Butterfly",
# @artists[1].name ~ ' has been found in the database';

# for @artists -> $artist {
#     does-ok $artist, Art::Behavior::Crudable;
#     isa-ok $artist.database, "MongoDB::Database";
#     ok $artist.type-for-document eq 'artist', "split get-type() test";
#     $plan += 3;
# }

# my $artist = Art::Agent::Artist.new(
#     name => "Alice Wonder",
#     database => $mongo.database
# );

# ok $artist.save($artist.name), 'DB save was a success';
# ok $artist.save(@artists[1].name), 'DB save was a success';
# ok $artist.save(@artists[2].name), 'DB save was a success';

# say $artist.^attributes;

# plan $plan;
    ok "Not implemented";
}
done_testing;
