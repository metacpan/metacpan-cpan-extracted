use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~  /^push_to_GIT$/; # SKIP
    return $file;
}

my %WriteMakefileArgs = (
    NAME             => 'Data::Roundtrip',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Data/Roundtrip.pm',
    ABSTRACT_FROM    => 'lib/Data/Roundtrip.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    EXE_FILES		=> [qw|
	script/json2json.pl
	script/json2yaml.pl
	script/yaml2json.pl
	script/json2perl.pl
	script/perl2json.pl
	script/yaml2perl.pl
    |],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
	'Data::Random::Structure' => '0',
    },
    PREREQ_PM => {
	'Encode' => '0',
	'JSON' => '0',
	'Unicode::Escape' => '0',
	'YAML' => '0',
	'Sub::Override' => '0',
	'Data::Dumper' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Roundtrip-*' },
	# Thanks to marto @ Perlmonks.org
	# see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
    META_MERGE => {
        'meta-spec' => { version => 2 },
	requires    => { perl    => '5.10.0' },
        resources   => {
            license    => 'artistic_2',
	    homepage   => 'https://metacpan.org/module/Data::Roundtrip',
            repository => {
                url  => 'https://github.com/hadjiprocopis/data-roundtrip',
                web  => 'https://github.com/hadjiprocopis/data-roundtrip',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/hadjiprocopis/data-roundtrip/issues',
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
