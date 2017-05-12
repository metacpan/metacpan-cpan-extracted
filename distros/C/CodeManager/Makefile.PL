use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CodeManager',
    VERSION_FROM      => 'lib/Prima/CodeManager/CodeManager.pm',
    PREREQ_PM         => {
		Prima					=>	1.29,
		File::Path				=>	2.07,
		File::Copy				=>	2.13,
		File::Copy::Recursive	=>	0.38,
		File::HomeDir			=>	0.86,

    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Prima/CodeManager/CodeManager.pm',
       AUTHOR         => 'Waldemar Biernacki <wb@sao.pl>') : ()),
       LICENSE        => perl,
);
