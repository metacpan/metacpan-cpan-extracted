use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME         => 'Crypt::OFB',
	      VERSION_FROM => 'OFB.pm',
	      PREREQ_PM    => { 'Crypt::ECB'   => '0' },
	      'linkext'    => {LINKTYPE => ''},
	      'dist'       => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
