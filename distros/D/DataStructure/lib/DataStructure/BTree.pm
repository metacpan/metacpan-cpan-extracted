# A binary tree data-structure.
#
# Mostly from the Cormen-Leiserson-Rivest book.

package DataStructure::BTree;

use strict;
use warnings;
use utf8;
use feature ':5.24';
use feature 'signatures';
no warnings 'experimental::signatures';

use DataStructure::BTree::Node;

use parent qw(DataStructure::OrderedSet);

=pod

=head1 NAME

DataStructure::BTree

=head1 SYNOPSIS

A binary tree data-structure, written in pure Perl.

=head1 DESCRIPTION

=head2 CONSTRUCTOR

C<< DataStructure::BTree->new(%options) >>

Creates an empty binary tree.

Available options are:

=over 4

=item cmp

The comparator used for the elements of the tree. Should be a reference to a
sub using C<$a> and C<$b>. Defaults to using C<cmp> if not specified.

=item multiset

Whether several identical values can be stored.

=back

=cut

sub new ($class, %options) {
  my $calling_pkg = caller($options{_context_skip} // 0);
  no strict 'refs';
  return bless {
    size => 0,
    root => undef,
    compare => $options{cmp} // sub { $a cmp $b},
    multi => $options{multiset} // 0,
    a => \*{ $calling_pkg . '::a' },
    b => \*{ $calling_pkg . '::b' },
  }, $class;
}

# Returns a node with the given value or undef.
sub find ($self, $value) {
  my $current = $self->{root};
  local *{$self->{a}} = $value;
  while (defined $current && $current->{value} != $value) {
    local *{$self->{b}} = $current->{value};
    if ($self->{compare}->() < 0) {
      $current = $current->{left};
    } else {
      $current = $current->{right};
    }
  }
  return $current;
}

# Returns the newly inserted node or undef if the value is already present and
# multiset was not passed in the options.
sub insert ($self, $value, $hint = undef) {
  my $new_node = DataStructure::BTree::Node->new($self, $value);
  my $current = $self->{root};
  my $parent = undef;
  local *{$self->{a}} = $value;
  my $c;
  while (defined $current) {
    $parent = $current;
    local *{$self->{b}} = $current->{value};
    $c = $self->{compare}->();
    if ($c < 0) {
      $current = $current->{left};
    } elsif ($c >0 || $self->{multi}) {
      $current = $current->{right};
    } else {
      return;
    }
  }
  $self->{size}++;
  $new_node->{parent} = $parent;
  if (!defined $parent) {
    $self->{root} = $new_node;
  } elsif ($c < 0) {
    $parent->{left} = $new_node;
  } else {
    $parent->{right} = $new_node;
  }
  return $new_node;
}

# Deletes the given node or one node with that value.
# Returns a true value on success and undef if the value is not found.
# Invalidates all node of the tree.
sub delete ($self, $value_or_node) {
  my $node;
  if (ref($value_or_node) && $value_or_node->isa('DataStructure::BTree::Node')) {
    $node = $value_or_node;
    return unless $self == $node->{tree};
  } else {
    $node = $self->find($value_or_node);
    return unless defined $node;
  }
  my $replacement;
  if (defined $node->{left} && defined $node->{right}) {
    $replacement = $node->_succ();  # cannot be null because we have a right child.
  } else {
    $replacement = $node;
  }
  my $new_child;
  if (defined $replacement->{left}) {
    $new_child = $replacement->{left};
  } else {
    $new_child = $replacement->{right};
  }
  $new_child->{parent} = $replacement->{parent} if defined $new_child;
  my $parent = $replacement->{parent};
  if ($parent) {
    if ($replacement == $parent->{left}) {
      $parent->{left} = $new_child;
    } else {
      $parent->{right} = $new_child;
    }
  } else {
    $self->{root} = $new_child;
  }
  $node->{value} = $replacement->{value} if $node != $replacement;
  $self->{size}--;
  return 1;
}

# Returns the smallest node in the tree
sub min ($self) {
  return unless defined $self->{root};
  return $self->{root}->_min_child();
}

# Returns the biggest node in the tree
sub max ($self) {
  return unless defined $self->{root};
  return $self->{root}->_max_child();
}

sub _values ($self) {
  sub node_value ($node) {
    return (undef) unless defined $node;
    return [$node->value(), $node->left(), $node->right()];
  }
  return node_value($self->{root});
}

1;
