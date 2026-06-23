use strict;
use warnings;

use Test::More;
use DBIO::Test;

my $schema = DBIO::Test->init_schema(no_deploy => 1);

# Mock count queries for the join-based counts
# Count CDs by artist name (has_a join)
$schema->storage->mock(qr/SELECT COUNT.*FROM cd me.*JOIN artist/i, [[3]]);
cmp_ok($schema->resultset("CD")->count({ 'artist.name' => 'Caterwauler McCrae' },
                           { join => 'artist' }),
           '==', 3, 'Count by has_a ok');

# Count CDs by tag (has_many join)
$schema->storage->mock(qr/SELECT COUNT.*FROM cd me.*JOIN tag/i, [[4]]);
cmp_ok($schema->resultset("CD")->count({ 'tags.tag' => 'Blue' }, { join => 'tags' }),
           '==', 4, 'Count by has_many ok');

# Count CDs by liner_notes (might_have join)
$schema->storage->mock(qr/SELECT COUNT.*FROM cd me.*JOIN liner_notes/i, [[3]]);
cmp_ok($schema->resultset("CD")->count(
           { 'liner_notes.notes' => { '!=' =>  undef } },
           { join => 'liner_notes' }),
           '==', 3, 'Count by might_have ok');

# Mixed count with multiple joins
$schema->storage->mock(qr/SELECT COUNT.*FROM cd me.*JOIN tag.*JOIN liner_notes/i, [[2]]);
cmp_ok($schema->resultset("CD")->count(
           { 'year' => { '>', 1998 }, 'tags.tag' => 'Cheesy',
               'liner_notes.notes' => { 'like' => 'Buy%' } },
           { join => [ qw/tags liner_notes/ ] } ),
           '==', 2, "Mixed count ok");

done_testing;
