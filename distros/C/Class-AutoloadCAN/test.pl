#! /usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..20\n"; }
END {print "not ok 1\n" unless $loaded;}
use Class::AutoloadCAN;
use Carp;
$loaded = 1;
print "ok 1\n";

my $tests_done = 1;

# The following classes are used in later tests.  They are here so that
# the inheritance is set up before those tests.
{
  package NoAutoload;

  sub implemented { "foo" };

  sub CAN {
    sub {"bar"};
  }

  package Base1;
  Class::AutoloadCAN->import;

  # This CAN is always paid attention to.
  sub CAN {
    my ($base_class, $method, $self, @args) = @_;
    return sub {"Base1"} if $method =~ /base1/;
  }

  package Base2;

  # This CAN is only paid attention to after we call import.
  sub CAN {
    my ($base_class, $method, $self, @args) = @_;
    return sub {"Base2"} if $method =~ /base2/;
  }

  package Child;
  @ISA = qw(Base1 Base2);

  # This CAN is paid attention to through inheritance.
  sub CAN {
    my ($base_class, $method, $self, @args) = @_;
    return sub {"Child"} if $method =~ /child/;
  }

  package GrandChild;
  @ISA = 'Child';
  sub can {"overridden"}

  package GreatGrandChild;
  use Class::AutoloadCAN;
  @ISA = 'GrandChild';
}

true(NoAutoload->can("implemented"), "Raw subs work");
true(NoAutoload->implemented eq "foo", "Raw subs are called normally");
true(!NoAutoload->can("not_implemented"), "CAN ignored if not AUTOLOADED");
eval {NoAutoload->not_implemented};
true($@ =~ /object method/, "Missing methods are missing if not AUTOLOADED");
eval {NoAutoload::not_implemented()};
true($@ =~ /subroutine/, "Missing subroutines are missing if not AUTOLOADED");
true(!NoAutoload->can("Child::implemented"), "Reset method search");
true(Child->can("child_method"), "CAN used in class");
true(Child->child_method eq "Child", "Child gets its own methods");
true(Child->can("base1_method"), "Inherited CAN seen");
true(Child->base1_method eq "Base1", "Child gets inherited CAN methods");
true(!Child->can("base2_method"), "CAN from ignored class, ignored");
eval "Child->base2_method";
true(($@ and $@ =~ /object method/), "Ignored class doesn't provide methods");
true(($@ and $@ =~ /"Child"/), "The error message includes the package");
true(($@ and $@ !~ /forgot to load/), "No load message on loaded package");
true(($@ =~ /eval/) ? 1 : 0, "The error comes from the right caller");
Class::AutoloadCAN->import("Base2");
true(Child->can("base2_method"), "Can unignore class");
true(Child->base2_method eq "Base2", "Unignored class provides methods");
true(GreatGrandChild->child_method eq "Child",
  "Can inherit through overridden can");
true(GreatGrandChild->can("child_method") eq "overridden",
  "But can is overridden");

sub true {
  my ($value, $test) = @_;
  confess("Wrong number of arguments") unless 2 == @_;
  $tests_done++;
  if ($value) {
    print "ok $tests_done\n";
    #print STDERR "\n\n$tests_done: $test succeeded\n";
  }
  else {
    print "not ok $tests_done\n";
    print STDERR "\n\n$tests_done: $test failed\n";
  }
}
