use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'DNS::Record::Check',
			  AUTHOR              => q{Zane C. Bowers <vvelox@vvelox.net>},
			  VERSION_FROM        => 'lib/DNS/Record/Check.pm',
			  ABSTRACT_FROM       => 'lib/DNS/Record/Check.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Test::More' => 0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'DNS-Record-Check-*' },
			  );
