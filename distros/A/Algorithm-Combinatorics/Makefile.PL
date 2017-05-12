use strict;
use warnings;
use ExtUtils::MakeMaker;

# I copied this trick from Text::CSV_XS's Makefile.PL.
my $def = '';
$def .= '-Wall' if $ENV{"__RUNNING_IN_FXN_LAPTOP"};

WriteMakefile(
    NAME          => 'Algorithm::Combinatorics',
    AUTHOR        => 'Xavier Noria <FXN@cpan.org>',
    VERSION_FROM  => 'Combinatorics.pm',
    ABSTRACT_FROM => 'Combinatorics.pm',
    PREREQ_PM => {
        'XSLoader'     => 0,
        'FindBin'      => 0,
        'Test::More'   => 0,
        'Scalar::Util' => 0,
    },
    DEFINE => $def,
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'Algorithm-Combinatorics-*' },
);
