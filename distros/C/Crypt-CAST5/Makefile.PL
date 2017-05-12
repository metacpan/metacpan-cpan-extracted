require 5.004;
use ExtUtils::MakeMaker;

use Config;
my $gcc_x86 = ($Config{"ccname"} =~ /gcc/) && ($Config{"archname"} =~ /i.86/);

WriteMakefile(
    'NAME'		=> 'Crypt::CAST5',
    'VERSION_FROM'	=> 'CAST5.pm', # finds $VERSION
    'PREREQ_PM'		=> { Test::More => 0.47 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'CAST5.pm', # retrieve abstract from module
       AUTHOR     => 'Bob Mathews <bobmathews@alumni.calpoly.edu>') : ()),
    'DEFINE'            => ($gcc_x86 ? '-DGCC_X86' : ''),
    'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
