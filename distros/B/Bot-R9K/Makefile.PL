use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bot::R9K',
    AUTHOR              => q{Altreus <altreus@perl.org>},
    VERSION_FROM        => 'lib/Bot/R9K.pm',
    ABSTRACT_FROM       => 'lib/Bot/R9K.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'x11')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'List::MoreUtils' => 0,
        'POE' => 0,
        'POE::Component::IRC' => 0,
        'POE::Component::IRC::Plugin' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bot-R9K-*' },
);
