use strict;
use warnings;

use Test::More;

use Config;
use File::Spec;
use IO::CaptureOutput qw/capture/;
use lib 't/lib';
use DotDirs;

if( eval {require YAML; 1 } ) {
  plan tests =>  5 ;
}
else {
  plan skip_all => "Requires YAML module";
}

#--------------------------------------------------------------------------#
# Setup test environment
#--------------------------------------------------------------------------#

# Setup CPAN::Reporter configuration and add mock lib path to @INC
$ENV{PERL_CPAN_REPORTER_DIR} = DotDirs->prepare_cpan_reporter;

# Setup CPAN dotdir with custom CPAN::MyConfig
DotDirs->prepare_cpan;

my ($stdout, $stderr);

$ENV{IS_DISABLE_TEST} = 1;

#--------------------------------------------------------------------------#
# tests begin here
#--------------------------------------------------------------------------#

require_ok( 'CPAN::Reporter::Smoker' );

can_ok( 'CPAN::Reporter::Smoker', 'start' );

pass ("Starting simulated smoke testing");

local $ENV{PERL_CR_SMOKER_RUNONCE} = 1;

if ( $ENV{PERL_AUTHOR_TESTING} ) {
    CPAN::Reporter::Smoker::start();
}
else {
    capture \&CPAN::Reporter::Smoker::start, \$stdout, \$stderr;
}

require_ok( 'CPAN::Reporter::History' );
my @results = CPAN::Reporter::History::have_tested();
is( scalar @results, 1, "Number of reports in history" );
