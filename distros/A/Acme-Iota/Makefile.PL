use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Acme::Iota',
    AUTHOR => 'Christoph Gärtner <cygx@cpan.org>',
    LICENSE => 'open_source',
    VERSION_FROM => 'lib/Acme/Iota.pm',
    ABSTRACT_FROM => 'lib/Acme/Iota.pm',
    PREREQ_PM => { 'Test::More' => 0 },
);
