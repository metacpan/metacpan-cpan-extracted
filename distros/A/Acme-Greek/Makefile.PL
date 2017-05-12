use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME                => 'Acme::Greek',
	      AUTHOR              => 'Jonathan Rockway <jrockway@cpan.org>',
	      VERSION_FROM        => 'lib/Acme/Greek.pm',
	      ABSTRACT_FROM       => 'lib/Acme/Greek.pm',
	      PL_FILES            => {},
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Acme-Greek-*' },
	     );
