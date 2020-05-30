use warnings;
use strict;

use Test::More;

plan tests => 2;


{ package Other;
  sub new { my ($class) = @_; bless {}, $class }
  sub foo { 'FOO' }
}

{ package Base;
  sub new { my ($class) = @_; bless { other => Other->new }, $class }

  sub DESTROY { ::ok 1 => 'Parent destructor called' } }

{ package Der;
  use base 'Base';
  use Class::Delegation
    send => 'foo', to => 'other';
}

my $obj = Der->new();

is $obj->foo, 'FOO' => 'Delegated correctly';

