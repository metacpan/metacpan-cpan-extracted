package SomeClass;
package main;
use strict;
use Benchmark qw(timethese timethis cmpthese);
my $id = 1;

our $ID = \$id;
my @data; 

sub new { my $self = bless \ do{ my $o= ${ $ID }++}, shift; return $self;} 

timethis 1000000, sub { my $data = new( 'SomeClass' ) };

print "Pentium M (Dothan), 1,7GHz rate: 653594/s\n";
