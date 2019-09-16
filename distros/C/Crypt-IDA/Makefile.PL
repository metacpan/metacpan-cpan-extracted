use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::IDA',
    VERSION_FROM      => 'lib/Crypt/IDA.pm', # finds $VERSION
    PREREQ_PM         => {
	'Math::FastGF2' => 0.07,
	'Class::Tiny' => 0,
    },
    ($] >= 5.005 ?     ## New keywords supported since 5.005
     (ABSTRACT_FROM  => 'lib/Crypt/IDA.pm',
      AUTHOR => 'Declan Malone <idablack@sourceforge.net>') : ()),
    EXE_FILES         => [ 'bin/rabin-combine.pl',
			   'bin/rabin-split.pl',
			   # I never got around to finishing these:
			   # 'bin/SplitCombine.xml',
			   # 'bin/SplitCombine.pl',
    ],
);
