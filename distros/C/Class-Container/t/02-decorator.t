use strict;

use Test;
BEGIN { plan tests => 24 }

use Class::Container;
use Params::Validate qw(:types);
use File::Spec;
require File::Spec->catfile('t', 'classes.pl');



# Decorator stuff
{
  local @Top::ISA = qw(Class::Container);
  Top->valid_params(undef);
  Top->contained_objects();
  sub Top::foo { "foo" }
  
  local @Decorator::ISA = qw(Top);
  Decorator->decorates;
  sub Decorator::bar { "bar" }
  
  local @OtherDec::ISA = qw(Top);
  OtherDec->decorates;
  sub OtherDec::baz { "baz" }
  
  # Make sure a simple 1-level decorator works
  {
    my $d = new Decorator;
    ok $d;
    
    ok $d->foo, 'foo';
    ok $d->bar, 'bar';
    
    # Should be using simple subclassing since it's just 1 level (no interface for this)
    ok !$d->{_decorates};
    
    # Make sure can() is correct
    # Test.pm will run subrefs (don't want that), so make them booleans
    ok !!$d->can('foo');
    ok !!$d->can('bar');
    ok  !$d->can('baz');
  }
  
  # Try a 2-level decorator
  {
    my $d = new Decorator(decorate_class => 'OtherDec');
    ok $d;
    
    ok !!$d->can('foo');
    ok !!$d->can('bar');
    ok !!$d->can('baz');
    
    ok $d->foo, 'foo';
    ok $d->bar, 'bar';
    ok $d->baz, 'baz';
    
    # Make sure it's using decoration containment at top level, and subclassing below.
    ok $d->{_decorates};
    ok ref($d->{_decorates}), 'OtherDec';
    ok !$d->{_decorates}{_decorates};
  }
  
  # Make sure arguments are passed correctly
  Top->valid_params( one => { type => SCALAR } );
  Decorator->valid_params( two => { type => SCALAR } );
  Top->decorates;
  Decorator->decorates;
  OtherDec->decorates;
  my $d = Decorator->new( one => 1, two => 2 );
  ok $d;
  
  $d = OtherDec->new( decorate_class => 'Decorator', one => 1, two => 2 );
  ok $d;
  ok $d->{one}, 1;
  ok $d->{_decorates}{two}, 2;

  $d = Decorator->new( decorate_class => 'OtherDec', one => 1, two => 2 );
  ok $d;
  ok $d->{one}, 1;
  ok $d->{two}, 2;
}

