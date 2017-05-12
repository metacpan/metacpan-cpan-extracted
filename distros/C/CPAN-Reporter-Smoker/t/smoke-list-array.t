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

my @list = qw(
  DAGOLDEN/Bogus-Pass-0.01.tar.gz
  DAGOLDEN/Bogus-Fail-0.01.tar.gz
);

#--------------------------------------------------------------------------#
# tests begin here
#--------------------------------------------------------------------------#

require_ok( 'CPAN::Reporter::Smoker' );

can_ok( 'CPAN::Reporter::Smoker', 'start' );

pass ("Starting simulated smoke testing");

local $ENV{PERL_CR_SMOKER_RUNONCE} = 1;

my $ran_ok;
if ( $ENV{PERL_AUTHOR_TESTING} ) {
    CPAN::Reporter::Smoker::start();
}
else {
  $ran_ok = eval {
    capture sub {
      CPAN::Reporter::Smoker::start( list => \@list )
    } => \$stdout, \$stderr;
    1;
  }
}

ok( $ran_ok, "Finished simulated smoke testing" ) or diag $@;

require_ok( 'CPAN::Reporter::History' );
my @results = CPAN::Reporter::History::have_tested();
is( scalar @results, scalar @list, "Number of reports in history" );

