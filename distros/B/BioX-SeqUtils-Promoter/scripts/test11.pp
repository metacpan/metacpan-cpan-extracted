#!/usr/bin/perl -w

use BioX::SeqUtils::Promoter::Alignment;
#print "new \n";
my $alignment = BioX::SeqUtils::Promoter::Alignment->new();
#print "load \n";
$alignment->m_align({afilename => '/home/stephen/BioCapstone/BioX-SeqUtils-Promoter/data/nrab1000.txt'});
$alignment->load_alignmentfile({filename => '/home/stephen/BioCapstone/BioX-SeqUtils-Promoter/data/tnrab1000'});

exit;


