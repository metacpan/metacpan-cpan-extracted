
package MyDatabase;

use strict;
use warnings;

use DBI;
use Carp 'croak';
use Exporter::NoWork;
use Rose::DB::Object::Loader;

use DB;
use autodie;

sub db_handle {
	my $db_file = shift
		or croak "db_handle() requires a database name";

	# no warnings 'once';

	my $dbh = DBI->connect(
		'dbi:SQLite:dbname=:memory:',
		"",    # no username required,
		"",    # no pass required,
		{
			RaiseError => 1,
			PrintError => 0,
			# AutoCommit => 1
		},
	) or croak "can not connect to db";


	return $dbh;
}

sub build_tests_db {
	my $dbh = shift;


	my $sql_media_type = <<"SQL";
CREATE TABLE IF NOT EXISTS media_types (
	id INTEGER PRIMARY KEY,
	media_type VARCHAR(10) NOT NULL
);
SQL

	$dbh->do($sql_media_type);


	my $sql_media = <<"SQL";
CREATE TABLE IF NOT EXISTS media (
id INTEGER PRIMARY KEY,
name VARCHAR(255) NOT NULL,
location VARCHAR(255) NOT NULL,
source VARCHAR(511) NOT NULL,
attribution VARCHAR(255) NOT NULL,
media_type_id INTEGER NOT NULL,
license_id INTEGER NOT NULL,
FOREIGN KEY (media_type_id) REFERENCES media_types(id),
FOREIGN KEY (license_id)
REFERENCES licenses(id)
);
SQL

	$dbh->do($sql_media);

	my $sql_license = <<"SQL";
CREATE TABLE IF NOT EXISTS licenses (
	id INTEGER PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	allows_commercial BOOLEAN NOT NULL
);
SQL

	$dbh->do($sql_license);
	return;
}

sub populate_test_db {

	my $dbh = shift;

	my $sql_media_type = "INSERT INTO media_types (media_type) VALUES (?)";
	my $sth            = $dbh->prepare($sql_media_type);
	my %media_type_id_for;

	foreach my $type (qw/video audio image/) {
		$sth->execute($type);
		$media_type_id_for{$type} = $dbh->last_insert_id("", "", "", "");
	}


	my $sql_license = <<"SQL";
INSERT INTO licenses (name, allows_commercial)
VALUES ( ?, ? )
SQL

	$sth = $dbh->prepare($sql_license);


	my @licenses =
		(['Public Domain', 1], ['Attribution CC BY', 1], ['Attribution CC BY-SA', 1], ['Attribution-NonCommercial CC BY-NC', 0],);

	my %license_id_for;
	foreach my $license (@licenses) {
		my ($name, $allows_commercial) = @$license;
		$sth->execute($name, $allows_commercial);
		$license_id_for{$name} = $dbh->last_insert_id("", "", "", "");
	}

	my @media = ([
			'Anne Frank Stamp',                                            '/data/images/anne_fronk_stamp.jpg',
			'http://commons.wikimedia.org/wiki/File:Anne_Frank_stamp.jpg', 'Deutsche Post',
			$media_type_id_for{'image'},                                   $license_id_for{'Public Domain'},
		],
		[
			'Clair de Lune',                                                   '/data/audio/claire_de_lune.ogg',
			'http://commons.wikimedia.org/wiki/File:Sonate_Clair_de_lune.ogg', 'Schwarzer Stern',
			$media_type_id_for{'audio'},                                       $license_id_for{'Public Domain'},
		],
	);


	my $sql_media = <<'SQL';
INSERT INTO media (
name, location, source, attribution,
media_type_id, license_id
)
VALUES ( ?, ?, ?, ?, ?, ? )
SQL

	$sth = $dbh->prepare($sql_media);
	foreach my $media (@media) {
		$sth->execute(@$media);
	}

}

sub build_mysql_db {
	my $dbh = shift;

	my $sql_media_type = <<"SQL";
	CREATE TABLE IF NOT EXISTS media_types (
    id INT NOT NULL AUTO_INCREMENT,
    media_type VARCHAR(10) NOT NULL,
    PRIMARY KEY (id)
);
SQL

	$dbh->do($sql_media_type);

	my $sql_license = <<"SQL";
CREATE TABLE IF NOT EXISTS licenses (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    allows_commercial TINYINT(1) NOT NULL,
    PRIMARY KEY (id)
);
SQL

	$dbh->do($sql_license);

	my $sql_media = <<"SQL";
CREATE TABLE IF NOT EXISTS media (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    source VARCHAR(511) NOT NULL,
    attribution VARCHAR(255) NOT NULL,
    media_type_id INT NOT NULL,
    license_id INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (media_type_id) REFERENCES media_types(id),
    FOREIGN KEY (license_id) REFERENCES licenses(id)
);
SQL

	$dbh->do($sql_media);

	return 1;
}

1;
