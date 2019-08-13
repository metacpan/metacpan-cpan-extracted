use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
my @seen;

package MyParent;
sub new { bless {}, shift }
sub left { push @seen, "orig-left" }
sub right { push @seen, "orig-right" }

package Child;
our @ISA = 'MyParent';
use Class::Method::Modifiers;
before 'left', 'right' => sub { push @seen, 'before' };

package Grandchild;
our @ISA = 'Child';
use Class::Method::Modifiers;
before ['left', 'right'] => sub { push @seen, 'grandbefore' };

package main;

my $child = Child->new();
$child->left;
is_deeply([splice @seen], [qw/before orig-left/], "correct 'left' results");

$child->right;
is_deeply([splice @seen], [qw/before orig-right/], "correct 'right' results");

my $grand = Grandchild->new();
$grand->left;
is_deeply([splice @seen], [qw/grandbefore before orig-left/], "correct 'left' results");

$grand->right;
is_deeply([splice @seen], [qw/grandbefore before orig-right/], "correct 'right' results");

done_testing;
