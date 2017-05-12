#!/usr/bin/perl

=head1 NAME 

transword - translate a word from specified language.

=head1 DESCRIPTION

This is a little sample program which will use the dictionary build up
by addword to translate words from the given language to the other
(English to polish or the other way round).

=head1 FILES

This uses a BiIndex consisting of two files in the current directory:
english-polish and polish-english.

=cut

use CDB_File::BiIndex;

my $language=shift;

# I'm not documenting it as okay to just swap round the two indexes,
# becuase I haven't thought carefully about when it might not be okay,
# but I can't see any circumstances that couldn't be avoided.


if ($language =~ m/^e/i) {
    $::index=new CDB_File::BiIndex "english-polish", "polish-english";
} elsif ($language =~ m/^p/i) {
    $::index=new CDB_File::BiIndex "polish-english", "english-polish";
} else {
    die "You must choose a language, English or Polish\n";
}

die "Give words to translate\n" unless @ARGV;

foreach (@ARGV) {
    my $translations_list = $::index->lookup_first($_);
    if ($translations_list) {
	print "$_ translates as:-\n  ";
	print join ("\n  ", @$translations_list), "\n\n";
    } else {
	print "$_ has no known translation\n";
    }
}

