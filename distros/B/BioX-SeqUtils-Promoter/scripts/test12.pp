#!/usr/bin/perl -w

use BioX::SeqUtils::Promoter::Alignment;
use BioX::SeqUtils::Promoter::SaveTypes::RImage;
#print "new \n";
my $alignment = BioX::SeqUtils::Promoter::Alignment->new();
#print "load \n";
my $rimage = BioX::SeqUtils::Promoter::SaveTypes::RImage->new();

$alignment->m_align({afilename => '/home/stephen/BioCapstone/BioX-SeqUtils-Promoter/data/nrab1000.txt'});
$alignment->load_alignmentfile({filename => '/home/stephen/BioCapstone/BioX-SeqUtils-Promoter/data/tnrab1000'});

####line from test10.pp
#$rimage->save({sequences => $tagged->get_sequences()});

$rimage->save({sequences => $alignment->get_sequences()});
exit;


