use strict;
use lib qw(t/lib);

use Test::More tests => 1;
use Music::DBI;

my @database = Music::DBI->databases;
my $count;


SKIP: {
	skip (Music::DBI->skip_message, 1) unless(Music::DBI->has_databases);

if(-e "./$database[0]"){
	unlink "./$database[0]" and $count++;
	unlink "./$database[1]" and $count++;
}

is($count,2);

}
