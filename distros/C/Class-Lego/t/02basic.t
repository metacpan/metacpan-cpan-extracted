
use Test::More tests => 5;

package My::Class;

use Class::Lego::Myself;

Test::More::ok( defined &give_my_self, "&give_my_self was exported" );

__PACKAGE__->give_my_self;

Test::More::ok( defined &find_my_self, "&find_my_self was installed" );

sub new { 
  my ($self, $fields) = @_;
  $fields ||= { name => 'me' };
  return bless {%$fields}, $self;
}

sub greeting {
  my $self = &find_my_self;
  return "Hello from " . $self->{name};
}

sub my_self {
  scalar &find_my_self;
}

package main;

is( My::Class->greeting, 'Hello from me', '&greeting works for class' );

is( My::Class->my_self, My::Class->my_self, 'always the same default' );

my $obj = My::Class->new({ name => 'Foo' });
is( $obj->greeting, 'Hello from Foo', '&greeting works for instances' );

