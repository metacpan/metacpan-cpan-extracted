use strict;
use Test::More;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DND::SQLite for testing')
	: (no_plan => 1);
}

my $DB  = "t/testdb";
unlink $DB if -e $DB;

my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 0 });

package Music::DBI;
use base qw(Class::DBI);
__PACKAGE__->set_db(Main => @DSN);

my $sql = <<'SQL_END';

---------------------------------------
-- Artists
---------------------------------------
CREATE TABLE artists (
	id INTEGER NOT NULL PRIMARY KEY,
	name VARCHAR(32)
);

INSERT INTO artists VALUES (1, "Willie Nelson");
INSERT INTO artists VALUES (2, "Patsy Cline");

---------------------------------------
-- CDs
---------------------------------------
CREATE TABLE cds (
	id INTEGER NOT NULL PRIMARY KEY,
	artist INTEGER,
	title VARCHAR(32),
	year INTEGER
);
INSERT INTO cds VALUES (1, 1, "Songs", 2005);
INSERT INTO cds VALUES (2, 1, "Read Headed Stanger", 2000);
INSERT INTO cds VALUES (3, 1, "Wanted! The Outlaws", 2004);
INSERT INTO cds VALUES (4, 1, "The Very Best of Willie Nelson", 1999);

INSERT INTO cds VALUES (5, 2, "12 Greates Hits", 1999);
INSERT INTO cds VALUES (6, 2, "Sweet Dreams", 1995);
INSERT INTO cds VALUES (7, 2, "The Best of Patsy Cline", 1991);

---------------------------------------
-- Tracks
---------------------------------------
CREATE TABLE tracks (
	id INTEGER NOT NULL PRIMARY KEY,
	cd INTEGER,
	position INTEGER,
	title VARCHAR(32)
);
INSERT INTO tracks VALUES (1, 1, 1, "Songs: Track 1");
INSERT INTO tracks VALUES (2, 1, 2, "Songs: Track 2");
INSERT INTO tracks VALUES (3, 1, 3, "Songs: Track 3");
INSERT INTO tracks VALUES (4, 1, 4, "Songs: Track 4");

INSERT INTO tracks VALUES (5, 2, 1, "Read Headed Stanger: Track 1");
INSERT INTO tracks VALUES (6, 2, 2, "Read Headed Stanger: Track 2");
INSERT INTO tracks VALUES (7, 2, 3, "Read Headed Stanger: Track 3");
INSERT INTO tracks VALUES (8, 2, 4, "Read Headed Stanger: Track 4");

INSERT INTO tracks VALUES (9, 3, 1, "Wanted! The Outlaws: Track 1");
INSERT INTO tracks VALUES (10, 3, 2, "Wanted! The Outlaws: Track 2");

INSERT INTO tracks VALUES (11, 4, 1, "The Very Best of Willie Nelson: Track 1");
INSERT INTO tracks VALUES (12, 4, 2, "The Very Best of Willie Nelson: Track 2");
INSERT INTO tracks VALUES (13, 4, 3, "The Very Best of Willie Nelson: Track 3");
INSERT INTO tracks VALUES (14, 4, 4, "The Very Best of Willie Nelson: Track 4");
INSERT INTO tracks VALUES (15, 4, 5, "The Very Best of Willie Nelson: Track 5");
INSERT INTO tracks VALUES (16, 4, 6, "The Very Best of Willie Nelson: Track 6");

INSERT INTO tracks VALUES (17, 5, 1, "12 Greates Hits: Track 1");
INSERT INTO tracks VALUES (18, 5, 2, "12 Greates Hits: Track 2");
INSERT INTO tracks VALUES (19, 5, 3, "12 Greates Hits: Track 3");
INSERT INTO tracks VALUES (20, 5, 4, "12 Greates Hits: Track 4");

INSERT INTO tracks VALUES (21, 6, 1, "Sweet Dreams: Track 1");
INSERT INTO tracks VALUES (22, 6, 2, "Sweet Dreams: Track 2");
INSERT INTO tracks VALUES (23, 6, 3, "Sweet Dreams: Track 3");
INSERT INTO tracks VALUES (24, 6, 4, "Sweet Dreams: Track 4");

INSERT INTO tracks VALUES (25, 7, 1, "The Best of Patsy Cline: Track 1");
INSERT INTO tracks VALUES (26, 7, 2, "The Best of Patsy Cline: Track 2");

SQL_END

foreach my $statement (split /;/, $sql) {
	$statement =~ s/^\s*//gs;
	$statement =~ s/\s*$//gs;
	next unless $statement;
	Music::DBI->db_Main->do($statement) or die "$@ $!";
}

Music::DBI->dbi_commit;

package Music::Artist;
use base 'Music::DBI';
Music::Artist->table('artists');
Music::Artist->columns(All => qw/id name/);
Music::Artist->has_many(cds => 'Music::CD');

package Music::CD;
use base 'Music::DBI';
Music::CD->table('cds');
Music::CD->columns(All => qw/id artist title year/);
Music::CD->has_many(tracks => 'Music::Track');
Music::CD->has_a(artist => 'Music::Artist');

package Music::Track;
use base 'Music::DBI';
use Class::DBI::Plugin::DeepAbstractSearch;
use Class::DBI::Plugin::DeepAbstractSearchPager;

Music::Track->table('tracks');
Music::Track->columns(All => qw/id cd position title/);
Music::Track->has_a(cd => 'Music::CD');

package main;

{
	my $where = { 'cd.title' => { -like => 'S%' }, };
	my $order_by = "cd.title, title";
	my $pager = Music::Track->deep_pager( $where, $order_by);
	my @tracks;
	
	$pager->per_page( 3 );
	$pager->page( 1 );
	@tracks = $pager->deep_search_where;
	is_deeply [ @tracks ], [ 1, 2, 3 ],		"Tracks from CDs whose name starts with 'S'";

	$pager->page( 2 );
	@tracks = $pager->deep_search_where;
	is_deeply [ @tracks ], [ 4, 21, 22 ],		"Tracks from CDs whose name starts with 'S'";

	$pager->page( 3 );
	@tracks = $pager->deep_search_where;
	is_deeply [ @tracks ], [ 23, 24 ],		"Tracks from CDs whose name starts with 'S'";

	$pager->page( 4 );
	@tracks = $pager->deep_search_where;
	is_deeply [ @tracks ], [ 23, 24 ],		"Tracks from CDs whose name starts with 'S'";


#	is_deeply [ @cds ], [1, 2, 3, 4, 21, 22, 23, 24 ],		"Tracks from CDs whose name starts with 'S'";
}


END { unlink $DB if -e $DB }

