use strict;
use warnings;

use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

# mdbtools are external programs, not Perl modules, so CPAN cannot install
# them.  Say so now if they are missing - but do not fail: they may be
# installed later, and failing here would make CPAN testers report "NA".
# (Core Perl only: File::Which is not installed yet at this point.)
{
	require Config;
	require File::Spec;
	my @missing = grep {
		my $program = $_;
		!grep {
			my $dir = $_;
			grep { -f $_ && -x _ } map { File::Spec->catfile($dir, "$program$_") } ('', '.exe');
		} File::Spec->path();
	} qw(mdb-tables mdb-export);
	if(@missing) {
		print "NOTE: access2csv needs the mdbtools programs, which were not found in PATH\n",
			"\t(missing: @missing).  Install mdbtools with your package manager,\n",
			"\te.g. 'sudo apt install mdbtools' or 'brew install mdbtools'.\n";
	}
}

WriteMakefile(
	NAME         => 'App::Access2CSV',
	VERSION_FROM => 'lib/App/Access2CSV.pm',
	ABSTRACT_FROM => 'lib/App/Access2CSV.pm',
	AUTHOR       => 'Nigel Horne <njh@nigelhorne.com>',
	# 5.14: the // operator, local $@ that survives croak, s///r and
	# "package NAME { }" (the last two in the tests)
	MIN_PERL_VERSION => '5.014',
	EXE_FILES => [ 'bin/access2csv', ],
	PREREQ_PM => {
		'autodie'      => 0,
		'Carp'         => 0,
		'Config'       => 0,
		'Encode'       => 0,
		'Fcntl'        => 0,
		'File::Path'   => 0,
		'File::Spec'   => 0,
		'File::Temp'   => 0,
		'File::Which'  => 0,
		'Getopt::Long' => 0,
		'IPC::Run3'    => 0,
		'IPC::System::Simple' => 0,	# needed by autodie qw(:all)
		'Log::Abstraction' => 0,
		'Params::Get'  => 0,
		'Params::Validate::Strict' => 0.40,
		'parent'       => 0,
		'Pod::Usage'   => 0,
		'Readonly'     => 0,
		'Return::Set'  => 0,
		'Scalar::Util' => 0,
		'Sub::Private' => 0.05,	# first version with enforce mode
		'Sub::Protected' => 0,
	}, TEST_REQUIRES => {
		'Capture::Tiny' => 0,
		'Cwd'          => 0,
		'Errno'        => 0,
		'Exporter'     => 0,
		'File::Copy'   => 0,
		'FindBin'      => 0,
		'POSIX'        => 0,
		'Storable'     => 0,
		'Time::HiRes'  => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0.13,	# mock_scoped multi-method form
		'Test::Most'   => 0,
		'Test::Returns' => 0,
		'Test::Without::Module' => 0,
	},
	LICENSE => 'gpl_2',
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/nigelhorne/App-access2csv.git',
				web  => 'https://github.com/nigelhorne/App-access2csv',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-access2csv',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-access2csv',
				# web => 'https://github.com/nigelhorne/App-access2csv/issues',
				# url => 'https://github.com/nigelhorne/App-access2csv/issues',
				mailto => 'bug-App-access2csv@rt.cpan.org'
			},
		}, prereqs => {
			test => {
				# Only for the "standard input is a terminal" tests,
				# which are skipped without it
				recommends => { 'IO::Pty' => 0 },
			},
		},
	},
	clean => { FILES => 'App-access2csv-*' },
	dist => $dist,
);
