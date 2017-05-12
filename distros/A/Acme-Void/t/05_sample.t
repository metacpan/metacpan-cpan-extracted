#!/usr/bin/perl --

use strict;
use Acme::Void qw(:all);

print "1..1\n";

eval {

    void;
    void foo();
    void = foo();

    void __PACKAGE__->foo;
    void = __PACKAGE__->foo;

    void->foo;
    void->void;

    my $foo = void;
    my @bar = void;

    void = empty = nil = noop = nothing = null = undef;
    void empty nil noop nothing null undef;

    __PACKAGE__->bar;
};
print "not " if $@;
print "ok\n";

sub foo { 1 };

sub bar {
  my $class = shift;
  $class->void;
  void = main->foo;
  return void;
}

