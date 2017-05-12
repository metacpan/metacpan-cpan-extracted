package dbixtest;
use strict;
use warnings;
use Exporter;

our @ISA= qw( Exporter );

our @EXPORT_OK = qw( dns user password create_table load_db get_db people crypt_salt prepare people_hash decrypt_arr get_conf);
our @EXPORT = qw( dsn user password create_table load_db get_db people crypt_salt prepare people_hash decrypt_arr get_conf);

sub dsn { 'dbi:SQLite:dbname=:memory:' }

sub user { 'root' }

sub password { '' }

sub create_table { 
	my ($db) = @_;
	$db->raw(query=>"CREATE TABLE dbix_raw ( id INTEGER PRIMARY KEY ASC, name varchar(255), age int, favorite_color varchar(255))");
	return 1;
}

sub people { 
	my $people_hash = people_hash();
	my @people;
	for(@$people_hash) { 
		push @people, [$_->{name}, $_->{age}, $_->{favorite_color}];
	}
	\@people;
}

sub people_hash { 
	[
		{ 
			id => 1,
			name => 'Adam',
			age => 21,
			favorite_color => 'blue',
		},	
		{ 
			id => 2,
			name => 'Dan',
			age => 23,
			favorite_color => 'green',
		},
	]
}

sub crypt_salt { 'xfasdfa8823423sfasdfalkj!@#$$CCCFFF!09xxxxlai3847lol13234408!!@#$_+-083dxje380-=0' }

sub load_db { 
	my ($db, $encrypt) = @_;

	my @encrypt_arr = ();
	if($encrypt) { 
		@encrypt_arr = qw/0 2/;
	}

	for(@{people()}) {
		$db->raw(query=>"INSERT INTO dbix_raw(name,age,favorite_color) VALUES(?, ?, ?)", vals => $_, encrypt => \@encrypt_arr);
	}
}

sub decrypt_arr { 
	['name', 'favorite_color'];
}

sub prepare { 
	my $encrypt = $_[0];
	my $db = get_db();
	create_table($db);
	load_db($db,$encrypt);
	return $db;
}

sub get_db { 
	return DBIx::Raw->new(conf => get_conf());
}

sub get_conf { 
	use strict;
	use Cwd 'abs_path';
	return abs_path('t/dbix_conf.pl');
}

1;
