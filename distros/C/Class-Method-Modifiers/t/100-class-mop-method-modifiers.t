
# taken from Class::MOP's test suite, cut down to the interesting bits I haven't
# necessarily tested yet

use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
my @tracelog;

package GreatGrandMyParent;
sub new { bless {}, shift }
sub method { 4 }
sub wrapped { push @tracelog => 'primary' }

package GrandMyParent;
use Class::Method::Modifiers;
our @ISA = 'GreatGrandMyParent';
around method => sub { (3, $_[0]->()) };

package MyParent;
use Class::Method::Modifiers;
our @ISA = 'GrandMyParent';
around method => sub { (2, $_[0]->()) };

package Child;
use Class::Method::Modifiers;
our @ISA = 'MyParent';
around method => sub { (1, $_[0]->()) };

package GrandChild;
use Class::Method::Modifiers;
our @ISA = 'Child';
around method => sub { (0, $_[0]->()) };

before wrapped => sub { push @tracelog => 'before 1' };
before wrapped => sub { push @tracelog => 'before 2' };
before wrapped => sub { push @tracelog => 'before 3' };

around wrapped => sub { push @tracelog => 'around 1'; $_[0]->() };
around wrapped => sub { push @tracelog => 'around 2'; $_[0]->() };
around wrapped => sub { push @tracelog => 'around 3'; $_[0]->() };

after wrapped => sub { push @tracelog => 'after 1' };
after wrapped => sub { push @tracelog => 'after 2' };
after wrapped => sub { push @tracelog => 'after 3' };

package main;

my $gc = GrandChild->new();
is_deeply(
    [ $gc->method() ],
    [ 0, 1, 2, 3, 4 ],
    '... got the right results back from the around methods (in list context)');

is(scalar $gc->method(), 4, '... got the right results back from the around methods (in scalar context)');

$gc->wrapped();
is_deeply(
    \@tracelog,
    [
        'before 3', 'before 2', 'before 1',  # last-in-first-out order
        'around 3', 'around 2', 'around 1',  # last-in-first-out order
        'primary',
        'after 1', 'after 2', 'after 3',     # first-in-first-out order
    ],
    '... got the right tracelog from all our before/around/after methods');


done_testing;
