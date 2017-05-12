BEGIN { $| = 1; print "1..21\n"; }

END {print "not ok 2\n" unless $storable;}
END {print "not ok 1\n" unless $loaded;}

use strict;
use vars qw( $loaded $storable $cookie );

use Apache::Recorder;
$loaded = 1;
print "ok 1\n";

use Storable qw( lock_retrieve );
$storable = 1;
print "ok 2\n";

#####################################################
#Test Apache::Recorder::write_config_file()
#####################################################

my $config_file = "t/recorder_config_file";
my $uri = 'http://localhost/index.htm';
my $request_type = 'GET';
my %params = (
    'state' => 'AL',
    'groupselect' => 9,
    'provnum' => '017037'
);

my $rc = Apache::Recorder::write_config_file( $config_file, $uri, $request_type,\%params );
if ( $rc ) { print "ok 3\n" }
else { print "not ok 3\n" }

#Test what happens if you fail to provide a path to the config_file
my $rc2;
eval {
    $rc2 = Apache::Recorder::write_config_file( '', $uri, $request_type, \%params );
};

unless ( $@ =~ /No such file or directory/ ) {print "not ok 4\n" }
else { print "ok 4\n" }

#Check the data you just wrote 
my $history = lock_retrieve( $config_file ) || undef;

if ( $history->{ 1 }{ 'method' } eq $request_type ) { print "ok 5\n" }
else { print "not ok 5\n" }

if ( $history->{ 1 }{ 'acceptcookie' } eq '1' ) { print "ok 6\n" }
else { print "not ok 6\n" }

if ( $history->{ 1 }{ 'url' } eq $uri ) { print "ok 7\n" }
else { print "not ok 7\n" }

if ( $history->{ 1 }{ 'sendcookie' } eq '1' ) { print "ok 8\n" }
else { print "not ok 8\n" }

if ( $history->{ 1 }{ 'print_results' } eq '1' ) { print "ok 9\n" }
else { print "not ok 9\n" }

if ( $history->{ 1 }{ 'params' }{ 'state' } eq 'AL' ) { print "ok 10\n" }
else { print "not ok 10\n" }

if ( $history->{ 1 }{ 'params' }{ 'groupselect' } eq '9' ) { print "ok 11\n" }
else { print "not ok 11\n" }

if ( $history->{ 1 }{ 'params' }{ 'provnum' } eq '017037' ) { print "ok 12\n" }
else { print "not ok 12\n" }

##############
# Test inserting a second click to the config file
##############

$uri = 'http://localhost/index2.htm';
$request_type = 'POST';
%params = (
    'state' => 'MA',
    'groupselect' => 124,
    'provnum' => 'AAAe887'
);

$rc = Apache::Recorder::write_config_file( $config_file, $uri, $request_type,\%params );
if ( $rc ) { print "ok 13\n" }
else { print "not ok 13\n" }

#Check the data you just wrote 
$history = lock_retrieve( $config_file ) || undef;

if ( $history->{ 2 }{ 'method' } eq $request_type ) { print "ok 14\n" }
else { print "not ok 14\n" }

if ( $history->{ 2 }{ 'acceptcookie' } eq '1' ) { print "ok 15\n" }
else { print "not ok 15\n" }

if ( $history->{ 2 }{ 'url' } eq $uri ) { print "ok 16\n" }
else { print "not ok 16\n" }

if ( $history->{ 2 }{ 'sendcookie' } eq '1' ) { print "ok 17\n" }
else { print "not ok 17\n" }

if ( $history->{ 2 }{ 'print_results' } eq '1' ) { print "ok 18\n" }
else { print "not ok 18\n" }

if ( $history->{ 2 }{ 'params' }{ 'state' } eq 'MA' ) { print "ok 19\n" }
else { print "not ok 19\n" }

if ( $history->{ 2 }{ 'params' }{ 'groupselect' } eq '124' ) { print "ok 20\n" }
else { print "not ok 20\n" }

if ( $history->{ 2 }{ 'params' }{ 'provnum' } eq 'AAAe887' ) { print "ok 21\n" }
else { print "not ok 21\n" }

####################
# Tear-down
####################

#Delete the config file to avoid populating with too many "clicks" if make test 
#    gets run multiple times.

my @cannot = grep { not unlink } $config_file;
print STDERR "$0: could not unlink @cannot.  Manually delete this file before running make test again.\n" if @cannot;
