use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Authen::ModAuthToken',
    AUTHOR              => q{Assaf Gordon <gordon@cshl.edu>},
    VERSION_FROM        => 'lib/Authen/ModAuthToken.pm',
    ABSTRACT_FROM       => 'lib/Authen/ModAuthToken.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Test::More'  => 0,
        'URI::Escape' => 0,
        'Digest::MD5' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Authen-ModAuthToken-*' },
);
