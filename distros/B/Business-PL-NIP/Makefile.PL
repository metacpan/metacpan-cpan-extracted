use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
    NAME         => 'Business::PL::NIP',
    VERSION_FROM => 'lib/Business/PL/NIP.pm',
    PREREQ_PM    => {
        'Exporter::Easy' => 0,
        Carp             => 0,
        'List::Util'     => 0,
    },
    ABSTRACT      => 'NIP number validation',
    AUTHOR        => 'Tomasz Czepiel <tjmc@cpan.org>',
    LICENSE       => 'perl',
);
