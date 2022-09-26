#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Class::Plain;

{
  class MyClassField {
    field x;
    field y;
    method where { sprintf "(%d,%d)", $self->{x}, $self->{y} }
  }

  {
    my $p = MyClassField->new(x => 10, y => 20);
    is( $p->where, "(10,20)", '$p->where' );
  }

  {
    my $p = MyClassField->new({x => 10, y => 20});
    is( $p->where, "(10,20)", '$p->where' );
  }
}

{
  class PointArgs {
    field x;
    field y;

    method new : common {
      my $self = $class->SUPER::new(x => $_[0], y => $_[1]);
      
      $self->{x} //= 0;
      $self->{y} //= 0;
      
      return $self;
    }

    method where { sprintf "(%d,%d)", $self->{x}, $self->{y} }
  }

  {
     my $p = PointArgs->new(10,20);
     is( $p->where, "(10,20)", '$p->where' );
  }
}

# Class Variable
{
  class ClassVariable {
    # Public
    our $FOO;
    
    # Private
    my $BAR;
    
    BEGIN {
      $FOO = 1;
      $BAR = 2;
    }
    
    method FOO : common { $FOO }
    method BAR : common { $BAR }
  }

  {
    is(ClassVariable->FOO, 1);
    is(ClassVariable->BAR, 2);
  }
}

{
  use ModuleClass;
  
  my $object = ModuleClass->new(x => 1);
  is($object->x, 1);
  $object->set_y(2);
  is($object->{y}, 2);
  $object->z(3);
  is($object->z, 3);
}

# Array Based Object
{
  class ArrayBased {
    method new : common {
      return bless [@_], ref $class || $class;
    }
    
    method push {
      my ($value) = @_;
      
      push @$self, $value;
    }
    
    method get {
      my ($index) = @_;
      
      return $self->[$index];
    }
    
    method to_array {
      return [@$self];
    }
  }
  
  my $object = ArrayBased->new(1, 2);

  is_deeply($object->to_array, [1, 2]);
  
  $object->push(3);
  $object->push(5);
  
  is($object->get(0), 1);
  is($object->get(1), 2);
  is($object->get(2), 3);
  is($object->get(3), 5);
  is_deeply($object->to_array, [1, 2, 3, 5]);
}

# Scalar Based Object
{
  class ScalarBased {
    method new : common {
      
      my $value = shift;
      
      return bless \$value, ref $class || $class;
    }
    
    method to_value {
      return $$self;
    }
  }
  
  my $object = ScalarBased->new(3);
  
  is($object->to_value, 3);
}

# Conflicting Keyword
{
  class MyConflictKeyword {
    method class {
      return "class";
    }
    
    method method {
      return "method";
    }
    
    method field {
      return "field";
    }
  }
  
  my $object = MyConflictKeyword->new;
  is($object->class, "class");
  is($object->method, "method");
  is($object->field, "field");
}

# Conflicting Keyword
{
  class MyConflictKeyword {
    method class {
      return "class";
    }
    
    method method {
      return "method";
    }
    
    method field {
      return "field";
    }
  }
  
  my $object = MyConflictKeyword->new;
  is($object->class, "class");
  is($object->method, "method");
  is($object->field, "field");
}

done_testing;
