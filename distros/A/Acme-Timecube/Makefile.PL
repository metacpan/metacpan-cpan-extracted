use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Timecube',
    AUTHOR              => q{Luke Poskitt <ltp@cpan.org>},
    VERSION_FROM        => 'lib/Acme/Timecube.pm',
    ABSTRACT_FROM       => 'lib/Acme/Timecube.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'HTML::TreeBuilder' => 0,
	'LWP::UserAgent' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Timecube-*' },
);
