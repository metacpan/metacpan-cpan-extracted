#!/usr/bin/perl -w

use BioX::SeqUtils::Promoter::Sequence;
use BioX::SeqUtils::Promoter::Sequences;

my $tagged = BioX::SeqUtils::Promoter::Sequences->new();
my $base = [10,11,12,13,14,15,16];
my $base2 = [17,18,19,20,21,22,23];
my $color = ['red', 'red', 'red', 'blue', 'blue', 'blue', 'red'];
my $color2 = ['blue', 'blue', 'red', 'red', 'green', 'green', 'green'];
my $label =  ['rab2B'];
my $label2 =  ['rabG'];
my $DNA = 'TATATTA';
my $DNA2 = 'CGCTAGG';

$tagged->add_sequence({sequence => $DNA, label => $label});
$tagged->set_color({bases => $base, colors => $color, label => $label});
$tagged->add_segment({sequence => $DNA2, label => $label2});
$tagged->set_color({bases => $base2, colors => $color2, label => $label2});

my $seqs = $tagged->get_sequences();
my @seqs = values %$seqs;

#print each sequence from each object from the sequences object
foreach my $seqobj (@seqs) {  
	my $color_list = $seqobj->get_color_list();
	my $count = @$color_list;
	print "\n";
	for (my $i = 0; $i < $count; $i++) {
		my $colorthing = defined $color_list->[$i] ?  $color_list->[$i] : 'black';
		print $colorthing,  "\n";
	}
}
	
exit;
	


