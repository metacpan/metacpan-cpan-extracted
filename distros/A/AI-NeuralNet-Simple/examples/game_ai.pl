#!/usr/local/bin/perl -w
use strict;
use lib '../blib/lib/', 'blib/lib';
use AI::NeuralNet::Simple;

use constant ATTACK => [1.0, 0.0, 0.0, 0.0]; 
use constant RUN    => [0.0, 1.0, 0.0, 0.0]; 
use constant WANDER => [0.0, 0.0, 1.0, 0.0]; 
use constant HIDE   => [0.0, 0.0, 0.0, 1.0]; 

use constant GOOD    => 2.0;
use constant AVERAGE => 1.0;
use constant POOR    => 0.0;

use constant YES     => 1.0;
use constant NO      => 0.0;

my $net = AI::NeuralNet::Simple->new(4,20,4);
$net->iterations(shift || 100000);
$net->train_set( [
#   health    knife gun  enemy
    [GOOD,    YES,  YES, 0],  WANDER,
    [GOOD,    YES,   NO, 2],  HIDE,
    [GOOD,    YES,   NO, 1],  ATTACK,
    [GOOD,    YES,   NO, 0],  WANDER,
    [GOOD,     NO,  YES, 2],  ATTACK,
    [GOOD,     NO,  YES, 1],  ATTACK,
    [GOOD,     NO,   NO, 3],  HIDE,
    [GOOD,     NO,   NO, 2],  HIDE,
    [GOOD,     NO,   NO, 1],  RUN,
    [GOOD,     NO,   NO, 0],  WANDER,

    [AVERAGE, YES,  YES, 0],  WANDER,
    [AVERAGE, YES,   NO, 2],  HIDE,
    [AVERAGE, YES,   NO, 1],  RUN,
    [AVERAGE,  NO,  YES, 2],  HIDE,
    [AVERAGE,  NO,  YES, 1],  ATTACK,
    [AVERAGE,  NO,   NO, 3],  HIDE,
    [AVERAGE,  NO,   NO, 2],  HIDE,
    [AVERAGE,  NO,   NO, 1],  RUN,
    [AVERAGE,  NO,   NO, 0],  WANDER,
    [AVERAGE,  NO,   NO, 0],  WANDER,

    [POOR,    YES,   NO, 2],  HIDE,
    [POOR,    YES,   NO, 1],  RUN,
    [POOR,     NO,  YES, 2],  HIDE,
    [POOR,     NO,  YES, 1],  RUN,
    [POOR,     NO,   NO, 2],  HIDE,
    [POOR,     NO,   NO, 1],  HIDE,
    [POOR,     NO,   NO, 0],  WANDER,
    [POOR,    YES,   NO, 0],  WANDER,
]);


my $format = "%8s %5s %3s %7s %6s\n";
my @actions = qw/attack run wander hide/;

printf $format, qw/Health Knife Gun Enemies Action/;
display_result($net,2,1,1,1);
display_result($net,2,0,0,2);
display_result($net,2,0,1,2);
display_result($net,2,0,1,3);
display_result($net,1,1,0,0);
display_result($net,1,0,1,2);
display_result($net,0,1,0,3);

while (1) {
    print "Type 'quit' to exit\n";
    my $health  = prompt("Am I in poor, average, or good health? ", qr/^(?i:[pag])/);
    my $knife   = prompt("Do I have a knife? ", qr/^(?i:[yn])/);
    my $gun     = prompt("Do I have a gun? ", qr/^(?i:[yn])/);
    my $enemies = prompt("How many enemies can I see? ", qr/^\d+$/);
    
    $health = substr $health, 0, 1;
    $health =~ tr/pag/012/;
    foreach ($knife,$gun) {
        $_ = substr $_, 0, 1;
        tr/yn/10/;
    }
    printf "I think I will %s!\n\n", $actions[$net->winner([
        $health, 
        $knife, 
        $gun, 
        $enemies])];
}

sub prompt 
{
    my ($message,$domain) = @_;
    my $valid_response = 0;
    my $response;
    do {
        print $message;
        chomp($response = <STDIN>);
        exit if substr(lc $response, 0, 1) eq 'q';
        $valid_response = $response =~ /$domain/;
    } until $valid_response;
    return $response;
}

sub display_result
{
    my ($net,@data) = @_;
    my $result      = $net->winner(\@data);
    my @health      = qw/Poor Average Good/;
    my @knife       = qw/No Yes/;
    my @gun         = qw/No Yes/;
    printf $format, 
        $health[$_[1]], 
        $knife[$_[2]], 
        $gun[$_[3]], 
        $_[4],             # number of enemies
        $actions[$result];
}
