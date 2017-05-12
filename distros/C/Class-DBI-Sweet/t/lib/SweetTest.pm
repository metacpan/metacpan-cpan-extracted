package SweetTest;

use strict;
use warnings;
use base qw/Class::DBI::Sweet/;

use Class::DBI::Sweet::Topping;

my $db_file = "t/var/SweetTest.db";

unlink($db_file) if -e $db_file;
unlink($db_file . "-journal") if -e $db_file . "-journal";
mkdir("t/var") unless -d "t/var";

__PACKAGE__->connection("dbi:SQLite:${db_file}");

my $dbh = __PACKAGE__->db_Main;

my $sql = <<EOSQL;
CREATE TABLE artist (artistid INTEGER NOT NULL PRIMARY KEY, name VARCHAR);

CREATE TABLE cd (cdid INTEGER NOT NULL PRIMARY KEY, artist INTEGER NOT NULL,
                     title VARCHAR, year VARCHAR);

CREATE TABLE liner_notes (liner_id INTEGER NOT NULL PRIMARY KEY, notes VARCHAR);

CREATE TABLE track (trackid INTEGER NOT NULL PRIMARY KEY, cd INTEGER NOT NULL,
                       position INTEGER NOT NULL, title VARCHAR);

CREATE TABLE tags (tagid INTEGER NOT NULL PRIMARY KEY, cd INTEGER NOT NULL,
                      tag VARCHAR);

CREATE TABLE twokeys (artist INTEGER NOT NULL, cd INTEGER NOT NULL,
                      PRIMARY KEY (artist, cd) );

CREATE TABLE onekey (id INTEGER NOT NULL PRIMARY KEY,
                      artist INTEGER NOT NULL, cd INTEGER NOT NULL );

INSERT INTO artist (artistid, name) VALUES (1, 'Caterwauler McCrae');

INSERT INTO artist (artistid, name) VALUES (2, 'Random Boy Band');

INSERT INTO artist (artistid, name) VALUES (3, 'We Are Goth');

INSERT INTO cd (cdid, artist, title, year)
    VALUES (1, 1, "Spoonful of bees", 1999);

INSERT INTO cd (cdid, artist, title, year)
    VALUES (2, 1, "Forkful of bees", 2001);

INSERT INTO cd (cdid, artist, title, year)
    VALUES (3, 1, "Caterwaulin' Blues", 1997);

INSERT INTO cd (cdid, artist, title, year)
    VALUES (4, 2, "Generic Manufactured Singles", 2001);

INSERT INTO cd (cdid, artist, title, year)
    VALUES (5, 3, "Come Be Depressed With Us", 1998);

INSERT INTO liner_notes (liner_id, notes)
    VALUES (2, "Buy Whiskey!");

INSERT INTO liner_notes (liner_id, notes)
    VALUES (4, "Buy Merch!");

INSERT INTO liner_notes (liner_id, notes)
    VALUES (5, "Kill Yourself!");

INSERT INTO tags (tagid, cd, tag) VALUES (1, 1, "Blue");

INSERT INTO tags (tagid, cd, tag) VALUES (2, 2, "Blue");

INSERT INTO tags (tagid, cd, tag) VALUES (3, 3, "Blue");

INSERT INTO tags (tagid, cd, tag) VALUES (4, 5, "Blue");

INSERT INTO tags (tagid, cd, tag) VALUES (5, 2, "Cheesy");

INSERT INTO tags (tagid, cd, tag) VALUES (6, 4, "Cheesy");

INSERT INTO tags (tagid, cd, tag) VALUES (7, 5, "Cheesy");

INSERT INTO tags (tagid, cd, tag) VALUES (8, 2, "Shiny");

INSERT INTO tags (tagid, cd, tag) VALUES (9, 4, "Shiny");

INSERT INTO twokeys (artist, cd) VALUES (1, 1);

INSERT INTO twokeys (artist, cd) VALUES (1, 2);

INSERT INTO twokeys (artist, cd) VALUES (2, 2);

INSERT INTO onekey (id, artist, cd) VALUES (1, 1, 1);

INSERT INTO onekey (id, artist, cd) VALUES (2, 1, 2);

INSERT INTO onekey (id, artist, cd) VALUES (3, 2, 2);
EOSQL

$dbh->do($_) for split(/\n\n/, $sql);

package SweetTest::LinerNotes;

use base 'SweetTest';

SweetTest::LinerNotes->table('liner_notes');
SweetTest::LinerNotes->columns(Essential => qw/liner_id notes/);

package SweetTest::Tag;

use base 'SweetTest';

SweetTest::Tag->table('tags');
SweetTest::Tag->columns(Essential => qw/tagid cd tag/);
SweetTest::Tag->has_a(cd => 'SweetTest::CD');

package SweetTest::Track;

use base 'SweetTest';

SweetTest::Track->table('track');
SweetTest::Track->columns(Essential => qw/trackid cd position title/);
SweetTest::Track->has_a(cd => 'SweetTest::CD');

package SweetTest::CD;

use base 'SweetTest';

SweetTest::CD->table('cd');
SweetTest::CD->columns(Essential => qw/cdid artist title year/);

SweetTest::CD->has_many(tracks => 'SweetTest::Track');
SweetTest::CD->has_many(tags => 'SweetTest::Tag');
SweetTest::CD->has_a(artist => 'SweetTest::Artist');

SweetTest::CD->might_have(liner_notes => 'SweetTest::LinerNotes' => qw/notes/);

package SweetTest::Artist;

use base 'SweetTest';

SweetTest::Artist->table('artist');
SweetTest::Artist->columns(Essential => qw/artistid name/);
SweetTest::Artist->has_many(cds => 'SweetTest::CD');
SweetTest::Artist->has_many(twokeys => 'SweetTest::TwoKeys');
SweetTest::Artist->has_many(onekeys => 'SweetTest::OneKey');

package SweetTest::TwoKeys;

use base 'SweetTest';

SweetTest::TwoKeys->table('twokeys');
SweetTest::TwoKeys->columns(Primary => qw/artist cd/);
SweetTest::TwoKeys->has_a(artist => 'SweetTest::Artist');
SweetTest::TwoKeys->has_a(cd => 'SweetTest::CD');

package SweetTest::OneKey;

use base 'SweetTest';

SweetTest::OneKey->table('onekey');
SweetTest::OneKey->columns(Primary => qw/id/);
SweetTest::OneKey->columns(Essential => qw/artist cd/);
SweetTest::OneKey->has_a(artist => 'SweetTest::Artist');
SweetTest::OneKey->has_a(cd => 'SweetTest::CD');

1;
