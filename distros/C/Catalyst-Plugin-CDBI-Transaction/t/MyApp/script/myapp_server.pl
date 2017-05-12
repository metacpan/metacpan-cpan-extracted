#!/usr/bin/perl -w

BEGIN { 
    $ENV{CATALYST_ENGINE} ||= 'HTTP';
    $ENV{CATALYST_SCRIPT_GEN} = 4;
}  

use strict;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use MyApp;

my $help = 0;
my $port = 3000;

GetOptions( 'help|?' => \$help, 'port=s' => \$port );

pod2usage(1) if $help;

MyApp->run($port);

1;
