#!/usr/bin/perl

use strict;
use Test;

BEGIN {
  use strict;
  plan tests => 10;
  package MyClass;
  use base qw/Class::MethodFilter/;

  sub new {
    return bless ({ baz => 'baz' }, $_[0]);
  }

  sub foo {
    return "foo!";
  }

  sub bar {
    return "bar!";
  }

  sub baz {
    my $self = shift;
    $self->{'baz'} = $_[0] if @_;
    return $self->{'baz'};
  }

  sub baz_filtered {
    my $self = shift;
    $self->{'baz_filtered'} = $_[0] if @_;
    return $self->{'baz_filtered'};
  }

  sub quux {
    return "quux!";
  }

  sub quux_filter {
    return "QUUX!";
  }

  __PACKAGE__->add_method_filter('foo', sub { $_[1] =~ tr/a-z/A-Z/; $_[1]; });
  __PACKAGE__->add_method_filter('bar', 'barf');
  __PACKAGE__->add_method_filter('baz', sub { $_[1] =~ tr/a-z/A-Z/; $_[1]; });
  __PACKAGE__->add_method_filter('quux');

  sub barf {
    $_[1] =~ s/(\w+)/$1f/;
    $_[1];
  }

}

my $x = new MyClass;

ok($x->foo() eq 'foo!');
ok($x->foo_filtered() eq 'FOO!');
ok($x->bar() eq 'bar!');
ok($x->bar_filtered() eq 'barf!');
ok($x->baz() eq 'baz');
ok(!defined($x->baz_filtered()));
$x->baz("NewValue");
ok($x->baz() eq 'NewValue');
ok($x->baz_filtered() eq 'NEWVALUE');
ok($x->quux() eq 'quux!');
ok($x->quux_filtered() eq 'QUUX!');
