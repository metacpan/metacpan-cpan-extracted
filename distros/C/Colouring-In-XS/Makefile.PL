use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $has_xsmulti = eval { ExtUtils::MakeMaker->VERSION('7.12'); 1 };

my %WriteMakefileArgs = (
    NAME             => 'Colouring::In::XS',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Colouring/In/XS.pm',
    ABSTRACT_FROM    => 'lib/Colouring/In/XS.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    INC    => '-I. -Iinclude',
    ($has_xsmulti
        ? (XSMULTI => 1)
        : (XS => { 'lib/Colouring/In/XS.xs' => 'lib/Colouring/In/XS.c' },
           OBJECT => 'XS$(OBJ_EXT)')
    ),
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Colouring-In-XS-* lib/Colouring/In/XS.c' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

package MY;

sub postamble {
    my $make = '';

    # Install the header alongside the module
    $make .= <<'HEADER';

pure_all :: $(INST_LIB)/Colouring/In/XS/include/colouring.h

$(INST_LIB)/Colouring/In/XS/include/colouring.h : include/colouring.h
	$(NOECHO) $(MKPATH) $(INST_LIB)/Colouring/In/XS/include
	$(NOECHO) $(CP) include/colouring.h $(INST_LIB)/Colouring/In/XS/include/colouring.h

HEADER

    # For old MakeMaker without XSMULTI: add rules for compiling the XS in lib/
    unless ($has_xsmulti) {
        $make .= <<'OLDMM';
lib/Colouring/In/XS.c : lib/Colouring/In/XS.xs
	$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) $< > $@

XS$(OBJ_EXT) : lib/Colouring/In/XS.c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -o $@ $<
OLDMM
    }

    return $make;
}
