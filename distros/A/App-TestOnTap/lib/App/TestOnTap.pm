package App::TestOnTap;

use 5.010_001;

use strict;
use warnings;

our $VERSION = '0.050';
my $version = $VERSION;
$VERSION = eval $VERSION;

use App::TestOnTap::Args;
use App::TestOnTap::Harness;
use App::TestOnTap::Util qw($IS_PACKED);

# These are (known) implicit dependencies, and listing them like this
# allows scanners like perlapp to pick up on them
# 
require TAP::Parser if 0;
require TAP::Parser::Aggregator if 0;
require TAP::Parser::Multiplexer if 0;
require TAP::Formatter::Console::ParallelSession if 0;

# main entry point
#
sub main
{
	# as a very special workaround - when running as a packed binary, any PERL5LIB envvar
	# is cleared, but if it's really needed, any TESTONTAP_PERL5LIB will be used to reinsert
	# it here for our children
	# 
	$ENV{PERL5LIB} = $ENV{TESTONTAP_PERL5LIB} if $ENV{TESTONTAP_PERL5LIB};

	# parse raw argv and prepare
	#
	my $args = App::TestOnTap::Args->new($version, @_);

	# run all tests
	#
	my $failed = App::TestOnTap::Harness->new($args)->runtests();
	
	# in case results have been requested...
	#
	my $saveDir = $args->getSaveDir();
	if ($saveDir)
	{
		my $savePath = $args->getWorkDirManager()->saveResult($saveDir, $args->getArchive());
		print "Result saved to '$savePath'\n";
	}
	
	warn("At least $failed test(s) failed!\n") if $failed;

	return $failed;
}

1;
