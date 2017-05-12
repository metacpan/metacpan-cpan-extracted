use strict;
use warnings;
use Test::More;
use AnnoCPAN::Config 't/config.pl';
use AnnoCPAN::DBI;

#plan 'no_plan';
plan tests => 20;

# delete all notes
AnnoCPAN::DBI::Note->retrieve_all->delete_all;

# select a distribution, pod, and section
my $distver  = AnnoCPAN::DBI::DistVer->retrieve(
    path => 'authors/id/A/AL/ALICE/My-Dist-0.10.tar.gz');
isa_ok ( $distver,  'AnnoCPAN::DBI::DistVer' );

my ($podver) = $distver->podvers;
isa_ok ( $podver,   'AnnoCPAN::DBI::PodVer' );

my $pod      = $podver->pod;
isa_ok ( $pod,      'AnnoCPAN::DBI::Pod' );

my $section  = AnnoCPAN::DBI::Section->retrieve(podver => $podver, pos => 6);
isa_ok ( $section,  'AnnoCPAN::DBI::Section' );

# create a note
my $note = AnnoCPAN::DBI::Note->create({
    pod         => $pod, 
    note        => 'hi, mom!',
    ip          => '123.123.123.123',
    time        => 1000000000,
    section     => $section,
});
wait;

isa_ok ( $note,     'AnnoCPAN::DBI::Note', 'new note' );

# count all the notes in the db
my @notes = AnnoCPAN::DBI::Note->retrieve_all;
is ( scalar @notes,     1,  'one note in the db' );

my @notepos = AnnoCPAN::DBI::NotePos->retrieve_all;
is ( scalar @notepos,     6,  'translated to every section' );

# try to post the same note again
my $dup_note = AnnoCPAN::DBI::Note->create({
    pod         => $pod, 
    note        => 'hi, mom!',
    ip          => '123.123.123.123',
    time        => 1000000001,
    section     => $section,
});

# it should have been rejected
ok ( !$dup_note,    'dup note' );

# "There can only be one"
@notes = AnnoCPAN::DBI::Note->retrieve_all;
is ( scalar @notes,     1,  'still one note in the db' );
@notepos = AnnoCPAN::DBI::NotePos->retrieve_all;
is ( scalar @notepos,     6,  'still only once per section' );


# test if the notes are assigned to the proper sections in other podvers
my %sections = (qw(
    authors/id/A/AL/ALICE/My-Dist-0.40.zip      7
    authors/id/A/AL/ALICE/My-Dist-0.50.tar.gz   6
    authors/id/A/AL/ALICE/My-Dist-0.10.tar.gz   6
    authors/id/A/AL/ALICE/My-Dist-0.20.tar.gz   6
    authors/id/A/AL/ALICE/My-Dist-0.30.tar.gz   7
    authors/id/B/BO/BOB/My-Dist-0.20.tar.gz     6
));

my @sections = $note->sections;
for my $sect (@sections) {
    my ($pos, $path) = ($sect->pos, $sect->podver->distver->path);
    is ( $pos, $sections{$path}, "notepos($path)" );
}

# delete the note
$note->delete;
@notes = AnnoCPAN::DBI::Note->retrieve_all;
is ( scalar @notes,     0,  'no notes left after deleting' );
@notepos = AnnoCPAN::DBI::NotePos->retrieve_all;
is ( scalar @notepos,     0,  'all links deleted' );

# create another note
$note = AnnoCPAN::DBI::Note->create({
    pod         => $pod, 
    note        => 'hello, world',
    ip          => '123.123.123.123',
    time        => 1000000002,
    section     => $section,
});
wait;

@notes = AnnoCPAN::DBI::Note->retrieve_all;
is ( scalar @notes,     1,  'one note in the db (again)' );
@notepos = AnnoCPAN::DBI::NotePos->retrieve_all;
is ( scalar @notepos,     6,  'once per section' );

