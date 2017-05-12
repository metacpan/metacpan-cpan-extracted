#!/usr/bin/perl -w

use BioX::SeqUtils::Promoter::Sequence;
use BioX::SeqUtils::Promoter::Sequences;
use BioX::SeqUtils::Promoter::Annotations;
use BioX::SeqUtils::Promoter::SaveTypes::RImage;

my $promoter = BioX::SeqUtils::Promoter::Sequences->new();
my $cpromoter = BioX::SeqUtils::Promoter::Annotations->new({ type => 'Consensus'});
my $rimage = BioX::SeqUtils::Promoter::SaveTypes::RImage->new();

my $test     = 'TTTTACGTACGTACGTGGACGCCACGTACGTACGTCCGCGCCACGTACGTACGTTATAAAAACGTACGTACGTTATATATACGTACGTACGTGGGCGGACGTACGTACGTGGCCAATCT';

my $label = 'TES';
my $base_length = length($test);
my $basel;

$promoter->add_sequence({sequence => $test, label => $label});

#print "$promoter->get_sequence()\n";

$cpromoter->set_reg({bases => $promoter});

#$rimage->save({sequences => $cpromoter->set_reg({bases => $promoter})});
$rimage->save({sequences => $promoter});
#$rimage->save({sequences => $promoter->get_sequences()});

print "\n";
exit;


