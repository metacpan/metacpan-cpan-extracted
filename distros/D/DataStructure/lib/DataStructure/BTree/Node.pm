package DataStructure::BTree::Node;

use strict;
use warnings;
use utf8;
use feature ':5.24';
use feature 'signatures';
no warnings 'experimental::signatures';

use Scalar::Util qw(weaken);

sub new ($class, $tree, $value, $parent = undef, $left = undef, $right = undef) {
  my $self = bless {
    tree => $tree,
    parent => $parent,
    left => $left,
    right => $right,
    value => $value,
  }, $class;
  weaken($self->{tree});
  return $self;
}

sub parent ($self) {
  return $self->{parent};
}


sub left ($self) {
  return $self->{left};
}


sub right ($self) {
  return $self->{right};
}


sub value ($self) {
  return $self->{value};
}

sub next ($self) {
  return unless defined $self->{right};
  return $self->{right}->_min_child();
}

sub prev ($self) {
  return unless defined $self->{left};
  return $self->{left}->_max_child();
}

# Returns the child with the smallest value (possibly itself).
sub _min_child ($self) {
  my $current = $self;
  while (defined $current->{left}) {
    $current = $current->{left};
  }
  return $current;
}

# Returns the child with the biggest value (possibly itself).
sub _max_child ($self) {
  my $current = $self;
  while (defined $current->{right}) {
    $current = $current->{right};
  }
  return $current;
}

# Returns the node with the smallest value bigger than the value of the current
# node (or undef).
sub _succ ($self) {
  return $self->{right}->_min_child() if defined $self->{right};
  my $current = $self;
  while (defined $current->{parent} && $current == $self->{parent}{right}) {
    $current = $self->{parent};
  }
  return $current->{parent};
}

# Requires that defined $self->{right}
sub _rotate_left ($self) {
  my $n = $self->{right};
  $self->{right} = $n->{left};
  return unless defined $n->{left};
  $n->{left}{parent} = $self;
  $n->{parent} = $self->{parent};
  if (defined $self->{parent}) {
    if ($self == $self->{parent}{left}) {
      $self->{parent}{left} = $n;
    } else {
      $self->{parent}{right} = $n;
    }
  } else {
    $self->{tree}{root} = $n;
  }
  $n->{left} = $self;
  $self->{parent} = $n;
  return;
}

# Requires that defined $self->{right}
sub _rotate_right ($self) {
  my $n = $self->{left};
  $self->{left} = $n->{right};
  return unless defined $n->{right};
  $n->{right}{parent} = $self;
  $n->{parent} = $self->{parent};
  if (defined $self->{parent}) {
    if ($self == $self->{parent}{left}) {
      $self->{parent}{left} = $n;
    } else {
      $self->{parent}{right} = $n;
    }
  } else {
    $self->{tree}{root} = $n;
  }
  $n->{right} = $self;
  $self->{parent} = $n;
  return;
}

1;
