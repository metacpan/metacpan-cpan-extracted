use strict;
use warnings FATAL => 'all';

use DBI;

use Test::More;

my($dbname,$db,$user,$pass,$dbh);

BEGIN {
	$dbname	=	$ENV{DBD_MYSQL_DBNAME}	||	'test';
	$db		=	"dbi:mysql:$dbname";
	$user	=	$ENV{DBD_MYSQL_USER}	||	'';
	$pass	=	$ENV{DBD_MYSQL_PASS}	||	'';
	
	eval {
		$dbh = DBI->connect($db,$user,$pass,{RaiseError=>1}) or die;
		$dbh->do(qq[ DROP TABLE IF EXISTS artist ]);
		$dbh->do(qq[ CREATE TABLE artist (
			artistid	int(10) unsigned not null primary key auto_increment,
			name		char(255)) ]);
		$dbh->do(qq[ INSERT INTO artist (name) VALUES ('Apocryphal') ]);

		$dbh->do(qq[ DROP TABLE IF EXISTS cd ]);
		$dbh->do(qq[ CREATE TABLE cd (
			cdid	int(10) unsigned not null primary key auto_increment,
			artist	int(10) unsigned not null,
			title	char(255) not null,
			reldate	date not null
		) ]);
		$dbh->do(qq[ INSERT INTO cd (artist,title,reldate) VALUES (1,'First', '2001-01-01') ]);
		$dbh->do(qq[ INSERT INTO cd (artist,title,reldate) VALUES (1,'Second','2001-02-02') ]);

		$dbh->do(qq[ DROP TABLE IF EXISTS liner_notes ]);
		$dbh->do(qq[ CREATE TABLE liner_notes (
			cd		int(10) unsigned not null primary key,
			notes	text,
			stamp	timestamp
		) ]);
		$dbh->do(qq[ INSERT INTO liner_notes (cd,notes) VALUES (1, 'Liner Notes for First') ]);

		$dbh->do(qq[ DROP TABLE IF EXISTS time_table ]);
		$dbh->do(qq[ CREATE TABLE time_table (
			id					int(10) unsigned not null primary key auto_increment,
			artist 				int(10) unsigned not null,
			time_field time 	default '12:12:12',
			date_field date 	default '2005-01-01',
			datetime_field		datetime default '2005-01-01 12:12:12',
			timestamp_field		timestamp
		) ]);
		$dbh->do(qq[ INSERT INTO time_table (artist) VALUES (1) ]);
		
		$dbh->do(qq[ DROP TABLE IF EXISTS style ]);
		$dbh->do(qq[ CREATE TABLE style (
			styleid	int(10) unsigned not null primary key auto_increment,
			style	char(30) not null
		) ]);
		$dbh->do(qq[ INSERT INTO style (style) VALUES ('Blues'),('Funk'),('Country') ]);

		$dbh->do(qq[ DROP TABLE IF EXISTS style_ref ]);
		$dbh->do(qq[ CREATE TABLE style_ref (
			cd		int(10) unsigned not null,
			style	int(10) unsigned not null,
			primary key (cd,style)
		) ]);
		$dbh->do(qq[ INSERT INTO style_ref (cd,style) VALUES (1,1),(1,2),(1,3) ]);
	};
	plan $@ ? (skip_all => 'needs a mysql account with create/drop table privs') : (tests => 10);
}

# clean the db
END {
	$dbh->do(qq[ DROP TABLE IF EXISTS artist ]);
	$dbh->do(qq[ DROP TABLE IF EXISTS cd ]);
	$dbh->do(qq[ DROP TABLE IF EXISTS liner_notes ]);
	$dbh->do(qq[ DROP TABLE IF EXISTS time_table ]);
	$dbh->do(qq[ DROP TABLE IF EXISTS style ]);
	$dbh->do(qq[ DROP TABLE IF EXISTS style_ref ]);
};

BEGIN { use_ok('Class::DBI::Loader::mysql::Grok') };

# load the test db
#my $output = qx( mysql $dbname -h$host -u$user -p$pass < music.sql );

my $loader = Class::DBI::Loader->new(
	dsn             => $db,
	user            => $user,
	password        => $pass,
	options			=> {RaiseError=>1},
	constraint		=>	'^artist|cd|liner_notes|time_table|style|style_ref$',
	namespace       => "Music",
	relationships	=> 1,
#	debug			=> 1,
);


my $class  = $loader->find_class('cd'); # $class => Music::Cd
my $cd     = $class->retrieve(1);

# has_a
my $artist = $cd->artist;
ok($artist->name eq 'Apocryphal',"has_a: Music::Cd->artist");

# has_many
my($first_cd,$second_cd) = $cd->artist->cds;
ok($first_cd->title eq 'First',"has_many: Music::Artist->cds");

# might_have
ok($first_cd->notes eq 'Liner Notes for First',"might_have 1: Music::Cd->notes true");
ok(!$second_cd->notes,"might_have 2: Music::Cd->notes false");

# time:
# datetime
my($tt) = $artist->time_tables;
ok($tt->datetime_field->ymd eq '2005-01-01',"Time::Piece: datetime");
ok($tt->date_field->ymd eq '2005-01-01',"Time::Piece: date");
ok($tt->time_field->hms eq '12:12:12',"Time::Piece: time");
ok($tt->timestamp_field->hms =~ /^\d\d:\d\d:\d\d$/,"Time::Piece: timestamp");

# style_ref: mapping
ok(($cd->styles) == 3,"has_many mapping: Music::Cd->styles");

#qx( mysql $dbname < music_end.sql );

__END__




