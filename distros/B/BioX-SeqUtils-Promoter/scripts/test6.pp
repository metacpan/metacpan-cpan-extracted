#!/usr/bin/perl -w

use BioX::SeqUtils::Promoter::Alignment;

my $Alignment = BioX::SeqUtils::Promoter::Alignment->new();
  
$Alignment->annotate();

exit;


