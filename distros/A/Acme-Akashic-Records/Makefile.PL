use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Akashic::Records',
    AUTHOR              => q{Dan Kogai <dankogai+cpan@gmail.com>},
    VERSION_FROM        => 'lib/Acme/Akashic/Records.pm',
    ABSTRACT_FROM       => 'lib/Acme/Akashic/Records.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Akashic-Records-*' },
);
