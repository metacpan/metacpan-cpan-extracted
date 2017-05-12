use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Crypt::FNA::Async',
    AUTHOR              => q{Mario Rossano <anak@cpan.org>},
    VERSION_FROM        => 'lib/Crypt/FNA/Async.pm',
    INSTALLDIRS         => 'site',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'NC-BY-SA')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Crypt::FNA' => 0.48,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Crypt-FNA-Async-*' },
);
