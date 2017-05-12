use strict;
use warnings;
no warnings qw(uninitialized);
use Cwd;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw(GET_BODY GET_OK);
use Apache::Wyrd::Services::MySQLIndex;
my $directory = getcwd();
#Note -- This line is to silence some errors using Apache::Test v. 1.19
eval 'use lib $directory';
$directory = "$directory/t" if (-d 't');

my $index = undef;
my $dbh = undef;
my $count = &count;

eval <<'EVAL';
	use DBI;
	$dbh = DBI->connect('DBI:mysql:test', 'test', '');
EVAL

if ($@) {
	$count = 0;
	warn "Could not initialize a connection to database 'test': $@";
} elsif (!$dbh) {
	$count = 0;
	warn "DBI Connection failed to be opened.";
}

my $create_routine = <<"CREATE";
drop table if exists _wyrd_index;
create table _wyrd_index (
id integer not null auto_increment primary key,
name varchar(255) unique not null,
timestamp long,
digest char(40),
data blob,
wordcount integer,
title varchar(255),
keywords varchar(255),
description text,
regular varchar(255),
map varchar(255)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

drop table if exists _wyrd_index_data;
create table _wyrd_index_data (
item varchar(255) not null,
id integer,
tally integer
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

drop table if exists _wyrd_index_regular;
create table _wyrd_index_regular (
item varchar(255) not null,
id integer,
tally integer
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

drop table if exists _wyrd_index_map;
create table _wyrd_index_map (
item varchar(255) not null,
id integer,
tally integer
) ENGINE=MyISAM DEFAULT CHARSET=utf8
CREATE

for my $query (split ';', $create_routine) {
	last if ($count == 0);
	my $sh = $dbh->prepare($query);
	$sh->execute;
	if ($sh->err) {
		warn $sh->errstr;
		$count = 0;
	}
}

if (!$count) {
	warn <<'WARNING';

Could not initialize MySQL database.  Will skip on this platform.  To test,
make sure:

1. MySQL is installed and running
2. A user account for database test exists: test, and that it has no password
3. user account 'test' has sufficient privileges to create tables and insert
   data.
4. dbd::mysql is installed and working

WARNING
}

print "1..$count\n";

exit 0 if (!$count);

print "not " unless (GET_OK '/25.html');
print "ok 1 - Index creation\n";

eval {
	$index = Apache::Wyrd::Services::MySQLIndex->new({
	dbh => $dbh,
	attributes => [qw(regular map)],
	maps => [qw(map)],
	strict => 1,
	debug => 1
})};
$index->read_db;

print "not " if ($@);
print "ok 2 - Index tie\n";

print "not " unless (GET_OK '/25.html');
print "ok 3 - Indexable objects\n";

my $text = GET_BODY '/25.html';

my $found = $index->entry_by_name('one');

print "not " if (ref($found) ne 'HASH');
print "ok 4 - Lookup\n";

print "not " if ($found->{description} ne 'first');
print "ok 5 - Find by name\n";

print "not " if ($found->{regular} ne 'regular1');
print "ok 6 - Custom regular attribute\n";

my @found = $index->word_search('one');

print "not " if (@found != 2);
print "ok 7 - Find by word\n";

@found = $index->word_search('four', 'map');

print "not " if (@found != 2);
print "ok 8 - Find by custom map\n";

@found = $index->word_search('+one');

print "not " if (@found != 2);
print "ok 9 - Exclusive word search\n";

@found = $index->word_search('+one +more');

print "not " if (@found != 1);
print "ok 10 - Exclusive word search combined 1\n";

@found = $index->word_search('+one -more');

print "not " if (@found != 1);
print "ok 11 - Exclusive word search combined 2\n";

@found = $index->word_search('-one -more');

print "not " if (@found != 2);
print "ok 12 - Exclusive word search combined 3\n";

@found = $index->word_search('-one -more');

print "not " if (@found != 2);
print "ok 13 - Exclusive word search combined 4\n";

@found = $index->parsed_search('one AND more');

print "not " if (@found != 1);
print "ok 14 - Exclusive logical search 1\n";

@found = $index->parsed_search('one NOT more');

print "not " if (@found != 1);
print "ok 15 - Exclusive logical search 2\n";

@found = $index->parsed_search('this AND (another OR more)');

print "not " if (@found != 4);
print "ok 16 - Exclusive logical search 3\n";

@found = $index->parsed_search('NOT one NOT more');

print "not " if (@found != 2);
print "ok 17 - Exclusive logical search 4\n";

#$index->delete_index;
$found = $index->get_entry('one');

print "not " if ($found->{description});
print "ok 18 - Zero index\n";

sub count {18}
