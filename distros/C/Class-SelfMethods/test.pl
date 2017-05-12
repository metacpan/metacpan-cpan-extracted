# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..21\n"; }
END {print "not ok 1\n" unless $loaded;}
use Class::SelfMethods;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package MyClass;
@ISA = qw(Class::SelfMethods);
use strict;

sub _friendly {
  my $self = shift;
  return $self->name;
}

package main;
no strict;

my $foo = MyClass->new( name => 'ok 2' );
my $bar = MyClass->new( name => 'not ok 3', friendly => 'ok 3');
my $bas = MyClass->new( name => 'not ok 4',
                        friendly => sub {
                          my $self = shift;
                          (my $retval = $self->_friendly) =~ s/not //;
                          return $retval;
                        }
                      );

# TEST 2
print(($foo->friendly ? $foo->friendly : 'not ok 2'), "\n");

# TEST 3
print $bar->friendly, "\n";

# TEST 4
print $bas->friendly, "\n";

# TEST 5
$foo->name_SET("ok 5");
print(($foo->friendly ? $foo->friendly : 'not ok 5'), "\n");

# TEST 6
$bas->name_SET("not ok 6");
$bas->friendly_SET( sub { "ok 6" } );
print $bas->friendly, "\n";

# TEST 7
$bas->name_SET("not ok 7");
$bas->friendly_SET( sub { return $_[1]->($_[2]); } );
print $bas->friendly( sub { return "ok $_[0]" }, 7 ), "\n";

# TEST 8
$bas->name_SET("not ok 8");
print $bas->friendly( sub { return "ok $_[0]" }, 8 ), "\n";

# TEST 9
$bas->name_SET("not ok 9");
$bas->friendly_SET("ok 9");
print $bas->friendly, "\n";

# TEST 10
$bas->friendly_SET("not ok 10");
$bas->name_SET("ok 10");
$bas->friendly_CLEAR;
print $bas->friendly, "\n";

#TEST 11
my $foo_SET = $bas->can('foo_SET');
print $foo_SET ? "ok 11\n" : "not ok 11\n";

#TEST 12
$bas->$foo_SET("ok 12\n");
print $bas->foo ? $bas->foo : "not ok 12\n";

#TEST 13
print $bas->can('foo') ? "ok 13\n" : "not ok 13\n";

#TEST 14
my $foo_CLEAR = $bas->can('foo_CLEAR');
print $foo_CLEAR ? "ok 14\n" : "not ok 14\n";

#TEST 15
print $bas->can('foo') ? "ok 15\n" : "not ok 15\n";

#TEST 16
$bas->$foo_CLEAR();
print $bas->can('foo') ? "not ok 16\n" : "ok 16\n";

#TEST 17
print !eval { $bas->foo }
  && $@ =~ /Can't locate object method "foo" via package "MyClass"/ ? "ok 17\n" : "not ok 17\n";

#TEST 18
my $friendly = $foo->can('friendly');
print $friendly ? "ok 18\n" : "not ok 18\n";

#TEST 19
$foo->name_SET("ok 19\n");
print $foo->$friendly() ? $foo->$friendly() : "not ok 19\n";

#TEST 20
print $foo->can('nonexistent') ? "not ok 20\n" : "ok 20\n";

#TEST 21
print !eval { $foo->nonexistent }
  && $@ =~ /Can't locate object method "nonexistent" via package "MyClass"/ ? "ok 21\n" : "not ok 21\n";
