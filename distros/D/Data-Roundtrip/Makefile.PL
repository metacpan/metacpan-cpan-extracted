use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~  /^push_to_GIT$/; # SKIP the git dir
    return if $file =~ /\.lock$/; # SKIP editor files
    return $file;
}

my %WriteMakefileArgs = (
    NAME             => 'Data::Roundtrip',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Data/Roundtrip.pm',
    ABSTRACT_FROM    => 'lib/Data/Roundtrip.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008',
    EXE_FILES        => [
	'script/json2json.pl',
	'script/json2yaml.pl',
	'script/yaml2json.pl',
	'script/json2perl.pl',
	'script/perl2json.pl',
	'script/yaml2perl.pl'
    ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::Script' => '1.09',
        'Test::Pod' => '1.51',
        'Test::More' => '0',
        'Benchmark' => '0',
	'Data::Random::Structure' => '0',
	'Data::Random::Structure::UTF8' => '0.06',
    },
    PREREQ_PM => {
	'Encode' => '3.0',
	'JSON' => '4.0',
	'Unicode::Escape' => '0.0.2',
	'YAML' => '1.28',
	'Data::Dumper' => '0',
	'Data::Dump' => '0',
	'Data::Dump::Filtered' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Roundtrip-*' },
    postamble => {
        BENCHMARK_FILES => 'xt/benchmarks/*.b' },
	# Thanks to marto @ Perlmonks.org
	# see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
        META_MERGE => {
          'meta-spec' => { version => 2 },
	  requires    => { perl => '5.0.8' },
          resources   => {
            license    => 'artistic_2',
	    homepage   => 'https://metacpan.org/module/App::Appupdater',
            repository => {
                url  => 'https://github.com/hadjiprocopis/app-appupdater',
                web  => 'https://github.com/hadjiprocopis/app-appupdater',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/hadjiprocopis/app-appupdater/issues',
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

sub MY::postamble {
    my (undef,%h) = @_;
    require Data::Dumper;
    #print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    return "BENCHMARK_FILES=$h{BENCHMARK_FILES}\n"
	. <<'POSTAMBLE';
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

benchmarks :: $(BENCHMARK_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^
POSTAMBLE
}

