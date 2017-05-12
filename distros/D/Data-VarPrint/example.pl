#!/usr/bin/perl -w

use strict;
use Data::VarPrint;
use IO::Socket;

my $obj = IO::Socket->new();
my $a1 = 1;
my $a2 = \1;
my $a3;
my $b = [1, 2, 3];
my $c = {"1"=>1, "b"=>[1,"2a"], "c"=>{"c1"=>"Pero", "c2"=>[4,5,6, \&VarPrint], "c3"=>$obj}, "d"=>4, "e"=>5};

print "Variables = ", VarPrintAsString($a1, $a2, $a3, $b, $c, $a1, $obj);
#VarPrint($a1, $a2, $a3, $b, $c, $a1, $obj);
#VarPrint({"a1" => $a1, "a2" => $a2, "a3" => $a3, "b" => $b, "c" => $c, "a1" => $a1, "obj" => $obj});
#VarPrint({map {$_ => eval('$'.$_)} ("a1", "a2", "a3", "b", "c", "a1", "obj")});
