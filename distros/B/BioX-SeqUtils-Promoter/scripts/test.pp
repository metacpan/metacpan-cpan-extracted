#!/usr/bin/perl -w

use BioX::SeqUtils::Promoter::Sequence;

my $promoter = BioX::SeqUtils::Promoter::Sequence->new();

$promoter->add_segment({sequence=>'GTACACTGC'});
$promoter->add_segment({sequence=>'GTACACTGC'});

print $promoter->get_sequence();
#print $base_list;


exit;


