use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Replace;
use File::Which;

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
    NAME             => 'Automate::Animate::FFmpeg',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Automate/Animate/FFmpeg.pm',
    ABSTRACT_FROM    => 'lib/Automate/Animate/FFmpeg.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    EXE_FILES        => [
        'script/automate-animate-ffmpeg.pl',
    ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
	'File::Replace' => '0',
	'File::Which' => '0',
    },
    BUILD_REQUIRES => {
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
	'Test2::Plugin::UTF8' => '0',
	'Test::Script' => '0',
        'FindBin' => '0',
        'Test::TempDir::Tiny' => '0',
        'File::Spec' => '0',
	'Data::Roundtrip' => '0',
	'Encode' => '0',
	'Cwd' => '0',
        'File::Basename' => '0',
    },
    PREREQ_PM => {
	'File::Temp' => '0',
	'IPC::Run' => '0',
	'Cwd::utf8' => '0',
	'File::Find::Rule' => '0',
	'Data::Roundtrip' => '0',
	'Text::ParseWords' => '0',
	'Encode' => '0',
	'Getopt::Long' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => [
		'Automate-Animate-FFmpeg-*',
		'.test-script-*',
		'pod2htmd.tmp'
    ] },
    postamble => {
        LIVE_FILES => 'xt/*.t'
    },
    # Thanks to marto @ Perlmonks.org
    # see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
    META_MERGE => {
          'meta-spec' => { version => 2 },
	  requires    => { perl => '5.0.8' },
          resources   => {
            license    => 'artistic_2',
	    homepage   => 'https://metacpan.org/module/Automate::Animate::FFmpeg',
            repository => {
                url  => 'https://github.com/hadjiprocopis/perl-Automate-Animate-FFmpeg',
                web  => 'https://github.com/hadjiprocopis/perl-Automate-Animate-FFmpeg',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/hadjiprocopis/perl-Automate-Animate-FFmpeg/issues',
            }
        },
    },
);

# check if the ffmpeg executable is found
# we understand AUTOMATE_ANIMATE_FFMPEG_PATH env var as well
# when found it will modify the package at lib/.../...pm
# and hardcode that path in there
my $ffmpeg_exe;
if( exists $ENV{AUTOMATE_ANIMATE_FFMPEG_PATH} ){
	if( -x $ENV{AUTOMATE_ANIMATE_FFMPEG_PATH} ){
		$ffmpeg_exe = Cwd::abs_path($ENV{AUTOMATE_ANIMATE_FFMPEG_PATH});
		print "ffmpeg executable was found after suggestion from env variable, it is located at $ffmpeg_exe\n"
	} else { print STDERR "ffmpeg executable was not found in the location suggested by the env variable 'AUTOMATE_ANIMATE_FFMPEG_PATH' : '".$ENV{AUTOMATE_ANIMATE_FFMPEG_PATH}."'.\n"; }
}
if( ! defined $ffmpeg_exe ){
	my @exes = File::Which::which('ffmpeg');
	if( not scalar @exes ){
		print STDERR "ffmpeg executable was not found after a search by which(). If you have it installed then set env variable 'AUTOMATE_ANIMATE_FFMPEG_PATH' to point to the executable's absolute path and re-run.\n";
	} elsif( scalar(@exes) > 1 ){
		my %dexes = @exes; # there may be duplicates, get rid of them
		if( scalar(keys %dexes) > 1 ){
			print STDERR "Warning, multiple ffmpeg executables were found after a search by which(): '".join("', '", @exes)."', the first one will be used: '".$exes[0]."'.\n";
		}
	} else {
		print STDOUT "ffmpeg executable was found after a search by which() at : '".$exes[0]."' and using it.\n";
	}
	$ffmpeg_exe = $exes[0];
}
if( ! defined $ffmpeg_exe ){
	print STDERR "============================================\n$0 : Warning, FFmpeg executable was not found anywhere in the path. If you have it installed, then set environment variable AUTOMATE_ANIMATE_FFMPEG_PATH to the executables's fullpath and rerun the make procedure. Or install it. \n============================================\n";
	# we are bailing out, no ffmpeg executable was found
	exit(1);
}

# we have found FFmpeg executable:
# hardcode the ffmpeg value into the package!
my ($infh,$outfh,$repl) = File::Replace::replace3('lib/Automate/Animate/FFmpeg.pm');
my $contents; { local $/ = undef; $contents = <$infh> }
$contents =~ s!\t\t# this will be modified during perl Makefile.PL\n\t\t'ffmpeg-executable'\s*=>\s*.*?\s*,?\s*#\s*specify fullpath if not in path\n\t\t# end this will be modified during perl Makefile.PL!\t\t# this will be modified during perl Makefile.PL\n\t\t'ffmpeg-executable' => '${ffmpeg_exe}', # specify fullpath if not in path\n\t\t# end this will be modified during perl Makefile.PL!;
print $outfh $contents;
$repl->finish; # it closes the filehandles too

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
    #require Data::Dumper; print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    return "LIVE_FILES=$h{LIVE_FILES}\n"
	. <<'POSTAMBLE';
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

livetests :: $(LIVE_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^
POSTAMBLE
}

