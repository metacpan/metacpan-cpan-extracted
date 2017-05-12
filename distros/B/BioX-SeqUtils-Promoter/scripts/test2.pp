#!/usr/bin/perl -w

use BioX::SeqUtils::Promoter::Sequence;

my $promoter = BioX::SeqUtils::Promoter::Sequence->new();

$promoter->add_segment({sequence=>'GTACACTGC'});
$promoter->add_segment({sequence=>'GTACACTGC'});

#$promoter->add_tag({tag=>'Rab2B'});

print "\n";
print $promoter->get_sequence();
print "\n";
#print $promoter->get_labels();

print "\n";
exit;


