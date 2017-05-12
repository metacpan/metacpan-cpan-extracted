#!/usr/bin/perl -w

BEGIN { 
    $ENV{CATALYST_ENGINE} ||= 'HTTP::Prefork';
}  

use strict;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";

my $debug             = 0;
my $help              = 0;
my $host              = undef;
my $port              = 3000;
my $restart           = 0;
my $restart_delay     = 1;  
my $restart_regex     = '(?:/|^)(?!\.#).+(?:\.yml$|\.yaml$|\.pm)$';
my $restart_directory = undef;
my $follow_symlinks   = 0;

my @argv = @ARGV;

GetOptions(
    'debug|d'             => \$debug,
    'help|?'              => \$help,
    'host=s'              => \$host,
    'port=s'              => \$port,
    'restart|r'           => \$restart,
    'restartdelay|rd=s'   => \$restart_delay,
    'restartregex|rr=s'   => \$restart_regex,
    'restartdirectory=s@' => \$restart_directory,
    'followsymlinks'      => \$follow_symlinks,
);

pod2usage(1) if $help;

if ( $debug ) {
    $ENV{CATALYST_DEBUG} = 1;
}

# This is require instead of use so that the above environment
# variables can be set at runtime.
require TestApp;

TestApp->run( $port, $host, {
    argv              => \@argv,
    restart           => $restart,
    restart_delay     => $restart_delay,
    restart_regex     => qr/$restart_regex/,
    restart_directory => $restart_directory,
    follow_symlinks   => $follow_symlinks,
} );

1;
