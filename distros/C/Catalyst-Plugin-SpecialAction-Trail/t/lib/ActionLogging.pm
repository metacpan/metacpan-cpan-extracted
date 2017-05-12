package ActionLogging;

use Moose::Role;
use namespace::autoclean;

has called_actions => (
  isa     => 'ArrayRef[Str]',
  is      => 'rw',
  default => sub { [] },
);

before execute => sub {
  my ($c, $class, $action) = @_;

  push @{ $c->called_actions }, join '::', $class, $action->name
    if $action->name !~ /^_/;
};

1;
