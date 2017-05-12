
# this is the same test as t/02basic.t but
# using inheritance rather than exporting &give_my_self

use Test::More tests => 5;

package My::Class;

BEGIN {
  require Class::Lego::Myself;
  @My::Class::ISA = qw( Class::Lego::Myself );
}

Test::More::ok( __PACKAGE__->can('give_my_self'), "&give_my_self was inherited" );

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

