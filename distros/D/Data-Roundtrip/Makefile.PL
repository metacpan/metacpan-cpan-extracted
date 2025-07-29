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
	# we need at least v1.28 because of script_fails()
        'Test::Script' => '1.28',
	'Test::Taint' => '0',
        'Test::Pod' => '1.51',
        'Test::More' => '0',
	'Test2::Plugin::UTF8' => '0', # rids of the Wide Character in TAP message!
	'File::Spec' => '0',
	'File::Basename' => '0',
	'Test::TempDir::Tiny' => '0',
	# this has problems with YAML_PARSE_ERR_INCONSISTENT_INDENTATION
	# see https://github.com/ingydotnet/yaml-pm/issues/224
	#'YAML' => '0',
	# this works but needs compilation on M$
	#'YAML::XS' => '0',
	# this looks like the best choice right now
	'YAML::PP' => '0',
        'Benchmark' => '0',
	# WARNING (30.06.2023): CPAN tests fail when
	# Data::Random is not installed in their system.
	# We have no direct dependency on Data::Random.
	# I guess Data::Random::Structure must declare this dependency.
	'Data::Random::Structure' => '0',
	'Data::Random::Structure::UTF8' => '0.06',
	'Data::Dumper' => '0',
	'Data::Dump' => '0',
	'YAML' => '0',
	'YAML::XS' => '0',
    },
    PREREQ_PM => {
	'Exporter' => '0',
	'Encode' => '3.0',
	'JSON' => '4.0',
	'Unicode::Escape' => '0.0.2',
	'YAML::PP' => '0',
	'Data::Dumper' => '0',
	'Data::Dump' => '0',
	'Data::Dump::Filtered' => '0',
	'Getopt::Long' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Roundtrip-*' },
    postamble => {
        DEFICIENCIES_FILES => 'xt/deficiencies/*.t',
        BENCHMARK_FILES => 'xt/benchmarks/*.t',
    },
	# Thanks to marto @ Perlmonks.org
	# see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
        META_MERGE => {
          'meta-spec' => { version => 2 },
	  requires    => { perl => '5.0.8' },
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

sub MY::postamble {
    my (undef,%h) = @_;
    # require Data::Dumper; print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    return "BENCHMARK_FILES=$h{BENCHMARK_FILES}\n"
	 . "DEFICIENCIES_FILES=$h{DEFICIENCIES_FILES}\n"
	. <<'POSTAMBLE';
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

benchmarks :: $(BENCHMARK_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^

deficiencies :: $(DEFICIENCIES_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^
POSTAMBLE
}

