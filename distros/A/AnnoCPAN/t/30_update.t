use strict;
use warnings;
use Test::More;
use AnnoCPAN::Config 't/config.pl';
use AnnoCPAN::Dist;
use AnnoCPAN::Update;

#plan 'no_plan';
plan tests => 14;

AnnoCPAN::Update->run(cpan_root => 't/CPAN2');
ok(1, "Updated the database");

is ( AnnoCPAN::DBI::Dist->count_all,         3,  'dists' );
is ( AnnoCPAN::DBI::DistVer->count_all,      8,  'distvers' );
is ( AnnoCPAN::DBI::Pod->count_all,          3,  'pods' );
is ( AnnoCPAN::DBI::PodVer->count_all,       8,  'podvers' );
is ( AnnoCPAN::DBI::Section->count_all,      54, 'sections' );
is ( AnnoCPAN::DBI::NotePos->count_all,      6,  'notepos' );

# XXX check notepos...

# now again
AnnoCPAN::Update->run(cpan_root => 't/CPAN3');
ok(1, "Updated the database");

is ( AnnoCPAN::DBI::Dist->count_all,         2,  'dists' );
is ( AnnoCPAN::DBI::DistVer->count_all,      5,  'distvers' );
is ( AnnoCPAN::DBI::Pod->count_all,          2,  'pods' );
is ( AnnoCPAN::DBI::PodVer->count_all,       5,  'podvers' );
is ( AnnoCPAN::DBI::Section->count_all,      38,  'sections' );
is ( AnnoCPAN::DBI::NotePos->count_all,      4,  'notepos' );

# XXX check notepos...
