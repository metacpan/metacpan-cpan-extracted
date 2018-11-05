#!/usr/bin/env perl
use ExtUtils::MakeMaker 6.52;  # need >=6.52 for CONFIGURE_REQUIRES

# http://cpanwiki.grango.org/wiki/CPANAuthorNotes
# "How can I indicate that my distribution only works on a particular operating system?"
# -> die or BAIL_OUT with "OS unsupported" ==> NA
# "How can I stop getting FAIL reports for missing libraries or other non-Perl dependencies?"
# -> exit(0) from Makefile.PL before Makefile is written ==> UNKNOWN

use Imager ();  # is listed in CONFIGURE_REQUIRES below
print "# Imager at $INC{'Imager.pm'}\n";
print "# Imager::Font version $Imager::Font::VERSION\n";
if ( my @available = grep { $Imager::formats{$_} } qw/ tt t1 w32 ft2 / )
     { print "# Available Imager::Font formats are: ", join(', ', @available), "\n" }
else { print "# WARNING: No known Imager::Font formats are available!\n" }
if (not $Imager::formats{tt} || $Imager::formats{ft2} ) {
	if ($ENV{BADGE_SIMPLE_IGNORE_FONTLIBS}) {
		print "# Imager FreeType support is missing, but I am ignoring that because you told\n",
		      "# me to by setting the environment variable BADGE_SIMPLE_IGNORE_FONTLIBS.\n";
	}
	else {
		print <<'END_NOTICE';
# ##### NOTICE: Imager FreeType Support Missing #####
# This build of the Imager distribution does not have the FreeType 1.x (tt)
# or FreeType 2.x (ft2) support enabled, most likely becuase these libraries
# were not available or were disabled when the distribution was built. This
# means the default font included with Badge::Simple cannot be loaded and the
# module's tests will fail.
# If you still want to build this module, for example if you want to use
# a different font library or you plan to rebuild Imager, then you can ignore
# this issue by setting the environment variable BADGE_SIMPLE_IGNORE_FONTLIBS
# to a true value and running Makefile.PL again.
# ##### BAILING OUT #####
END_NOTICE
		exit 0;
	}
}

# and in CONFIGURE_REQUIRES, we require >=6.64 for TEST_REQUIRES
WriteMakefile(
	NAME           => 'Badge::Simple',
	AUTHOR         => 'Hauke D <haukex@zero-g.net>',
	LICENSE        => 'perl_5',
	VERSION_FROM   => 'lib/Badge/Simple.pm', # finds $VERSION
	ABSTRACT_FROM  => 'lib/Badge/Simple.pm',
	MIN_PERL_VERSION => '5.6.0',
	META_MERGE     => {
		'meta-spec'  => { version => 2 },
		provides     => {
			'Badge::Simple' => {
				file    => 'lib/Badge/Simple.pm',
				version => '0.04',
			},
		},
		resources    => {
			homepage    => 'https://github.com/haukex/Badge-Simple',
			repository  => {
				type       => 'git',
				url        => 'https://github.com/haukex/Badge-Simple.git',
				web        => 'https://github.com/haukex/Badge-Simple',
			},
			bugtracker  => {
				web        => 'https://github.com/haukex/Badge-Simple/issues',
				#mailto     => '',
			},
		},
		prereqs      => {
			runtime    => {
				recommends => { # "strongly encouraged and should be satisfied except in resource constrained environments"
				},
				suggests   => { # "optional, but are suggested for enhanced operation"
				},
			},
		},
	},
	EXE_FILES => [
		( $] ge '5.008' ? 'bin/badge' : () ),
	],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'    => '6.64',
		'Imager'                 => '1.000',
	},
	PREREQ_PM      => {
		# CPAN
		'Imager'                 => '1.000',
		'XML::LibXML'            => '2.0122',
		# Perl core modules
		'Carp'                   => 0,
		'Exporter'               => 0,
		'File::Basename'         => 0,
		'File::Spec::Functions'  => 0,
	},
	TEST_REQUIRES  => {
		# CPAN - none
		# Perl core modules
		'Test::More'             => '1.302096',
		'FindBin'                => 0,
		'File::Temp'             => 0,
		'File::Glob'             => 0,
		# note I haven't included modules needed for author tests here
	},
);
