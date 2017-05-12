#!perl -T

use Test::More tests => 1;

package myclass;
use Class::Constant WHATEVER => "whatever";

sub as_string {
    return "forty two";
}

package main;

is(myclass::WHATEVER, "forty two");
