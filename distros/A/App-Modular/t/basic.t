#!/usr/bin/perl -w
use strict;
use 5.006_001;
use App::Modular;

print "1..1\n";

# test 1 initialize modularizer
my $mod = App::Modular->instance();
if (ref($mod) ne "App::Modular") {
   print "not ok 1 initialize App::Modular\n";
   print "Bail out!\n";
   print "Could not initialize App::Modular -> tests are useless!\n";
   exit;
}
print "ok 1\n";
$mod->loglevel(0);

