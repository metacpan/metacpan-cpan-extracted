use strict;
use warnings;

use Test::More;
use Class::Anonymous;

my $class = class {
  my ($self, $name) = @_;
  $self->(greet => sub { "Hello, my name is $name" });
  $self->(yell  => sub { uc $_[1] });
};

my $instance = $class->new('Joel');
is $instance->greet, 'Hello, my name is Joel';
is $instance->can('greet')->(), 'Hello, my name is Joel';
is $instance->yell('can you hear me?'), 'CAN YOU HEAR ME?';
ok $instance->isa($class);
ok !$instance->isa('Horse');

my $subclass = extend $class => via {
  my ($self) = @_;
  $self->(sing => sub { "lalala $_[1]" });
};
ok $subclass->isa($class);

my $singer = $subclass->new;
ok $singer->isa($class);
ok $singer->isa($subclass);
is $singer->sing('lululu'), 'lalala lululu';

done_testing;

