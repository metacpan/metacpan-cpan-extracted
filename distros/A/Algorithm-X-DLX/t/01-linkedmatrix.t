#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 5;

use Algorithm::X::LinkedMatrix;
use Algorithm::X::ExactCoverProblem;

# Tests
subtest 'Empty matrix test' => sub {
  plan tests => 4;
  my $M = Algorithm::X::LinkedMatrix->new(Algorithm::X::ExactCoverProblem->new());
  my $root = $M->root_id();
  is($root, $M->L($root), 'no column at left');
  is($root, $M->R($root), 'no column at right');
  is($root, $M->U($root), 'self pointer up');
  is($root, $M->D($root), 'self pointer down');
};

subtest 'Positive width without rows test' => sub {
  my $M = Algorithm::X::LinkedMatrix->new(Algorithm::X::ExactCoverProblem->new(1));
  my $root = $M->root_id();
  isnt($root, $M->L($root), 'column head exists');
};

subtest 'Small matrix 0' => sub {
  #     v          v
  # > [root] <-> [col] <
  #     ^          ^
  plan tests => 11;
  my $M = Algorithm::X::LinkedMatrix->new(Algorithm::X::ExactCoverProblem->dense([[0]]));
  my $root = $M->root_id();
  my $col = $M->R($root);
  isnt($root, $col, 'column head exists');

  is($col,  $M->L($root), 'column at left');
  is($col,  $M->R($root), 'column at right');
  is($root, $M->U($root), 'self pointer up');
  is($root, $M->D($root), 'self pointer down');

  is($root, $M->L($col), 'first head to root');
  is($root, $M->R($col), 'first head wraps to root');
  is($col,  $M->U($col), 'self pointer up, no row');
  is($col,  $M->D($col), 'self pointer down, no row');

  is(0,     $M->S($col), 'column is empty');
  is($col,  $M->C($col), 'already are at head');

};

subtest 'Small matrix 1' => sub {
  #     v          v
  # > [root] <-> [col] <
  #     ^          ^
  #                |
  #                v
  #            > [node] <
  #                ^
  plan tests => 16;
  my $M = Algorithm::X::LinkedMatrix->new(Algorithm::X::ExactCoverProblem->dense([[1]]));
  my $root = $M->root_id();
  my $col = $M->R($root);
  my $node = $M->D($col);
  isnt($col,  $root, 'column head is present');
  isnt($col,  $node, 'node is present');
  isnt($node, $root, 'node is really a 3rd one');

  is($col,   $M->L($root), 'root to rightmost head');
  is($col,   $M->R($root), 'root to leftmost head');
  is($root,  $M->U($root), 'self pointer up');
  is($root,  $M->D($root), 'self pointer down');

  is($root,  $M->L($col), 'connect to root');
  is($root,  $M->R($col), 'rightmost head wraps to root');
  is($node,  $M->U($col), 'head to last row');
  is($node,  $M->D($col), 'head to first row');


  is(1,      $M->S($col), 'column has 1 row');
  is($col,   $M->C($col), 'col is the column head');
  is(1,      $M->S($node), 'column has 1 row');
  is(0,      $M->Y($node), 'index of single row');
  is($col,   $M->C($node), 'head of single column');
};

subtest 'Small matrix 11' => sub {
  #     v          v           v
  # > [root] <-> [col1 ] <-> [col2 ] <
  #     ^          ^           ^
  #                |           |
  #                v           v
  #            > [node1] <-> [node2] <
  #                ^           ^
  plan tests => 31;
  my $M = Algorithm::X::LinkedMatrix->new(Algorithm::X::ExactCoverProblem->dense([[1, 1]]));
  my $root = $M->root_id();
  my $col1 = $M->R($root);
  my $col2 = $M->R($col1);
  my $node1 = $M->D($col1);
  my $node2 = $M->D($col2);
  isnt($col1,  $col2, '2 col heads');
  isnt($col1,  $node1, 'col 1 header ne node 1');
  isnt($col2,  $node2, 'col 2 header ne node 2');

  is(1,       $M->S($col1), '1 node in col 1');
  is(1,       $M->S($col2), '1 node in col 2');
  is($col1,   $M->C($node1), 'node 1 head');
  is($col2,   $M->C($node2), 'node 2 head');
  is(0,       $M->Y($node1), 'row of node 1');
  is(0,       $M->Y($node2), 'row of node 2');
  is(0,       $M->X($node1), 'col of node 1');
  is(1,       $M->X($node2), 'col of node 2');

  is($col2,   $M->L($root), 'root to rightmost head');
  is($col1,   $M->R($root), 'root to leftmost head');
  is($root,   $M->U($root), 'self pointer up');
  is($root,   $M->D($root), 'self pointer down');

  is($root,   $M->L($col1), 'leftmost head to root');
  is($col2,   $M->R($col1), 'inter head pointer');
  is($node1,  $M->U($col1), 'head to last node in column');
  is($node1,  $M->D($col1), 'head to first node in column');

  is($col1,   $M->L($col2), 'inter head pointer');
  is($root,   $M->R($col2), 'rightmost head to root');
  is($node2,  $M->U($col2), 'head to last node in column');
  is($node2,  $M->D($col2), 'head to last node in column');

  is($node2,  $M->L($node1), 'prev node in row');
  is($node2,  $M->R($node1), 'next node in row');
  is($col1,   $M->U($node1), 'first node to head');
  is($col1,   $M->D($node1), 'last node to head');

  is($node1,  $M->L($node2), 'prev node in row');
  is($node1,  $M->R($node2), 'next node in row');
  is($col2,   $M->U($node2), 'first node to head');
  is($col2,   $M->D($node2), 'last node to head');
};

done_testing();
