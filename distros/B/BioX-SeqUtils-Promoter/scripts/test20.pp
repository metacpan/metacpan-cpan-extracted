#!/usr/bin/perl -w

use BioX::SeqUtils::Promoter::Annotations;
use BioX::SeqUtils::Promoter::Alignment;
use BioX::SeqUtils::Promoter::SaveTypes::RImage;
use BioX::SeqUtils::Promoter::Sequences;

my $promoter = BioX::SeqUtils::Promoter::Sequences->new();
my $alignment = BioX::SeqUtils::Promoter::Alignment->new();
my $cpromoter = BioX::SeqUtils::Promoter::Annotations->new({ type => 'Consensus'});
my $rimage = BioX::SeqUtils::Promoter::SaveTypes::RImage->new();


#$alignment->m_align({afilename => '/home/stephen/BioCapstone/BioX-SeqUtils-Promoter/data/cell_location/golgi.txt', matrix => 'BLOSUM', gap_open => 15, gap_ext => 2});
$alignment->m_align({afilename => '/home/stephen/BioCapstone/BioX-SeqUtils-Promoter/data/cell_location/endosomes.txt', matrix => 'BLOSUM', gap_open => -7, gap_ext => -1});
#$alignment->m_align({afilename => '/home/stephen/BioCapstone/BioX-SeqUtils-Promoter/data/nrab1000.txt', matrix => 'BLOSUM', gap_open => 15, gap_ext => 2});
$alignment->load_alignmentfile({filename => '/home/stephen/BioCapstone/BioX-SeqUtils-Promoter/data/tnrab1000'});

#$promoter->set_sequences($alignment);
$cpromoter->set_reg({bases => $alignment->get_sequences()});
print "test\n";
$rimage->save({sequences => $alignment->get_sequences()});
exit;

