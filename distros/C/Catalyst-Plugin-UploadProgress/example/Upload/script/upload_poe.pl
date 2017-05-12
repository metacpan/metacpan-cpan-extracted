#!/usr/bin/perl -w

BEGIN { 
    $ENV{CATALYST_ENGINE} ||= 'HTTP::POE';
}  

use strict;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";

my $debug         = 0;
my $help          = 0;
my $host          = undef;
my $port          = 3000;

my @argv = @ARGV;

GetOptions(
    'debug|d'           => \$debug,
    'help|?'            => \$help,
    'host=s'            => \$host,
    'port=s'            => \$port,
);

pod2usage(1) if $help;

if ( $debug ) {
    $ENV{CATALYST_DEBUG} = 1;
}

# This is require instead of use so that the above environment
# variables can be set at runtime.
require Upload;

Upload->run( $port, $host, {
    argv          => \@argv,
} );

1;

