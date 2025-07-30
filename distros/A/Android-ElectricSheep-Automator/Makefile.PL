use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~  /^push_to_GIT$/; # SKIP the git dir
    return if $file =~  /^tmp$/; # SKIP the git dir
    return if $file =~  /^bin$/; # SKIP the git dir
    return if $file =~  /^experiments$/; # private folder
    return if $file =~  /^doc$/; # private folder
    return if $file =~  /^forums$/; # private folder
    return if $file =~ /\.lock.*$/; # SKIP editor files
    return $file;
}

my %WriteMakefileArgs = (
    NAME             => 'Android::ElectricSheep::Automator',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Android/ElectricSheep/Automator.pm',
    ABSTRACT_FROM    => 'lib/Android/ElectricSheep/Automator.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    EXE_FILES        => [
	'script/electric-sheep-close-app.pl',
	'script/electric-sheep-dump-current-location.pl',
	'script/electric-sheep-dump-current-screen-ui.pl',
	'script/electric-sheep-dump-screen-shot.pl',
	'script/electric-sheep-dump-screen-video.pl',
	'script/electric-sheep-emulator-geofix.pl',
	'script/electric-sheep-find-installed-apps.pl',
	'script/electric-sheep-find-running-processes.pl',
	'script/electric-sheep-open-app.pl',
	'script/electric-sheep-viber-send-message.pl',
    ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
	'Test::More::UTF8' => '0',
	'Test::TempDir::Tiny' => '0',
	'FindBin' => '0',
	'Mojo::Log' => '0',
	'Data::Roundtrip' => '0.30',
    },
    PREREQ_PM => {
	'Mojo::Log' => '0',
	'Config::JSON::Enhanced' => '0',
	'Data::Roundtrip' => '0.30',
	#'Android::ADB' => '0.002', # we have it now
	'Text::ParseWords' => '0',
	'Class::Accessor::Fast' => '0',
	'XML::LibXML::XPathContext' => '0',
	'Cwd' => '0',
	'File::Temp' => '0',
	'FindBin' => '0',
	'XML::LibXML' => '0',
	'XML::XPath' => '0',
	'Time::HiRes' => '0',
	'Image::PNG' => '0',

	# by Android::ADB
	'Carp' => '0',
	'File::Slurp' => '0',
	'IPC::Open2' => '0',
	'IPC::Run' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Android-ElectricSheep-Automator-*' },
    postamble => {
        LIVE_TEST_FILES => 'xt/live/*.t',
    },
    # see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
    META_MERGE => {
          'meta-spec' => { version => 2 },
	  requires    => { perl => '5.0.10' },
          resources   => {
            license    => 'artistic_2',
	    homepage   => 'https://metacpan.org/module/Android::ElectricSheep::Automator',
            repository => {
                url  => 'https://github.com/hadjiprocopis/perl-android-electricsheep-automator',
                web  => 'https://github.com/hadjiprocopis/perl-android-electricsheep-automator',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/hadjiprocopis/perl-android-electricsheep-automator/issues',
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
    return "LIVE_TEST_FILES=$h{LIVE_TEST_FILES}\n"
	. <<'POSTAMBLE';
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

livetest :: $(LIVE_TEST_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^
POSTAMBLE
}
