require 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Acme-PricelessMethods',
    AUTHOR            => 'Jose Castro <cog@cpan.org>',
    VERSION_FROM      => 'lib/Acme/PricelessMethods.pm',
    PL_FILES          => { },
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean             => { FILES => 'Acme-PricelessMethods-*' },
);
