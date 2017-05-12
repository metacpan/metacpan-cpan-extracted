#!/usr/bin/perl -w

use BioX::SeqUtils::Promoter::Alignment;
print "new \n";
my $alignment = BioX::SeqUtils::Promoter::Alignment->new();
print "load \n";

$alignment->load_alignmentfile({filename => $ARGV[0]});

exit;


