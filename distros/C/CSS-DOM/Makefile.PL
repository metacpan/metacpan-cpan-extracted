BEGIN { require 5.008002 } # In 5.8.1, sub {} means sub {@_}
use strict;
use ExtUtils::MakeMaker;

my %prq = (
	 Carp                         => 1.01, # @CARP_NOT
	 Clone                        =>  .09, # coderefs
	 constant                     => 1.03, # multiple at once
	 Encode                       => 2.1,  # LEAVE_SRC
	 Exporter                     => 5.57, # use Exporter 'import';
	 overload                     => 0,
	 re                           => 0,
	'Scalar::Util'                => 0,
	 strict                       => 0,
	 warnings                     => 0,
# for testing only:
	'Scalar::Util'                => 1.09, # refaddr
	'Test::More'                  => 0,
);


WriteMakefile(
    NAME           => 'CSS::DOM',
    AUTHOR         => 'Father Chrysostomos <sprout & cpan . org>',
    VERSION_FROM   => 'lib/CSS/DOM.pm',
    ABSTRACT_FROM  => 'lib/CSS/DOM.pm',
    LICENSE        => 'perl',
    PL_FILES       => {},
    PREREQ_PM      => \%prq,
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                        TAR => 'COPYFILE_DISABLE=1 tar' },
    clean          => { FILES => 'CSS-DOM-*' },
);
