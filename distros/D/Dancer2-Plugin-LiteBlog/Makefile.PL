use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Dancer2::Plugin::LiteBlog',
    AUTHOR           => q{Alexis Sukrieh <sukria@gmail.com>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/LiteBlog.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/LiteBlog.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    
    EXE_FILES    => ['bin/liteblog-scaffold'],

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'DateTime' => 0,
        'File::Basename' => 0,
        'File::Path' => 0,
        'File::Slurp' => 0,
        'File::Spec' => 0,
        'File::Stat' => 0,
        'MIME::Base64' => 0,
        'Moo' => 0,
        'Path::Tiny' => 0,
        'Text::Markdown' => 0,
        'YAML::XS' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-LiteBlog-*' },
);


sub MY::postamble {
    return <<'EOM';

build_scaffolder:
	@perl -Ilib -Idist dist/build.pl

listdeps:
	@grep -r 'use' lib/ | sed -e 's/.*:\s*use //' | sed -e 's/;//' | grep -v 'LiteBlog' | sort -u

distdir: build_scaffolder

EOM
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

