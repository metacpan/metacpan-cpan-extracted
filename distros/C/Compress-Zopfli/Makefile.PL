# Copyright (c) 2017 Marcel Greter.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

################################################################################
# Based on https://github.com/sass/perl-libsass/
################################################################################

use 5.008000;
use Getopt::Long;
use ExtUtils::CppGuess;
use ExtUtils::MakeMaker;

# TIP: use `dmake -P#jobs` on windows

use strict;
use warnings;

################################################################################
# commandline options
################################################################################

# command line options
my $optimize = '-O3';
my $debug_mode = 0;
my $compiler = undef;
my $profiling = 0;
my $skip_manifest = 0;
my $update_deps = 0;
my $checkout_deps = 0;
my $skip_git = 0;

# arrays for various switches
my (@libs, @flags, @defs, @incs);

# start by adding the main incs
push @incs, '.', 'zopflib/src/zopfli';

sub help
{
	print "Compress::Zopfli Makefile.PL end-user options:\n\n";
	print "  --help               This help screen\n";
	print "\n  The following options are for developers only:\n\n";
	print "  --debug              Build zopfli in debug mode\n";
	print "  --profiling          Enable gcov profiling switches\n";
	print "  --compiler           Skips compiler autodetection (passed to CppGuess)\n";
	print "  --skip-manifest      Skips manifest generation (would need git repo)\n";
	print "  --update-deps        Update zopfli to latest master (needs git repo)\n";
	print "  --checkout-deps      Checkout submodules at linked commit (needs git repo)\n";
	print "  --get-versions       Show versions of all perl package (.pm) files\n";
	print "  --set-versions       Set versions of all perl package (.pm) files\n";
	print "  --skip-git           Do not try to use anything git related\n";
	exit 1;
}

