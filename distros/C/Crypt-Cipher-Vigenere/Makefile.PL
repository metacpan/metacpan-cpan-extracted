use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $lib_file = 'lib/Crypt/Cipher/Vigenere.pm';

sub extract_version {
    open my $F, '<', $lib_file or die $!;
    while (<$F>) {
        return $1 if /^our \$VERSION = '(.*)'/;
    }
}

my %WriteMakefileArgs = (
    NAME             => 'Crypt::Cipher::Vigenere',
    AUTHOR           => q{Borek Lupomesky <borekl@cpan.org>},
    VERSION_FROM     => 'lib/Crypt/Cipher/Vigenere.pm',
    ABSTRACT_FROM    => 'lib/Crypt/Cipher/Vigenere.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.020',
    META_MERGE       => {
   	'meta-spec' => { version => 2 },
	dynamic_config => 0,
	resources => {
		repository => {
			type => 'git',
			url => 'https://github.com/borekl/crypt-cipher-vigenere.git',
			web => 'https://github.com/borekl/crypt-cipher-vigenere'
		},
	},
        provides => {
                'Crypt::Cipher::Vigenere' => {
                        file => $lib_file,
                        version => extract_version(),
                }
        }
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test2::V0' => '0',
        'Test::More' => '0',
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Crypt-Cipher-Vigenere-*' },
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
