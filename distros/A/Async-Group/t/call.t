# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use Async::Group ;
$loaded = 1;
print "ok 1\n";
my $trace = shift ;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict ;

sub sub1 
  {
    print "Dummy subroutine \n" if $trace ;
    my $dummy = shift ;
    my $cb = shift ;

    &$cb(1,"Dummy ok\n");
  }

sub nsub1 
  {
    print "Dummy false subroutine \n" if $trace ;
    my $dummy = shift ;
    my $cb = shift ;

    &$cb(0,"dummy false\n");
  }

sub allDone
  {
    print "All done, result is ", shift ,", all outputs are\n",shift  if $trace ;
  }

my $a = Async::Group->new(name => 'aTest', test => $trace) ;
my $cb = $a->getCbRef();

$a->run(set => [ sub {&sub1( callback => $cb)},
                 sub {&sub1( callback => $cb)},
                 sub {&nsub1( callback => $cb )},
                 sub {&nsub1( callback => $cb )} ],
        callback => \&allDone 
       )
