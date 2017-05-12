use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


WriteMakefile(
    NAME                => 'Data::All',
    AUTHOR              => 'Delano Mandelbaum <delano@cpan.org>',
    VERSION_FROM        => 'lib/Data/All.pm',
    ABSTRACT_FROM       => 'lib/Data/All.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Text::ParseWords' => undef,
		'Class::Factory' => undef,
		'File::Spec' => undef,
		'Regexp::Common' => undef
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-All-*' },
);

