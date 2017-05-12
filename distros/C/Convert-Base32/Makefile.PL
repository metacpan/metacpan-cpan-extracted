use strict;
use warnings;

use ExtUtils::MakeMaker qw( WriteMakefile );

my %build_requires = (
    'Test::More'      => 0,  # For testing.
    'Test::Exception' => 0,  # For testing.
);

WriteMakefile(
    NAME          => 'Convert::Base32',
    VERSION_FROM  => 'lib/Convert/Base32.pm',
    ABSTRACT_FROM => 'lib/Convert/Base32.pm',

    ( $ExtUtils::MakeMaker::VERSION lt '6.56'
	? ( PREREQ_PM      => \%build_requires )
	: ( BUILD_REQUIRES => \%build_requires )
    ),

    dist  => { COMPRESS => 'gzip -9f' },
    clean => { FILES => 'Convert-Base32-*' },
);
