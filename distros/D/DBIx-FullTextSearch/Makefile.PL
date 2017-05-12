
use strict;
use ExtUtils::MakeMaker;
use Data::Dumper;
use DBI;

# see if mysql driver is available
unless (grep /mysql/, DBI->available_drivers) {
  die "DBIx::FullTextSearch requires DBD::mysql - see README for details";
}

# this is to catch values from previous perl Makefile.PL run
use lib 'testconfig';

# we try to load the previous config values
eval 'use DBIx::FullTextSearch::TestConfig';

# if we got some values and we are not forced to run the dialog again
# with -s or -setup option, just use those defaults, but say it
if (defined $DBIx::FullTextSearch::TestConfig::Config{'dsn'}
	and not (@ARGV and ($ARGV[0] eq '-s' or $ARGV[0] eq '-setup'))) {
	print <<'EOF';
	For the test suite, we use the database and user info specified
	during the previous run. If you want to change the values, run
	perl Makefile.PL -s.
EOF
	}
# we will ask the questions
else {
	print <<'EOF';
	We will ask you for the database info to run the test. To enter
	undefined value, accept empty string or say undef.
EOF
	if (not defined $DBIx::FullTextSearch::TestConfig::Config{'dsn'}) {
		$DBIx::FullTextSearch::TestConfig::Config{'dsn'} = 'dbi:mysql:test';
		}
	$DBIx::FullTextSearch::TestConfig::Config{'dsn'}
		= prompt 'The dsn for tests:', $DBIx::FullTextSearch::TestConfig::Config{'dsn'};
	$DBIx::FullTextSearch::TestConfig::Config{'user'}
		= prompt 'The username:', $DBIx::FullTextSearch::TestConfig::Config{'user'};
	$DBIx::FullTextSearch::TestConfig::Config{'password'}
		= prompt 'The password:', $DBIx::FullTextSearch::TestConfig::Config{'password'};

	for (qw! dsn user password !) {
		if ($DBIx::FullTextSearch::TestConfig::Config{$_} eq ''
			or $DBIx::FullTextSearch::TestConfig::Config{$_} eq 'undef') {
			$DBIx::FullTextSearch::TestConfig::Config{$_} = undef;
			}
		}
	}

# create the testconfig directory for the DBIx::FullTextSearch::TestConfig.pm file
mkdir 'testconfig', 0700;
mkdir 'testconfig/DBIx', 0700;
mkdir 'testconfig/DBIx/FullTextSearch', 0700;

# write out the TestConfig file, to be used either for next perl
# Makefile.PL in this session, or (after install) even for further
# versions of this module
open OUT, '> testconfig/DBIx/FullTextSearch/TestConfig.pm' or die "Error writing the TestConfig\n";
print OUT Data::Dumper->new([ \%DBIx::FullTextSearch::TestConfig::Config ],
	[ '*DBIx::FullTextSearch::TestConfig::Config' ])->Dump,
	"1;\n";
close OUT;

WriteMakefile(
	NAME =>		'DBIx::FullTextSearch',
	VERSION_FROM =>	'lib/DBIx/FullTextSearch.pm',
	clean =>	{ FILES => "testconfig"},
	PM =>		{ 'lib/DBIx/FullTextSearch.pm' => '$(INST_LIBDIR)/FullTextSearch.pm',
			'lib/DBIx/FullTextSearch/String.pm' => '$(INST_LIBDIR)/FullTextSearch/String.pm',
			'lib/DBIx/FullTextSearch/File.pm' => '$(INST_LIBDIR)/FullTextSearch/File.pm',
			'lib/DBIx/FullTextSearch/URL.pm' => '$(INST_LIBDIR)/FullTextSearch/URL.pm',
			'lib/DBIx/FullTextSearch/Blob.pm' => '$(INST_LIBDIR)/FullTextSearch/Blob.pm',
			'lib/DBIx/FullTextSearch/BlobFast.pm' => '$(INST_LIBDIR)/FullTextSearch/BlobFast.pm',
			'lib/DBIx/FullTextSearch/Column.pm' => '$(INST_LIBDIR)/FullTextSearch/Column.pm',
			'lib/DBIx/FullTextSearch/Phrase.pm' => '$(INST_LIBDIR)/FullTextSearch/Phrase.pm',
			'lib/DBIx/FullTextSearch/StopList.pm' => '$(INST_LIBDIR)/FullTextSearch/StopList.pm',
			'lib/DBIx/FullTextSearch/Table.pm' => '$(INST_LIBDIR)/FullTextSearch/Table.pm',
			'testconfig/DBIx/FullTextSearch/TestConfig.pm' => '$(INST_LIBDIR)/FullTextSearch/TestConfig.pm',
			},
	PREREQ_PM =>    { 'Parse::RecDescent' => 0},
	MAN1PODS =>	{ 'ftsadmin' => '$(INST_MAN1DIR)/ftsadmin.1' },
	dist =>		{ COMPRESS => 'gzip -9f', SUFFIX => 'gz',
			POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
	macro =>	{ BENCH_FILES => 'bench/*.t' },
	depend =>	{ bench => q!pure_all
		for i in $(BENCH_FILES) ; do echo $$i ; $(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) $$i ; done
		! },
	);

