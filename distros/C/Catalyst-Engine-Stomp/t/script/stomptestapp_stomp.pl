BEGIN { 
	$ENV{CATALYST_ENGINE} = 'Stomp';
	require Catalyst::Engine::Stomp;
}  

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";

my $debug   = 0;
my $help    = 0;
my $oneshot = 0;

my @argv = @ARGV;

GetOptions(
    'debug|d' => \$debug,
    'help|?'  => \$help,
    'oneshot' => \$oneshot,
);

pod2usage(1) if $help;

if ( $debug ) {
	$ENV{CATALYST_DEBUG} = 1;
}

if ( $oneshot ) { 
	$ENV{ENGINE_ONESHOT} = 1;
}	

# This is require instead of use so that the above environment
# variables can be set at runtime.
require StompTestApp;
StompTestApp->run();

1;

=head1 NAME

testapp_stomp.pl - Catalyst STOMP client

=head1 SYNOPSIS

testapp_stomp.pl [options]

 Options:
   -d -debug          force debug mode
   -? -help           display this help and exits

 See also:
   perldoc Catalyst::Engine::Stomp
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst STOMP client for this application.

=cut
