use strict;
use warnings;

use Test::More;

use Config;
use File::Spec;
use IO::CaptureOutput qw/capture/;
use lib 't/lib';
use DotDirs;

plan tests =>  6 ;

#--------------------------------------------------------------------------#
# Setup test environment
#--------------------------------------------------------------------------#

# Setup CPAN::Reporter configuration and add mock lib path to @INC
$ENV{PERL_CPAN_REPORTER_DIR} = DotDirs->prepare_cpan_reporter;

# Setup CPAN dotdir with custom CPAN::MyConfig
DotDirs->prepare_cpan;

my ($stdout, $stderr);

my $list_file = File::Spec->catfile(qw/t data dist-list/);

#--------------------------------------------------------------------------#
# tests begin here
#--------------------------------------------------------------------------#

require_ok( 'CPAN::Reporter::Smoker' );

can_ok( 'CPAN::Reporter::Smoker', 'start' );

pass ("Starting simulated smoke testing");

local $ENV{PERL_CR_SMOKER_RUNONCE} = 1;

my $ran_ok;
$ran_ok = eval {
  capture sub {
    CPAN::Reporter::Smoker::start( list => $list_file )
  } => \$stdout, \$stderr;
  1;
};

ok( $ran_ok, "Finished simulated smoke testing" ) or diag $@;

# check non-blank lines for expected count
open my $dist_file, "<", $list_file;
my @lines = grep { /\S/ } <$dist_file>;
close $dist_file;

require_ok( 'CPAN::Reporter::History' );
my @results = CPAN::Reporter::History::have_tested();
is( scalar @results, scalar @lines, "Number of reports in history" );

