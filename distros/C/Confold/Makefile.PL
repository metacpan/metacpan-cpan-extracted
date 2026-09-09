use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Confold provides the `<:` prefix operator. Core has no hook for a prefix
# symbolic operator, so `<:` is caught with the PL_infix_plugin hook used as a
# lexer trap and redirected into a keyword plugin. PL_infix_plugin arrived in
# perl 5.38, which is therefore the minimum -- there is no useful subset of the
# module below it.

my %WriteMakefileArgs = (
    NAME             => 'Confold',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Confold.pm',
    ABSTRACT_FROM    => 'lib/Confold.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.038',
    INC              => '-Iinclude',
    XS               => { 'Confold.xs' => 'Confold.c' },
    OBJECT           => 'Confold$(OBJ_EXT)',
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    },
    # MakeMaker tracks neither include/*.h nor INCLUDEd xs/*.xs, so edits to
    # the headers would otherwise not trigger a rebuild.
    depend => {
        'Confold$(OBJ_EXT)' => 'include/confold_compat.h include/xop_compat.h',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Confold-* Confold.c Confold$(OBJ_EXT)' },
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
