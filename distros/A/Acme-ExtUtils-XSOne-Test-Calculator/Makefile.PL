use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Use ExtUtils::XSOne to combine multiple XS files into one
eval { require ExtUtils::XSOne };
if ($@) {
    die "ExtUtils::XSOne is required to build this module: $@";
}

# Combine XS files before WriteMakefile
# Output to root directory (standard location for XS)
# Use recursive mode to find XS files alongside .pm files
ExtUtils::XSOne->combine(
    src_dir   => 'lib/Acme/ExtUtils/XSOne/Test',
    output    => 'Calculator.xs',
    recursive => 1,
    verbose   => 1,
);

my %WriteMakefileArgs = (
    NAME             => 'Acme::ExtUtils::XSOne::Test::Calculator',
    AUTHOR           => ['lnation <email@lnation.org>'],
    VERSION_FROM     => 'lib/Acme/ExtUtils/XSOne/Test/Calculator.pm',
    ABSTRACT_FROM    => 'lib/Acme/ExtUtils/XSOne/Test/Calculator.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::XSOne'     => '0.02',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'Acme-ExtUtils-XSOne-Test-Calculator-* Calculator.xs Calculator.c Calculator.o' },
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

# Add a target to regenerate XS when source files change
sub MY::postamble {
    my @src_files = ExtUtils::XSOne->_find_xs_files_recursive('lib/Acme/ExtUtils/XSOne/Test');
    my $deps = join(' ', map { "lib/Acme/ExtUtils/XSOne/Test/$_" } @src_files);

    return <<"MAKE_FRAG";
Calculator.xs : $deps
\t\$(PERLRUN) -Ilib -MExtUtils::XSOne -e 'ExtUtils::XSOne->combine(src_dir => "lib/Acme/ExtUtils/XSOne/Test", output => "Calculator.xs", recursive => 1, verbose => 1)'
MAKE_FRAG
}
