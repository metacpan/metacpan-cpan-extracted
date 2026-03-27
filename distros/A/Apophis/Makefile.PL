use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $has_xsmulti = eval { ExtUtils::MakeMaker->VERSION('7.12'); 1 };

# Resolve Horus include directory:
#   1. Try installed Horus module (CPAN / system)
#   2. Fall back to sibling directory (development)
my $horus_inc;
eval {
    require Horus;
    my $dir = Horus->include_dir();
    $horus_inc = $dir if -d $dir;
};
if (!$horus_inc && -d '../Horus/include') {
    $horus_inc = '../Horus/include';
}
die "Cannot find Horus include directory. Install Horus or place it as a sibling directory.\n"
    unless $horus_inc;

my %WriteMakefileArgs = (
    NAME             => 'Apophis',
    AUTHOR           => 'LNATION <email@lnation.org>',
    VERSION_FROM     => 'lib/Apophis.pm',
    ABSTRACT_FROM    => 'lib/Apophis.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'Horus'               => '0',
    },
    BUILD_REQUIRES => {
        'Devel::PPPort' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
        'File::Temp' => '0',
    },
    PREREQ_PM => {},

    # Horus UUID library headers (resolved above)
    INC      => "-I$horus_inc",

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Apophis-* lib/*.o lib/*.c lib/*.bs' },
);

if ($has_xsmulti) {
    $WriteMakefileArgs{XSMULTI} = 1;
    $WriteMakefileArgs{XS}      = { 'lib/Apophis.xs' => 'lib/Apophis.c' };
    $WriteMakefileArgs{OBJECT}  = 'lib/Apophis$(OBJ_EXT)';
} else {
    $WriteMakefileArgs{XS}     = { 'lib/Apophis.xs' => 'lib/Apophis.c' };
    $WriteMakefileArgs{OBJECT} = 'lib/Apophis$(OBJ_EXT)';
}

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

sub MY::postamble {
    return '' if $has_xsmulti;
    return <<'MAKE';
lib/Apophis$(OBJ_EXT): lib/Apophis.c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $< -o $@
MAKE
}
