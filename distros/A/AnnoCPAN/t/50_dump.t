$| = 1;
use strict;
use warnings;
use Test::More;
use AnnoCPAN::Config 't/config.pl';
use AnnoCPAN::Dist;
use AnnoCPAN::Dump;

#plan 'no_plan';
plan tests => 5;

my $notepos_count = AnnoCPAN::DBI::NotePos->count_all;
my $note_count    = AnnoCPAN::DBI::Note->count_all;

my $file = 't/tmp/note_dump.xml';
AnnoCPAN::Dump->write_dump($file);

ok (-s $file, "file was dumped");

AnnoCPAN::DBI::Note->retrieve_all->delete_all;

is ( AnnoCPAN::DBI::Note->count_all,      0,   'deleted the notes; N(notes)=0');
is ( AnnoCPAN::DBI::NotePos->count_all,   0,   'N(notepos)=0');

AnnoCPAN::Dump->read_dump($file);

is ( AnnoCPAN::DBI::Note->count_all,      $note_count,   
    "undumped the notes; N(notes)=$note_count");
is ( AnnoCPAN::DBI::NotePos->count_all,   $notepos_count, 
    "undumped the notes; N(notes)=$notepos_count");

