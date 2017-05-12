#!/usr/bin/perl  
  
  use Billing::Allopass;
  my $allopass=Billing::Allopass->new('session', 60);
  die "Error constructing class. Die" if ! $allopass;
  
# PALIER=4&SITE_ID= 21877 &DOC_ID= 56191  
  
  if ($allopass->check('21877/56338/363051', 'LaserJet6L')){
        print "OK\n";
  } else {
        print $allopass->get_last_error;
  }
  
  print "\n";