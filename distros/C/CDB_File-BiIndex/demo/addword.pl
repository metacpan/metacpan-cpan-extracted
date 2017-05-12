#!/usr/bin/perl

=head1 NAME

addword - add a word translation to the translators dictionary.

=head1 DESCRIPTION

This is a little sample program which will add a word to the
translators dictionary between English and Polish.  It demonstrates
how to correctly update the database.

=head1 FILES

This uses a BiIndex consisting of two files in the current directory:
english-polish and polish-english.

=head1 BUGS

Concurrent updates will interfere and one of them is guaranteed to be
lost (whichever one finishes first).  Furthermore, if the two
processes run at exactly the wrong times, the two directions could be
inconsistent until the next time the program is run.  Still, in the
end the database should be consistent and safe.

The program is very inefficient as designed.  Updates should be
batched together which means we should be able to give more than one
word at a time to the program.  As it is, we have to read through the
whole database for every single word we add...

=cut

my $english=shift;
my $polish=shift;
die "Give english followed by Polish.\n" unless $polish;
die "Give only two words (English then Polish\n" if @ARGV;

use CDB_File::BiIndex;
use CDB_File::BiIndex::Generator;

my $gen=new CDB_File::BiIndex::Generator "english-polish", "polish-english";
$gen->add_relation($english, $polish);

-e "english-polish" and do {
  my $old=new CDB_File::BiIndex "english-polish", "polish-english";
  my$key;
  for ($key=$old->first_first();
       defined $key;
       $key=$old->first_next() ) {
    $valref=$old->lookup_first($key);
    $gen->add_list_first($key, $valref);
  }
};
$gen->finish;
