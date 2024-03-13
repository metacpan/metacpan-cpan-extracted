use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~  /^push_to_GIT$/; # SKIP the git dir
    return if $file =~ /\.lock.*$/; # SKIP editor files
    return $file;
}

my %WriteMakefileArgs = (
    NAME             => 'Config::JSON::Enhanced',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Config/JSON/Enhanced.pm',
    ABSTRACT_FROM    => 'lib/Config/JSON/Enhanced.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    EXE_FILES        => [
        'script/configjson2perl.pl',
        'script/configjson2json.pl',
        'script/configjson2yaml.pl',
    ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
	'Test2::Plugin::UTF8' => '0',
	'File::Temp' => '0',
	'File::Spec' => '0',
	'FindBin' => '0',
	'Cwd' => '0',
    },
    PREREQ_PM => {
	'Data::Roundtrip' => '0.16',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Config-JSON-Enhanced-*' },
    # Thanks to marto @ Perlmonks.org
    # see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
    META_MERGE => {
        'meta-spec' => { version => 2 },
	requires    => { perl    => '5.6.0' },
        resources   => {
            license    => 'artistic_2',
	    homepage   => 'https://metacpan.org/module/Config::JSON::Enhanced',
            repository => {
                url  => 'https://github.com/hadjiprocopis/Config-JSON-Enhanced',
                web  => 'https://github.com/hadjiprocopis/Config-JSON-Enhanced',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/hadjiprocopis/Config-JSON-Enhanced/issues',
            }
        },
    },
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
