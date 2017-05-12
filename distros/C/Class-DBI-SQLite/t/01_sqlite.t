use strict;
use Test::More tests => 42;
use lib 't/lib';

use Class::DBI::SQLite;

use Film;
Film->CONSTRUCT;

for my $i (1..10) {
    my $film = Film->create({
	title => "movie-$i",
	director => "director-$i",
    });
    isa_ok $film, 'Film';
    like $film->id, qr/\d+/, "id is " . $film->id;
    is $film->title, "movie-$i";
    is $film->director, "director-$i";
}

Film->dbi_commit;
Film->db_Main->disconnect;

my @movies = Film->retrieve_all;
is @movies, 10, '10 movies out there';

my %seen;
my @uniq = grep { !$seen{$_}++ } map $_->id, @movies;
is @uniq, 10, "10 unique ids - @uniq";

