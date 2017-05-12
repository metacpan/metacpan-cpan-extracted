# $Id: Makefile.PL,v 1.7 2007/08/14 15:45:51 ajk Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT_FROM  => 'lib/Data/Passphrase.pm',
    AUTHOR         => 'Andrew J. Korty <ajk@iu.edu>',
    EXE_FILES      => [qw(scripts/passphrase-test)],
    NAME           => 'Data::Passphrase',
    PREREQ_PM      => {
        Apache::Request   => 1.2,
        Bloom::Filter     => 0.03,
        HTTP::Status      => 1.26,
        List::MoreUtils   => 0.19,
        Object::InsideOut => 1.33,
        Readonly          => 1.03,
        Test::More        => 0.54,
        version           => 0.53,
    },
    SIGN           => 1,
    VERSION_FROM   => 'lib/Data/Passphrase.pm',
);
