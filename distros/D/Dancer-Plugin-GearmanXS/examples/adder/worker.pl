#!/usr/bin/env perl
use strict;
use warnings;
use Gearman::XS qw(:constants);
use Gearman::XS::Worker;

use Storable qw/thaw/;

# a simple "add arguments" worker

sub do_add {
    my $job     = shift;
    my $numbers = thaw( $job->workload );
    warn "Got numbers to add: @$numbers\n";
    my $sum = 0;
    $sum += $_ for @$numbers;
    warn "Added @$numbers = $sum\n";
    return $sum;
}

my $worker = Gearman::XS::Worker->new;
my $ret = $worker->add_server( '127.0.0.1', 4730 );
die "Error: " . $worker->error() unless $ret == GEARMAN_SUCCESS;

$ret = $worker->add_function( 'add', 1, \&do_add, 1 );
die "Error: " . $worker->error() unless $ret == GEARMAN_SUCCESS;

my $count = 500;
print "Serving up to $count connections..\n";
while ( $count > 0 ) {
    my $ret = $worker->work;
    die "Error: " . $worker->error() unless $ret == GEARMAN_SUCCESS;
    print "Worked..\n";
    $count--;
}
print "Bye!\n";
