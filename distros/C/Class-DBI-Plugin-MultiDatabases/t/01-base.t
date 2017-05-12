use strict;
use lib qw(t/lib);

use Test::More tests => 40;

use Music::DBI;
use Music::CD;

my @database = Music::DBI->databases;

SKIP: {
	skip (Music::DBI->skip_message, 40) unless(Music::DBI->has_databases);

my ($cds, $cd);

Music::DBI->set_connections(
	$database[0] => ["dbi:SQLite:dbname=$database[0]", '', ''],
	$database[1] => ["dbi:SQLite:dbname=$database[1]", '', ''],
);


Music::DBI->change_db($database[0]); # testdb1

$cd = Music::CD->retrieve(1);
is($cd->title, "title testdb1-1");
is($cd->artist, "artist testdb1-1");
is($cd->artist->name, "testdb1 111");
is($cd->notes, "notes testdb1-1");

Music::CD->create({
	cdid => 4, title => "added cd", artist => "artist testdb1-1"
});

Music::DBI->change_db($database[1]); # testdb2

is($cd->title, "title testdb1-1", 'remained');
is($cd->artist, "artist testdb1-1");
is($cd->artist->name, "testdb1 111");
is($cd->notes, "notes testdb1-1");

$cd = Music::CD->retrieve(1);

is($cd->title, "title testdb2-1", 'changed result');
is($cd->artist, "artist testdb2-1");
is($cd->artist->name, "testdb2 111");
is($cd->notes, "notes testdb2-1");

$cd = Music::CD->retrieve(4);

ok(!$cd);

Music::DBI->change_db($database[0]); # testdb1

$cd = Music::CD->retrieve(1);
is($cd->title, "title testdb1-1");
is($cd->artist, "artist testdb1-1");
is($cd->artist->name, "testdb1 111");
is($cd->notes, "notes testdb1-1");

$cd = Music::CD->retrieve(4);
is($cd->title, "added cd", "added cd");
is($cd->artist, "artist testdb1-1");
is($cd->artist->name, "testdb1 111");
is($cd->notes, undef);

Music::DBI->change_db($database[1]); # testdb1
$cd = Music::CD->retrieve(4);
is($cd, undef, "empty");


SKIP: {
	skip("Class::DBI doesn't implemented clear_object_index()", 6)
	            unless( Class::DBI->VERSION >= 0.96 and $] >= 5.006 );

	Music::DBI->change_db($database[0]); # testdb1
	$cd = Music::CD->retrieve(1);
	is($cd->title, "title testdb1-1", "clear object...");
	is($cd->artist, "artist testdb1-1");


	Music::DBI->_clear_object(0); # disable to clear

	Music::DBI->change_db($database[1]); # testdb2
	$cd = Music::CD->retrieve(1);
	is($cd->title, "title testdb1-1"); # remain from testdb1
	is($cd->artist, "artist testdb1-1"); # remain from testdb1

	Music::DBI->_clear_object(1);

	Music::DBI->change_db($database[1]); # testdb2
	$cd = Music::CD->retrieve(1);
	is($cd->title, "title testdb2-1");
	is($cd->artist, "artist testdb2-1"); # remain from testdb1
}


{ # TRANSACTION
  # WAIT! I change a primary key in Music::Artist
	local Music::CD->db_Main->{ AutoCommit };

	Music::DBI->change_db($database[0]); # testdb1
	$cd = Music::CD->retrieve(1);
	is($cd->title, "title testdb1-1");
	is($cd->artist->name, "testdb1 111", "transaction...");

	$cd->artist->name("Hoge");
	$cd->artist->update;
	$cd->dbi_commit();

	Music::DBI->change_db($database[1]); # testdb2
	$cd = Music::CD->retrieve(1);
	is($cd->artist->name, "testdb2 111");

	Music::DBI->change_db($database[0]); # testdb1
	$cd = Music::CD->retrieve(1);
	is($cd->artist->name, "Hoge");

	$cd->artist->name("Hoge2");
	$cd->artist->update;
	$cd->dbi_rollback();

	Music::DBI->change_db($database[1]); # testdb2
	$cd = Music::CD->retrieve(1);
	is($cd->artist->name, "testdb2 111");

	Music::DBI->change_db($database[0]); # testdb1
	$cd = Music::CD->retrieve(1);
	is($cd->artist->name, "Hoge");

	my $artist = Music::Artist->retrieve("artist testdb1-1");
	$artist->name('testdb1 111');
	$artist->update;
	$artist->dbi_commit();
	is($artist->name, "testdb1 111", "end transaction");

}

Music::DBI->change_db($database[0]);

is($cd->db_Main, Music::CD->db_Main);

my $saved_dbh = $cd->save_db_Main();

Music::DBI->change_db($database[1]);
isnt($saved_dbh, Music::CD->db_Main);

is($cd->db_Main, $saved_dbh, 'save_db_Main');

$cd->clear_db_Main();

isnt($cd->db_Main, $saved_dbh, 'clear_db_Main');


eval q| Music::CD->change_db($database[0]) |;

like($@, qr/must be called by the imported class./, "exception");

}

__END__
