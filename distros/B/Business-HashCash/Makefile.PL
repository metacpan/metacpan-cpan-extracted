use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	      NAME                => 'Business::HashCash',
	      AUTHOR              => q{Ashish Gulhati <biz-hashcash at hash.neo.tc>},
	      VERSION_FROM        => 'lib/Business/HashCash.pm',
	      ABSTRACT_FROM       => 'lib/Business/HashCash.pm',
              LICENSE             => 'Artistic_2_0',
	      PL_FILES            => {},
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM           => {
				      'Crypt::HashCash' => 1.122,
				     },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Business-HashCash-*' },
	     );
