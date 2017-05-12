package Film;

use strict;
use base 'Class::DBI';
use Class::DBI::DATA::Schema translate => ["MySQL" => "SQLite"];

use File::Temp qw/tempfile/;
my (undef, $DB) = tempfile();
my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });

END { unlink $DB if -e $DB }

__PACKAGE__->set_db(Main => @DSN);
__PACKAGE__->table('Film');
__PACKAGE__->columns(All => qw/filmid title rating/);

1;

__DATA__

CREATE TABLE film (
	filmid INTEGER AUTO_INCREMENT PRIMARY KEY,
	title VARCHAR(255),
	rating VARCHAR(5)
);
INSERT INTO film (title, rating) VALUES ("Veronique", 15);
