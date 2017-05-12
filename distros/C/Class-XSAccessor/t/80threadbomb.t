use strict;
use warnings;

BEGIN {
  use Config;
  if (! $Config{'useithreads'}) {
    print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
    exit(0);
  }
}

# The purpose of this test is to check the thread-safety of the module.
# Since this kind of stuff is highly non-deterministic, it's hard to construct
# tests that are. The test consists of running several threads in parallel,
# which all try the two main aspects of the module in a tight loop:
# - creating methods
# - calling those methods
# The former is the type of operation that writes to thread-shared memory
# and requires locking. The latter should not pose any threat to thread-safety
# apart from the OP-tree-inlining optimization.
# Given a certain number of operations per thread, we randomly choose a fraction
# of method creations and method calls to make sure that there's some overlap of
# both types of operations among all test threads.
# The 'common' method below is special cased to ensure that there's some method
# overwriting going on that likely affects multiple threads trying to modify or
# read-access the thread-global memory at the same time in the
# most-likely-colliding manner. The writing-to-shared-memory situation is very
# likely to cause this to crash if the locking isn't working since the memory
# is re-allocated with a geometric-growth algorithm.
# PS: I suspect the whole locking thing is broken on cygwin and thus this test
#     consistently fails there.

srand(0);
$| = 1; # show tests ASAP

our $NumThreads = 5;
our $NumOperations = 10000;
our $CreationFractionHard = 0.2;
our $CreationFractionFuzzy = 0.3;
our $CommonMethodFraction = 0.15;

our $AUTHOR_TESTING = $ENV{AUTHOR_TESTING};

if ($AUTHOR_TESTING) {
  $NumThreads = 30;
  $NumOperations = 10000000;
  $CreationFractionHard = 0.001;
  $CreationFractionFuzzy = 0.001;
}

# Not using Test::More simply because it's too much hassle to
# hack around issues with running in parallel.
print "1.." . ($NumThreads*3 + 1) . "\n";

use threads;
use Class::XSAccessor;
use Time::HiRes qw(sleep);

my @chars = ('a'..'z', 'A'..'Z');

my @t;
foreach (1..$NumThreads) {
  push @t, threads->new(\&_thread_main, $_);
}
$_->join for @t;

print "ok - all reaped\n";

# DONE

sub _thread_main {
  my $no = shift;

  our $obj = bless({} => 'Foo');
  my $ngen = int( $NumOperations*$CreationFractionHard + $NumOperations*$CreationFractionFuzzy * rand() );
  my $ninvoke = $NumOperations - $ngen;
  # This makes sense only if we plan to do a lot of work in the threads
  # => AUTHOR_TESTING
  sleep(rand()) if $AUTHOR_TESTING;
  
  print "ok - starting method generation, thread $no\n";
  my %fields;
  foreach (1 .. $ngen) {
    my $fieldname = (rand > $CommonMethodFraction ? join('', map {$chars[rand(@chars)]} 1..5) : 'common');
    $fields{$fieldname} = undef;
    Class::XSAccessor->import(
      replace => 1,
      class   => 'Foo',
      getters => {$fieldname=> $fieldname}
    );
    print "# thread $no: Generated method $_ of $ngen\n"
      if $AUTHOR_TESTING and not $_ % 10000;
  }

  print "ok - done with method generation, thread $no\n";

  my @methods = keys %fields;
  foreach (1..$ninvoke) {
    if (rand() > $CommonMethodFraction) {
      my $name = $methods[rand @methods];
      $obj->$name;
    }
    else {
      $obj->common;
    }
    print "# thread $no: Ran method $_ of $ninvoke\n"
      if $AUTHOR_TESTING and not $_ % 100000;
  }

  print "ok - done, thread $no\n";
}

