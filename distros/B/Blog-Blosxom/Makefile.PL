use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Blog::Blosxom',
    AUTHOR              => q{Altreus <altreus@perl.org>},
    VERSION_FROM        => 'lib/Blog/Blosxom.pm',
    ABSTRACT_FROM       => 'lib/Blog/Blosxom.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'x11')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Blog-Blosxom-*' },
);
