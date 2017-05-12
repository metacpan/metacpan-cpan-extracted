use strict;
use warnings;
use Test::More;
use AnnoCPAN::Config 't/config.pl';
use AnnoCPAN::Dist;
use AnnoCPAN::Update;

#plan 'no_plan';
plan tests => 7;

AnnoCPAN::Update->run;
ok(1, "Loaded the database");

is ( AnnoCPAN::DBI::Dist->count_all,         3,  'dists' );
is ( AnnoCPAN::DBI::DistVer->count_all,      8,  'distvers' );

# run again, to make sure we don't get duplicates
AnnoCPAN::Update->run;
is ( AnnoCPAN::DBI::DistVer->count_all,      8,  'distvers (reloaded)' );
is ( AnnoCPAN::DBI::Pod->count_all,          3,  'pods' );
is ( AnnoCPAN::DBI::PodVer->count_all,       8,  'podvers' );
is ( AnnoCPAN::DBI::Section->count_all,      52,  'sections' );


