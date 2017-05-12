# Makefile.PL for Citrix Module
require 5.8.0;
use ExtUtils::MakeMaker;
# Test Presence of Net::Ping, output recommendation to have it
eval {require(Net::Ping);};
if ($@) {
   print("Dependency Problem: $@\n");
   print("Dont have Net::Ping (risk hanging)");
   exit(1);
} 
   
WriteMakefile(
  'NAME'         => 'Citrix',
  'VERSION_FROM' => 'Citrix.pm', # Citrix.pm
  'ABSTRACT'     => "Query and Control UNIX Citrix Sessions",
  'PL_FILES'     => {},
  #'INSTALLDIRS' => 'site',
  'AUTHOR'       => 'Olli Hollmen <ohollmen@broadcom.com>',
  
  #'EXE_FILES'  => [],
  
  'PREREQ_PM' => {
      'Test::More' => '0',
      #'Carp' => '0.01'.
      'Net::Ping' => 0,
      'Net::DNS' => 0,
  },
  dist              => {
     COMPRESS	=> 'gzip', #  -9
     SUFFIX	=> '.gz',
     #DIST_DEFAULT   => 'all tardist',
   },

);
