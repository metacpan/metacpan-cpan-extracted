use strict;

use Test::More;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 7);
}

package My::Film;

use base 'Class::DBI';
use Class::DBI::Plugin::CountSearch;

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
	Jaws      => 1975,
	Manhatten => 1979,
	Network   => 1976,
	Rocky     => 1976,
	Nashville => 1975,
	Ape       => 1976,
	JFK       => 1991,
);

while (my ($title, $year) = each %films) {
	My::Film->create({ title => $title, year => $year });
}

{
	my @films = My::Film->retrieve_all;
	is @films, 14, "Got 14 films";
}

{
	my $count1976 = My::Film->count_search('year' => '1976');
	is $count1976, 4, "Got 4 1976 films";
}

{
	my $count1912 = My::Film->count_search('year' => '1912');
	is $count1912, 0, "Got 0 1912 films";
}

{
	my $count_h = My::Film->count_search_like('title' => 'H%');
	is $count_h, 2, "Got 2 H\% films";
}

{
	my $count_197x_h = My::Film->count_search_like('title' => 'H%', 'year' => '197_');
	is $count_197x_h, 1, "Got 1 H\% film in 197_";
}

{
	my $count_1994_red = My::Film->count_search('title' => 'Red', 'year' => '1994');
	is $count_1994_red, 1, "Got 1 1994 film called Red";
}

{
	my $total_count = My::Film->count_search();
	is $total_count, 14, "Got 14 search without terms";
}
