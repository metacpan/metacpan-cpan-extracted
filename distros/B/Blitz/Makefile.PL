use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Blitz',
    AUTHOR              => q{Ben Klaas <ben@benklaas.com>},
    VERSION_FROM        => 'lib/Blitz.pm',
    ABSTRACT_FROM       => 'lib/Blitz.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'JSON::XS'  => '2.3',
        'MIME::Base64' => 0,
        'LWP' => 0,
        'Regexp::Common' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Blitz-*' },
);
