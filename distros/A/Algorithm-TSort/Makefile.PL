# vim: ft=perl sts=4 ts=8 sw=4 et ff=unix
use strict;
use ExtUtils::MakeMaker;
use constant MIN_PERL_VERSION => 5.007003;

if ( $] < MIN_PERL_VERSION ) {
    print "Perl $] not supported by this module\n";
    exit(0);
}

WriteMakefile(
    NAME          => 'Algorithm::TSort',
    VERSION_FROM  => 'lib/Algorithm/TSort.pm',         # finds $VERSION
    PREREQ_PM     => {},                               # e.g., Module::Name => 1.1
    ABSTRACT_FROM => 'lib/Algorithm/TSort.pm',         # retrieve abstract from module
    AUTHOR        => 'A. G. Grishaev <grian@cpan.org>',
    $ExtUtils::MakeMaker::VERSION >= 6.48 ? ( MIN_PERL_VERSION => MIN_PERL_VERSION ) : (),
    $ExtUtils::MakeMaker::VERSION >= 6.31 ? ( LICENSE          => 'perl' )           : (),
);
