#!/usr/bin/perl -w

use BioX::SeqUtils::Promoter::Sequence;
use BioX::SeqUtils::Promoter::Sequences;
use BioX::SeqUtils::Promoter::SaveTypes::RImage;

my $tagged = BioX::SeqUtils::Promoter::Sequences->new();
my $rimage = BioX::SeqUtils::Promoter::SaveTypes::RImage->new();
my $base = [11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70];
my $base2 = [11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70];
my $color = ['red', 'red', 'red', 'blue', 'blue', 'blue', 'red' , 'red', 'red', 'red', 'blue', 'blue', 'blue', 'blue', 'blue', 'blue', 'red', 'red', 'red', 'blue', 'blue', 'blue', 'red' , 'red', 'red', 'red', 'blue', 'blue', 'blue', 'blue', 'blue', 'blue', 'red', 'red', 'red', 'red', 'red', 'red',  'red', 'red', 'red', 'red', 'red', 'red', 'red', 'red', 'red', 'blue', 'blue', 'blue', 'red' , 'red', 'red', 'red', 'blue', 'blue', 'blue'];
my $color2 = ['blue', 'blue', 'red', 'red', 'green', 'green', 'green', 'blue', 'blue', 'red', 'red', 'green', 'green', 'green', 'green', 'green', 'green', 'green', 'green', 'green', 'green', 'green', 'green', 'red' , 'red', 'red', 'red', 'blue', 'blue', 'blue', 'blue', 'blue', 'blue', 'blue', 'blue', 'red', 'red', 'green', 'green', 'green', 'blue', 'red', 'red', 'green', 'green', 'green', 'green', 'red' , 'red', 'red', 'red', 'blue', 'blue',  'green', 'green', 'green', 'green', 'green'];

my $DNA = 'CATATCTACTACTCTCACTAAGCTGATCGAGCTAGCTACGTAGCATCGATCGCTAGCTAG';
my $DNA2 = 'ACTTTTTCTAATCATATTTAATAGATGGGACGCGCGCGCGATCGATCGATCGATACTACT';

my $label =  'rab';
my $label2 =  'ras';

$tagged->add_sequence({sequence => $DNA, label => $label});
$tagged->set_color({bases => $base, colors => $color, label => $label});
$tagged->add_sequence({sequence => $DNA2, label => $label2});
$tagged->set_color({bases => $base2, colors => $color2, label => $label2});

#my $testing = save($tagged);
$rimage->save({sequences => $tagged->get_sequences()});
	
exit;
	


