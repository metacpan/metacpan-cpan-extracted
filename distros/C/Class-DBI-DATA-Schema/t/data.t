#!/usr/bin/perl -w

use strict;
use Test::More;

use lib 't/testlib';

BEGIN {
	eval "use DBD::SQLite; use SQL::Translator; use Digest::MD5";
	plan $@ 
		? (skip_all => 'needs DBD::SQLite, SQL::Translator and Digest::MD5 for testing') 
		: (tests => 10);
}

use_ok 'Class::DBI::DATA::Schema';

use_ok 'Film';
can_ok Film => 'run_data_sql';

ok Film->run_data_sql, "set up data";
is Film->retrieve_all, 1, "We have one film automatically set up";

my $gf = Film->create({ title => "The Godfather", rating => 18 });
ok my $fetch = Film->retrieve($gf->id), "Fetch back";
is $fetch->title, "The Godfather", " - title correct";

is Film->search(title => 'Veronique')->first->rating, 15, "Veronique";
is Film->search(title => 'The Godfather')->first->rating, 18, "Godfather";

eval { Film->run_data_sql };
like $@, qr/already exists/, "Running again causes an error";
