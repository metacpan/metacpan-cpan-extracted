use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Authentication::Store::MongoDB',
    AUTHOR              => q{Altreus <altreus@cpan.org>},
    VERSION_FROM        => 'lib/Catalyst/Authentication/Store/MongoDB.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Authentication/Store/MongoDB.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'MIT')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Authentication-Store-MongoDB-*' },
);
