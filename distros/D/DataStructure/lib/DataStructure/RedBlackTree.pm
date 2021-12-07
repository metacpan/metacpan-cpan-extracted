# A red-black binary tree data-structure.
#
# Mostly from the Cormen-Leiserson-Rivest book.

package DataStructure::RedBlackBTree;

use strict;
use warnings;
use utf8;
use feature ':5.24';
use feature 'signatures';
no warnings 'experimental::signatures';

use DataStructure::BTree;
use DataStructure::BTree::Node;

use parent qw(DataStructure::OrderedSet);

our @ISA = ('DataStructure::BTree');

sub new ($class, %options) {
  $options{_context_skip} += 1;
  return $class->SUPER::new(%options);
}

sub insert ($self, $value, $hint = undef) {
  my $n = $self->SUPER::insert($value, $hint);
  $n->{color} = 'R';
  while (defined $n->{parent} && $n->{parent}{color} eq 'R') {
    if ($n->{parent} == $n->{parent}{parent}{left}) {
      my $m = $n->{parent}{parent}{right};
      if ($m->{color} eq 'R') {
        $n->{parent}{color} = 'B';
        $m->{color} = 'B';
        $n->{parent}{parent}{color} = 'R';
        $n = $n->{parent}{parent};
      } else {
        if ($n == $n->{parent}{right}) {
          $n = $n->{parent};
          $n->_rotate_left();
        }
        $n->{parent}{color} = 'B';
        $n->{parent}{parent}{color} = 'R';
        $n->{parent}{parent}->_rotate_right();
      }
    } else {
      my $m = $n->{parent}{parent}{left};
      if ($m->{color} eq 'R') {
        $n->{parent}{color} = 'B';
        $m->{color} = 'B';
        $n->{parent}{parent}{color} = 'R';
        $n = $n->{parent}{parent};
      } else {
        if ($n == $n->{parent}{left}) {
          $n = $n->{parent};
          $n->_rotate_right();
        }
        $n->{parent}{color} = 'B';
        $n->{parent}{parent}{color} = 'R';
        $n->{parent}{parent}->_rotate_left();
      }
    }
  }
  return;
}
