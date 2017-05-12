#/usr/bin/perl
use strict;
use warnings;
use feature 'say';

#
# Usage :
#  $ curl -s http:// .... .html | html2text > file.txt
#  $ ./freq.pl file.txt > words.txt
#

binmode(STDOUT, ":utf8");

sub usage {
   say './freq.pl file';
   exit;
}

sub load_stopwords {
    my $fh;
    open $fh, '<:utf8', './stop-words-fr.txt';
    my @L = <$fh>;
    close $fh;
    my @SWords;
    foreach my $l (@L) {
        push @SWords, split ('\W',$l) if $l && $l !~ m/#/;
    };
    return @SWords;
};


my $File = $ARGV[0];

&usage if !$File ;


open my $F, '<:utf8', $File or die $!;
my @L = <$F>;
close $F;

my @StopWords = &load_stopwords;


my %seen=();
foreach my $l (@L)
{
    foreach my $word ( split '\W', $l )
    {
        $word = lc($word);
        $word =~ s/[. ,]*$//; # strip off punctuation, etc.

        next if $word =~m /\d+/;
        if ( length $word > 2 && ! grep /^$word$/, @StopWords ) {        
            $seen{$word}++;
        }
    }
}

foreach my $word ( sort { $seen{$b} <=> $seen{$a} } keys %seen) {
    say $word.';'.$seen{$word};
}


