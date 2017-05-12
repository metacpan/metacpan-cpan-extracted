#!/usr/bin/perl -w

use BioX::SeqUtils::Promoter::Sequence;

my $tagged = BioX::SeqUtils::Promoter::Sequence->new();
my $base = [10,11,12,13,14,15,16];
my $color = ['red', 'red', 'red', 'blue', 'blue', 'blue', 'red'];

$tagged->set_color({bases => $base, colors => $color});
my $color_list = $tagged->get_color_list();
my $count = @$color_list;
for (my $i = 0; $i < $count; $i++) {
	my $colorthing = defined $color_list->[$i] ?  $color_list->[$i] : 'black';
	print $colorthing,  "\n";
}
	
exit;
	


