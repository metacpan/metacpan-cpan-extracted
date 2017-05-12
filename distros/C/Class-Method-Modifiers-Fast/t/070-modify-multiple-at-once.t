#!perl -T
use strict;
use warnings;
use Test::More tests => 2;
my @seen;

package Parent;
sub new { bless {}, shift }
sub left { push @seen, "orig-left" }
sub right { push @seen, "orig-right" }

package Child;
our @ISA = 'Parent';
use Class::Method::Modifiers::Fast;
before 'left', 'right' => sub { push @seen, 'before' };

package main;

my $child = Child->new();
$child->left;
is_deeply(\@seen, [qw/before orig-left/], "correct 'left' results");

@seen = ();
$child->right;
is_deeply(\@seen, [qw/before orig-right/], "correct 'right' results");

