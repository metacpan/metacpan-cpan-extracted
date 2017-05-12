# Module makefile for Bundle::Thread (using ExtUtils::MakeMaker)

require 5.008;

use strict;
use warnings;

use ExtUtils::MakeMaker;

# Construct make file
WriteMakefile(
    'NAME'          => 'Bundle::Thread',
    'AUTHOR'        => 'Jerry D. Hedden <jdhedden AT cpan DOT org>',
    'VERSION_FROM'  => 'Thread.pm',
    'ABSTRACT_FROM' => 'Thread.pm',

    ((ExtUtils::MakeMaker->VERSION() lt '6.25') ?
        ('PL_FILES' => { })            : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),
);

# Additional 'make' targets
sub MY::postamble
{
    return <<'_EXTRAS_';
fixfiles:
	@dos2unix `cat MANIFEST`
	@$(CHMOD) 644 `cat MANIFEST`
_EXTRAS_
}

# EOF
