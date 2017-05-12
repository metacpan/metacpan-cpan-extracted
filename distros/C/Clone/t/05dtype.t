# $Id: 05dtype.t,v 0.18 2006/10/08 03:37:29 ray Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $has_data_dumper;
BEGIN {
  $| = 1;
  my $tests = 1;
  eval q[use Data::Dumper];
  if (!$@) {
    $has_data_dumper = 1;
    $tests++;
  }
  print "1..$tests\n";
}
END {print "not ok 1\n" unless $loaded;}
use Clone;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

eval 'use Storable qw( dclone )';
if ($@) 
{
  print "ok 2 # skipping Storable not found\n";
  exit;
}
# use Storable qw( dclone );

$^W = 0;
$test = 2;

sub ok     { printf("ok %d\n", $test++); }
sub not_ok { printf("not ok %d\n", $test++); }

use strict;

package Test::Hash;

@Test::Hash::ISA = qw( Clone );

sub new()
{
  my ($class) = @_;
  my $self = {};
  $self->{x} = 0;
  $self->{x} = {value => 1};
  bless $self, $class;
}

package main;

my ($master, $clone1);

my $a = Test::Hash->new();

my $b = $a->clone;
my $c = dclone($a);

if ($has_data_dumper) {
  Dumper($a, $b) eq Dumper($a, $c) ? ok() : not_ok;
}
# print Dumper($a, $b);
# print Dumper($a, $c);
