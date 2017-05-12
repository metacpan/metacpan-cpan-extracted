use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Bio::MAGE',
    'VERSION'           => '20030502.3',
    'PREREQ_PM'         => {Tie::IxHash=>1.21},
    ($] >= 5.005 ?
      (ABSTRACT         => 'Classes for MAGE-OM',
       AUTHOR           => q[The MAGE-Perl Hackers <mged-mage 'at' lists 'dot' sf 'dot' net>]) : ()),
);

