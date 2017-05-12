#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Compress::Huffman;
my $ch = Compress::Huffman->new ();
my %symbols = (あ => 100, い => 200, う => 300, え => 400, お => 1000);
$ch->symbols (\%symbols, notprob => 1);
binmode STDOUT, ":encoding(utf8)";
my $msg = $ch->encode ([qw/あ い う え お/]);
print "Huffman encoding is $msg\n";
my $recovered = $ch->decode ($msg);
print "Recovered @$recovered\n";

