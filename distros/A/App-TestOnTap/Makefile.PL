use 5.010_001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my $IS_WIN32 = $^O eq 'MSWin32';

my $downstream_requires =
	{
		# Config::Std reqs Class::Std and that wants MB >= 0.42 
		'Module::Build'						=>	0.42,
	};
	
my $configure_requires =
	{
		%$downstream_requires,
		'ExtUtils::MakeMaker' => '7.12', 
	};

my $test_requires =
	{
		# very old ones lack "done_testing()", and recent one changes a newline behavior
		'Test::Simple'	=>	1.302085,
		'Test::More'	=>	1.302085,
		'Capture::Tiny'	=>	0,			# initial dev used: 0.30
	};

my $eumm_understands_meta_merge = $ExtUtils::MakeMaker::VERSION ge '6.46';
my $eumm_understands_conf_and_test_requires_properly = $ExtUtils::MakeMaker::VERSION ge '7.12';

WriteMakefile(
    NAME             => 'App::TestOnTap',
    AUTHOR           => q{Kenneth Olwing <knth@cpan.org>},
    VERSION_FROM     => 'lib/App/TestOnTap.pm',
    ABSTRACT_FROM    => 'lib/App/TestOnTap.pod',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => 5.010_001, 
    EXE_FILES         => [ 'script/testontap' ],
	$eumm_understands_meta_merge
		? (
			META_MERGE =>
				{
					'meta-spec' =>
						{
							version => 2,
						},
					resources =>
						{
							repository =>
								{
									type => 'git',
									url => 'https://github.com/kenneth-olwing/App-TestOnTap.git',
									web => 'https://github.com/kenneth-olwing/App-TestOnTap'
								}
						},
					no_index =>
						{
							directory => [ 'extras', 'author' ],
						}
				}
			)
		: (),
	$eumm_understands_conf_and_test_requires_properly
		? ( CONFIGURE_REQUIRES => $configure_requires, TEST_REQUIRES => $test_requires )
		: (),
	PREREQ_PM =>
		{
			$eumm_understands_conf_and_test_requires_properly
				? ()
				: ( %$configure_requires, %$test_requires ),
			'Archive::Zip'						=>	1.47,	# 1.30 misbehaves in t\21-verify_saved_archive.t
			'Config'							=>  0,
			'Config::Std'						=>	0,		# initial dev used: 0.901
			'Cwd'								=>  0,
			'Exporter'							=>	0,		# initial dev used: 5.72
			'ExtUtils::Installed'				=>  0,
			'File::Basename'					=>	0,		# initial dev used: 2.85
			'File::Copy::Recursive'				=>	0,		# initial dev used: 0.38
			'File::Find'						=>	0,		# initial dev used: 1.27
			'File::Path'						=>	0,		# initial dev used: 2.12
			'File::Slurp'						=>	0,		# initial dev used: 9999.19
			'File::Spec'						=>	0,		# initial dev used: 3.48_01
			'File::Temp'						=>	0,		# initial dev used: 0.2304
			'FindBin'							=>	0,		# initial dev used: 1.51 
			'Getopt::Long'						=>	0,		# initial dev used: 2.47
			'Grep::Query'						=>	1.006,
			'JSON'								=>	0,		# initial dev used: 2.90
			'List::Util'						=>	0,		# Core 5.24
			'List::MoreUtils'					=>	0.428,	# Must have 'singleton'
			'LWP::Simple'						=>	0,		# initial dev used: 6.17
			'Net::Domain'						=>	0,		# initial dev used: 3.07
			'POSIX'								=>	0,		# initial dev used: 1.38_03
			'Pod::Simple::Search'				=>	0,		# initial dev used: 3.35 
			'Pod::Usage'						=>	0,		# initial dev used: 1.67
			'Sort::Naturally'					=>	0,		# initial dev used: 1.03
			'TAP::Formatter::Console'			=>	0,		# initial dev used: 3.35
			'TAP::Formatter::File'				=>	0,		# initial dev used: 3.35
			'TAP::Parser::Scheduler::Job'		=>	0,		# initial dev used: 3.35
			'TAP::Parser::Scheduler::Spinner'	=>	0,		# initial dev used: 3.35
			'UUID::Tiny'						=>	0,		# initial dev used: 1.04
		},
	dist  =>
		{
			$IS_WIN32 ? (TARFLAGS => '--mode=755 -cvf') : (),
			COMPRESS => 'gzip -9f',
			SUFFIX => 'gz',
			DIST_DEFAULT => 'alltest tardist'
		},
    clean => { FILES => 'App-TestOnTap-* *.tmp' },
	test => { RECURSIVE_TEST_FILES => 1 },
);

package MY;

sub postamble
{
	return <<'MAKE_FRAG';

XTEST_STANDARD_FILES = xt/standard/*.t
XTEST_AUTHOR_FILES = xt/author/*.t

# make test: runs all 't' tests (pre-provided by EUMM)
# make test_v: runs all 't' tests verbose
#
.PHONY : test_v

test_v : dynamic pure_all
	$(NOECHO) prove -lvr --merge $(TEST_FILES)

# make xtest: runs all 'xt' tests
# make xtest_v: runs all 'xt' tests verbose
#
.PHONY : xtest xtest_v

xtest : dynamic pure_all
	$(NOECHO) prove -lr --merge $(XTEST_STANDARD_FILES)

xtest_v : dynamic pure_all
	$(NOECHO) prove -lvr --merge $(XTEST_STANDARD_FILES)

# make authortest: runs all 'xt/author' tests
# make authortest_v: runs all 'xt/author' tests verbose
#
.PHONY : authortest authortest_v

authortest : dynamic pure_all
	$(NOECHO) prove -lr --merge $(XTEST_AUTHOR_FILES)

authortest_v : dynamic pure_all
	$(NOECHO) prove -lvr --merge $(XTEST_AUTHOR_FILES)

# make alltest: runs all tests
# make alltest_v: runs all tests verbose
#
.PHONY : alltest alltest_v

alltest : test xtest authortest
	$(NOECHO) $(NOOP)

alltest_v : test_v xtest_v authortest_v
	$(NOECHO) $(NOOP)

MAKE_FRAG
}
