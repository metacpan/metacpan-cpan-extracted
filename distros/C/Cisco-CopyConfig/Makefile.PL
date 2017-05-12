use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'AUTHOR'		=> 'Aaron M. Scarisbrick <aaronsca@cpan.org>',
  'ABSTRACT'		=> 'IOS running-config manipulation',
  'NAME'		=> 'Cisco::CopyConfig',
  'VERSION_FROM'	=> 'CopyConfig.pm',
  'PREREQ_PM'		=> {
    'Socket'		=> 0,
    'Net::SNMP'		=> 0,
  }
);