my $re_vtoken = qr/v?([0-9]+\.[0-9]+\.[0-9]+(?:[\-_].+?)?)/;
my $re_version = qr/our\s+\$VERSION\s*=\s*[\"\']
                    $re_vtoken
                   [\"\']\s*\;/x;

################################################################################
# helper for version cli option
################################################################################

# needs File::Slurp
# no hard dependency!
sub versions
{
	my @files;
	my ($v) = @_;
	# only require when needed
	# avoids hard dependency
	require File::Slurp;
	my $tag = $v;
	my $ma = File::Slurp::read_file('MANIFEST', { 'binmode' => ':raw' });
	@files = grep { m/.pm$/i } split /\s*\r?\n/, $ma;
	# this optional step need git repo
	# when nothing is explicitly passed
	unless ($tag) {
		$tag = `git describe --abbrev=0 --always --tag`;
		$tag =~ s/(?:\A\s+|\Av|\s+\z)//g;
		unless ( $tag =~ m/(\d+\.\d+\.)(\d+)(?:[\-_]|\z)/ )
		{ warn "Tag <$tag> invalid (\\d+.\\d+.\\d+)\n"; return; }
		# increment the patch level
		else { $tag = $1 . ($2 + 1); }
	}
	$tag =~ s/(?:\A\s+|\Av|\s+\z)//g;
	if (scalar(@_)) {
		print "Update META.* and *.pm with new version <$tag>\n";
		unless ( $tag =~ m/(\d+\.\d+\.)(\d+)(?:[\-_]|\z)/ )
		{ warn "Tag <$tag> invalid (\\d+.\\d+.\\d+)\n"; return; }
		if (-e "META.yml") {
			my $metayml = File::Slurp::read_file("META.yml", { 'binmode' => ':raw' });
			if ($metayml =~ s/version\s*:\s*v($re_vtoken)/version: v$tag/i && $tag ne $1) {
				print "  update version in META.yml (was $1)\n";
				File::Slurp::write_file("META.yml", { 'binmode' => ':raw' }, $metayml);
			}
		}
		if (-e "META.json") {
			my $metajson = File::Slurp::read_file("META.json", { 'binmode' => ':raw' });
			if ($metajson =~ s/\"version\"\s*:\s*\"v($re_vtoken)\"/\"version\" : \"v$tag\"/i && $tag ne $1) {
				print "  update version in META.json (was $1)\n";
				File::Slurp::write_file("META.json", { 'binmode' => ':raw' }, $metajson);
			}
		}
		foreach my $filename (@files) {
			my $data = File::Slurp::read_file($filename, { 'binmode' => ':raw' });
			if ($data =~ s/$re_version/our \$VERSION = \"$tag\";/i) {
				next if $tag eq $1;
				print "  update version in $filename (was $1)\n";
				File::Slurp::write_file($filename, { 'binmode' => ':raw' }, $data);
			}
		}
	} else {
		foreach my $filename (@files) {
			my $data = File::Slurp::read_file($filename, { 'binmode' => ':raw' });
			print "  $filename (", ($data =~ m/$re_version/i ? $1 : "[NA]"), ")\n";
		}
	}
}

sub podcreate {
	# only require if needed
	# avoids hard dependency
	require FindBin;
	require File::Slurp;
	require Pod::Select;
	require Pod::Markdown;
	# get the files to convert/create relative to Makefile.PL
	my $pm_src = $FindBin::Bin . '/lib/Compress/Zopfli.pm';
	my $md_src = $FindBin::Bin . '/lib/Compress/Zopfli.md';
	my $pod_src = $FindBin::Bin . '/lib/Compress/Zopfli.pod';
	# Create pod from inline documentation in perl module
	Pod::Select::podselect({-output => $pod_src }, $pm_src);
	my $pod = File::Slurp::read_file($pod_src, { binmode => ':raw' });
	# print a message to the console
	warn "Created $pod_src\n" if $pod;
	# working with string did not seem to work with Pod::Markdown - invoke externaly!
	system "perl -MPod::Markdown -e \"Pod::Markdown->new->filter(\@ARGV)\" $pod_src > $md_src";
	# print a message to the console
	warn "Created $md_src\n" unless $?;
}


################################################################################
# parse options via GetOptions ("posix standard")
################################################################################

GetOptions(
	'--help' => \&help,
	'--debug!' => \$debug_mode,
	'--compiler:s' => \$compiler,
	'--profiling!' => \$profiling,
	'--skip-git!' => \$skip_git,
	'--skip-manifest!' => \$skip_manifest,
	# options for git submodules
	'--update-deps!' => \$update_deps,
	'--checkout-deps!' => \$checkout_deps,
	# manipulate versions of all perl packages
	'--pod-create!' => sub { podcreate(); exit 1; },
	'--get-versions' => sub { versions(); exit 1; },
	'--set-versions:s' => sub { versions($_[1]); exit 1; },
);

################################################################################
# some git helper utilities (devs only)
################################################################################

# declare git submodules that are used
my @submodules = qw(zopflib);

# Are we in our development tree?
# If so, create the MANIFEST file.
if (-d ".git" && !$skip_git)
{
	require Cwd;
	require File::Spec;
	my @modules = ('.');
	my $base = Cwd::getcwd;
	my ($dir, $manifest);
	# init and update git submodules
	foreach my $submodule (@submodules)
	{
		if (!-e "$submodule/.git" || $checkout_deps)
		{
			print "Checkout git submodule: $submodule\n";
			system "git submodule init \"$submodule\"";
			system "git submodule update \"$submodule\"";
			system "git -C \"$submodule\" fetch --tags";
		}
	}
	# create manifest file via git
	# also add files that we generate
	unless ($skip_manifest) {
		open $manifest, ">:encoding(UTF-8)", "MANIFEST";
		die "could not create MANIFEST: $!" unless $manifest;
		print $manifest "MANIFEST\n";
		while (my $module = shift @modules)
		{
			my $cwd = Cwd::getcwd;
			chdir ($module) or die "pushd: $!";
			my $files = "";
			if (-e ".git") {
				$files = `git ls-files` or
					die "Couldn't run git: $!";
			}
			my @items = split(/\n+/, $files);
			my @files = grep { ! -d } @items;
			print $manifest grep { ! /\"/ } # "
				map { tr/\\/\//; $_ . "\n" }
				map { File::Spec->abs2rel($_, $base) } @files;
			push @modules,
				map { File::Spec->catfile($module, $_) }
				grep { -d } @items;
			chdir ($cwd) or die "popd: $!";
		}
	}
	if ($update_deps)
	{
		foreach my $submodule (@submodules)
		{
			print "Update git submodule $submodule\n";
			system "git -C \"$submodule\" fetch";
			system "git -C \"$submodule\" fetch --tags";
			system "git -C \"$submodule\" pull --ff origin master";
		}
	}
}

################################################################################
# compiler configurations
################################################################################

my $guess = ExtUtils::CppGuess->new(
	(defined($compiler) ? (cc => $compiler) : ()),
);

# enable all warnings (disable only specific ones)
push @flags, '-Wall -Wextra -Wno-unused-parameter';

# enable optional debug mode
$optimize = '-O1' if $debug_mode;
push @defs, 'DEBUG' if $debug_mode;

# not sure why this does not work otherwise
push @flags, '-o $*.o' if ($guess->is_gcc);

# enable code profiling via gcov
$optimize = '-O1' if $profiling;
push @libs, '-lgcov' if $profiling;
push @libs, '-fprofile-arcs' if $profiling;
push @libs, '-ftest-coverage' if $profiling;
push @flags, '-fprofile-arcs' if $profiling;
push @flags, '-ftest-coverage' if $profiling;

# now add our custom flags
$guess->add_extra_linker_flags(join(' ', @libs));
$guess->add_extra_compiler_flags(join(' ', @flags));

# fetch the original compiler flags
my %compiler_flags = $guess->makemaker_options();

# cleanup some unnecessary whitespace
$compiler_flags{'CCFLAGS'} =~ s/^\s+//g;
$compiler_flags{'CCFLAGS'} =~ s/\s+$//g;
$compiler_flags{'CCFLAGS'} =~ s/\s+/ /g;

# disable all optimizations when doing code profiling
$compiler_flags{'CCFLAGS'} =~ s/\s*\-O[1-9]//g if $profiling;

# parse source files directly from zopfli makefile
open(my $fh, "<", "zopflib/Makefile");
die "zopflib/Makefile not found" unless $fh;
my $srcfiles = join "", <$fh>; close $fh;

my (@CFILES, @CPPFILES);
# parse variable out (this is hopefully tolerant enough)
if ($srcfiles =~ /^\s*ZOPFLILIB_SRC\s*=\s*((?:.*(?:\\\r?\n))*.*)/m) {
	@CFILES = grep { $_ } split /(?:\s|\\\r?\n)+/, $1;
} else { die "Did not find c++ CSOURCES in zopflib/Makefile"; }


# prefix paths and filter the c and c++ sources
my @SOURCES = map { join '/', 'zopflib', $_ }
              grep { s/\.c(?:pp)?$/\.o/ }
              (@CFILES, @CPPFILES);

# Fix an issue with EU::MM > 7.10 as reported in:
# https://github.com/sass/perl-libsass/issues/25
my $EMMV = $ExtUtils::MakeMaker::VERSION;
# Bug has been fixed in version 7.20
if ($EMMV > 7.10 && $EMMV < 7.20) {
	# Fix another issue if as-needed is not supported
	# https://github.com/sass/perl-libsass/issues/26
	unless (`ld --help` =~ /--no-as-needed/) {
		warn "Your current ExtUtils::MakeMaker has a bug\n";
		die "You need to upgrade ExtUtils::MakeMaker to 7.20+\n";
	}
	if (exists $compiler_flags{'dynamic_lib'}) {
		my $dynlibs = $compiler_flags{'dynamic_lib'};
		if (exists $dynlibs->{'OTHERLDFLAGS'}) {
			if ($guess->is_gcc) {
				$dynlibs->{'OTHERLDFLAGS'} = join " ",
					'-Wl,--no-as-needed',
					$dynlibs->{'OTHERLDFLAGS'},
					'-Wl,--as-needed';
			}
		}
	}
}

################################################################################
# See lib/ExtUtils/MakeMaker.pm for details of how to
# influence content of the Makefile that is written.
################################################################################

my %WriteMakefile = (
	NAME               => 'Compress::Zopfli',
	# finds $VERSION, requires EU::MM from perl >= 5.5
	VERSION_FROM       => 'lib/Compress/Zopfli.pm',
	# runtime dependencies
	PREREQ_PM          => {
		# 'perl'                 => 5.008000,
		'Carp'                 => 1.01, # core as of 5.008
		'version'              => 0,
		'warnings'             => 0, # core as of 5.008
		'strict'               => 0, # core as of 5.008,
		'Getopt::Long'         => 0.01,
	},
	# test dependencies
	TEST_REQUIRES      => {
		'IO::Uncompress::Gunzip' => 0,
		'IO::Uncompress::Inflate' => 0,
		'IO::Uncompress::RawInflate' => 0,
	},
	# build dependencies
	BUILD_REQUIRES     => {
		'Getopt::Long'         => 0.01,
		'ExtUtils::CppGuess'   => 0.09,
		'ExtUtils::MakeMaker'  => 6.52,
	},
	# build dependencies
	CONFIGURE_REQUIRES => {
		'Getopt::Long'         => 0.01,
		'ExtUtils::CppGuess'   => 0.09,
		'ExtUtils::MakeMaker'  => 6.52,
	},
	# additional information
	META_MERGE => {
		resources => {
			license     => 'http://opensource.org/licenses/MIT',
			homepage    => 'https://metacpan.org/release/Compress-Zopfli',
			bugtracker  => 'https://github.com/mgreter/perl-zopfli/issues',
			repository  => 'https://github.com/mgreter/perl-zopfli',
		},
	},
	# retrieve abstract from module
	ABSTRACT_FROM      => 'lib/Compress/Zopfli.pm',
	AUTHOR             => q{Marcel Greter <compress-zopfli@ocbnet.ch>},
	LICENSE            => 'MIT',
	# options are set by CppGuess
	# LIBS               => [''],
	# CCFLAGS            => '',
	# LDDLFLAGS          => '',
	INC                => join(" ", map { sprintf "-I%s", $_ } @incs),
	DEFINE             => join(" ", map { sprintf "-D%s", $_ } @defs),
	%compiler_flags,
	OPTIMIZE           => $optimize,
	TYPEMAPS           => [ 'perlobject.map' ],
	OBJECT             => join(" ", (@SOURCES), '$(O_FILES)'),
	# EXE_FILES          => [ 'bin/pzopfli' ],
);

# remove unknown key (as seen in Dist::Zilla)
unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
	delete $WriteMakefile{TEST_REQUIRES};
	delete $WriteMakefile{BUILD_REQUIRES};
	# $WriteMakefile{PREREQ_PM} = \%fallback;
}

# remove unknown key (as seen in Dist::Zilla)
unless ( eval { ExtUtils::MakeMaker->VERSION(6.52) } ) {
	delete $WriteMakefile{CONFIGURE_REQUIRES}
}

# See lib/ExtUtils/MakeMaker.pm for details of how to
# influence content of the Makefile that is written.
WriteMakefile(%WriteMakefile);
