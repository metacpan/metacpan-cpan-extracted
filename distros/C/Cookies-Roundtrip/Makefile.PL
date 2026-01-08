use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~ m!^bin/!; # SKIP the bin dir
    return if $file =~ m!^push_to_GIT/!; # SKIP the git dir
    return if $file =~ m!^experiments/!; # private folder
    return if $file =~ m!\.lock.*$!; # SKIP editor files
    return if $file =~ m!\.test-script-.*!; # SKIP editor files
    return $file;
}

my %WriteMakefileArgs = (
    NAME             => 'Cookies::Roundtrip',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Cookies/Roundtrip.pm',
    ABSTRACT_FROM    => 'lib/Cookies/Roundtrip.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
	'Data::Roundtrip' => '0.30',
	'FindBin' => '0',
	'HTTP::CookieJar' => '0',
	'HTTP::CookieJar::LWP' => '0',
	'HTTP::Cookies' => '0',
	'HTTP::Cookies' => '0',
	'HTTP::Request' => '0',
	'HTTP::Response' => '0',
	'Test::Deep' => '0',
	'Test::More::UTF8' => '0',
	'Test::TempDir::Tiny' => '0',
	'URI' => '0',
	'DateTime' => '0',
	'Firefox::Marionette' => '0',
	'Firefox::Marionette::Cookie' => '0',
	'HTTP::Date' => '0',
	'LWP::UserAgent' => '0',
	'WWW::Mechanize' => '0',
    },
    PREREQ_PM => {
	'DateTime' => '0',
	'HTTP::Date' => '0',
	'HTTP::Request' => '0',
	'autovivification' => '0',
	'Data::Roundtrip' => '0.30',
	'Exporter' => '0',
	'HTTP::CookieJar' => '0',
	'HTTP::Cookies' => '0',
	'Data::Compare' => '0',
	'HTTP::Headers::Util' => '0',
	'HTTP::Response' => '0',
	'Devel::StackTrace' => '0',
	'Firefox::Marionette::Cookie' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Cookies-Roundtrip-*' },
    postamble => {
	# Thanks to marto @ Perlmonks.org
	# see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
        META_MERGE => {
          'meta-spec' => { version => 2 },
	  requires    => { perl => '5.0.6' },
          resources   => {
            license    => 'artistic_2',
	    homepage   => 'https://metacpan.org/module/Cookies::Roundtrip',
            repository => {
                url  => 'https://github.com/hadjiprocopis/cookies-roundtrip',
                web  => 'https://github.com/hadjiprocopis/cookies-roundtrip',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/hadjiprocopis/cookies-roundtrip/issues',
            }
          }
        },
	LIVE_TEST_FILES => 'xt/live/*.t',
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
    my ($self, %h) = @_;

    my$retstr =
             "LIVE_TEST_FILES=$h{LIVE_TEST_FILES}\n" # add here all vars to go to Makefile
	. <<'POSTAMBLE';
    # the following will be appended to the MAKEFILE
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

livetest :: $(LIVE_TEST_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^


POSTAMBLE

    return $retstr;
}

