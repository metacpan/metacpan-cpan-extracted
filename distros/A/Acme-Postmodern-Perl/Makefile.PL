use 5.032;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Postmodern::Perl',
    AUTHOR              => q{Frank Wiegand <fwie@cpan.org>},
    VERSION_FROM        => 'lib/Acme/Postmodern/Perl.pm',
    ABSTRACT_FROM       => 'lib/Acme/Postmodern/Perl.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Postmodern-Perl-*' },
    MIN_PERL_VERSION    => 5.032,
);
