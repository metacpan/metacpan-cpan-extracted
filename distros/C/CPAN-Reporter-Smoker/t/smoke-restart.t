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

#--------------------------------------------------------------------------#
# tests begin here
#--------------------------------------------------------------------------#

require_ok( 'CPAN::Reporter::Smoker' );

can_ok( 'CPAN::Reporter::Smoker', 'start' );

pass ("Starting simulated smoke testing");

local $ENV{PERL_CR_SMOKER_RUNONCE} = 1;

my $rc;
if ( $ENV{PERL_AUTHOR_TESTING} ) {
    $rc = CPAN::Reporter::Smoker::start( restart_delay => 1 );
}
else {
    $rc = capture { CPAN::Reporter::Smoker::start( restart_delay => 1 ) }
                  \$stdout, \$stderr;
}

require_ok( 'CPAN::Reporter::History' );
my @results = CPAN::Reporter::History::have_tested();
is( scalar @results, 6 , "Number of reports in history" );
ok( $rc > 1, "Looped more than once due to restart delay" );

