#!/usr/bin/perl -w
use strict;
#use lib '../lib';
use Class::STAF;
use Test::Simple tests=>1;

package STAF::Service::Var::VarInfo;
use base qw/Class::STAF::Marshalled/;

__PACKAGE__->field("X", "X");
__PACKAGE__->field("Y", "Y");
__PACKAGE__->field("Z", "Z");

package main;

my $class_string = 
'@SDT/*:372:@SDT/{:290::13:map-class-map@SDT/{:262::24:STAF/Service/Var/VarInfo'. 
'@SDT/{:223::4:keys@SDT/[3:162:@SDT/{:44::12:display-name@SDT/$S:1:X:3:key'. 
'@SDT/$S:1:X@SDT/{:44::12:display-name@SDT/$S:1:Y:3:key@SDT/$S:1:Y'. 
'@SDT/{:44::12:display-name@SDT/$S:1:Z:3:key@SDT/$S:1:Z:4:name'. 
'@SDT/$S:24:STAF/Service/Var/VarInfo@SDT/%:61::24:STAF/Service/Var/VarInfo'.
'@SDT/$S:1:3@SDT/$S:1:4@SDT/$S:1:5';

my $class_ref = STAF::Service::Var::VarInfo->new("X"=>3, "Y"=>4, "Z"=>5);
ok(Marshall($class_ref) eq $class_string, "Creating class and marshalling it");


