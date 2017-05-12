use strict;
use warnings;
use Test::More;
use AnnoCPAN::Config 't/config.pl';
use AnnoCPAN::Dist;

#plan 'no_plan';
plan tests => 8;

is ( AnnoCPAN::DBI::Pod->count_all,          2,  'pods' );
is ( AnnoCPAN::DBI::PodDist->count_all,      2,  'pod_dists' );
is ( AnnoCPAN::DBI::NotePos->count_all,      4,  'notepos' );

my ($pod1, $pod2) = AnnoCPAN::DBI::Pod->search(name => 'My::Dist');

isa_ok ($pod1, 'AnnoCPAN::DBI::Pod');
isa_ok ($pod2, 'AnnoCPAN::DBI::Pod');

$pod1->join_pods($pod2);

is ( AnnoCPAN::DBI::Pod->count_all,          1,  'pods after join' );
is ( AnnoCPAN::DBI::PodDist->count_all,      2,  'pod_dists' );
is ( AnnoCPAN::DBI::NotePos->count_all,      5,  'notepos' );

