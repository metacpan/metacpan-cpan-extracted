use strict;

use Test::More;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 4);
}

package My::Film;

use base 'Class::DBI';
use Class::DBI::Plugin::RetrieveAll;

use File::Temp qw/tempfile/;
my (undef, $DB) = tempfile();
my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });

END { unlink $DB if -e $DB }

__PACKAGE__->set_db(Main => @DSN);
__PACKAGE__->table('Movies');
__PACKAGE__->columns(All => qw/id title year/);

sub CONSTRUCT {
	shift->db_Main->do(
		qq{
     CREATE TABLE Movies (
        id     INTEGER PRIMARY KEY,
        title  VARCHAR(255),
        year   INTEGER
     )
	}
	);
}

package main;

My::Film->CONSTRUCT;

my %films = (
	Veronique => 1991,
	Red       => 1994,
	White     => 1994,
	Blue      => 1993,
	Dekalog   => 1988,
	Hospital  => 1976,
	Heaven    => 2002,
);

while (my ($title, $year) = each %films) {
	My::Film->create({ title => $title, year => $year });
}

{
	my @films = My::Film->retrieve_all;
	is @films, 7, "Got 7 films";
}

{
	my @films = My::Film->retrieve_all_sorted_by('title');
	is_deeply [ map $_->title, @films ],
		[qw/Blue Dekalog Heaven Hospital Red Veronique White/], "Sorted by title";
}

{
	my @films = My::Film->retrieve_all_sorted_by('year, title DESC');
	is_deeply [ map $_->title, @films ],
		[qw/Hospital Dekalog Veronique Blue White Red Heaven/], "Compound sort";
}


My::Film->retrieve_all_sort_field('title');

{
	my @films = My::Film->retrieve_all;
	is_deeply [ map $_->title, @films ],
		[qw/Blue Dekalog Heaven Hospital Red Veronique White/], "Sorted by title";
}
