#!/usr/bin/perl

package Some::Class::InsideOutBase;

use strict;
use warnings;

use Class::Tie::InsideOut;

our @ISA = qw( Class::Tie::InsideOut );


BEGIN {
  no strict 'refs';
  foreach my $field (qw( foo bar )) {
    *{$field}       = { };
    *{"set_$field"} = sub {
      my $self = shift;
      $self->{$field} = shift;
    };
    *{"get_$field"} = sub {
      my $self = shift;
      $self->{$field};
    };
  }
}

package Another::Class::Name::InsideOutInherited;

our @ISA = qw( Some::Class::InsideOutBase );

our %bar;

sub inherited_foo {
  my $self = shift;
  if (@_) {
    return $self->{foo} = shift;
  } else {
    return $self->{foo};
  }
}

sub my_bar {
  my $self = shift;
  if (@_) {
    eval { $self->{bar} = shift; };
  } else {
    return $self->{bar};
  }
}

BEGIN {
  no strict 'refs';
  foreach my $field (qw( bo baz )) {
    *{$field}       = { };
    *{"set_$field"} = sub {
      my $self = shift;
      $self->{$field} = shift;
    };
    *{"get_$field"} = sub {
      my $self = shift;
      $self->{$field};
    };
  }
}


package main;

use strict;
use warnings;

use Test::More tests => 8;

my $obj = Another::Class::Name::InsideOutInherited->new();
ok($obj->isa("Another::Class::Name::InsideOutInherited"));
ok($obj->isa("Some::Class::InsideOutBase"));
ok($obj->isa("Class::Tie::InsideOut"));

{
  # local $TODO = "inheritance does not work";
  my $exp = 0;
  eval {
    $obj->set_foo(12);
    $exp = $obj->get_foo;
    # 
  };
  ok( !$@, "no error from inherited methods" );
  ok( $exp == 12, "tested inherited method" );
}

$obj->set_baz(99);
ok( $obj->get_baz == 99, "tested added method" );

undef $@;
eval { $obj->inherited_foo; };
ok( $@, "access to inherited field fails" );


$obj->set_bar(5);
$obj->my_bar(6);
ok($obj->get_bar != $obj->my_bar, "separate fields with the same name");
