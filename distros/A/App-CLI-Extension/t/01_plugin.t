#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use lib qw(t/lib);
use MyApp;

our $RESULT;

my $result;
my($hour) = (localtime time)[2];
if($hour >= 5 && $hour <= 11){
    $result = "good morning";
}elsif($hour >= 12 && $hour <= 18){
    $result = "hello";
}elsif($hour >= 19 && $hour <= 23){
    $result= "good evening";
}else{
    $result = "good night";
}

{
    local *ARGV = ["plugin"];
    MyApp->dispatch;
}

ok($result eq $RESULT);



