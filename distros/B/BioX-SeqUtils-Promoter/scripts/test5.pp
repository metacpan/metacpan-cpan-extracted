#!/usr/bin/perl -w

use BioX::SeqUtils::Promoter::SaveTypes;

my $savetypes = BioX::SeqUtils::Promoter::SaveTypes->new({savetypes => 'RImage'});
  
$savetypes->print();

exit;


