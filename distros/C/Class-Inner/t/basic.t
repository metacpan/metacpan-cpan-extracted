#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;

BEGIN { use_ok( 'Class::Inner' ); }

package Parent;

sub new { my $class = shift; bless [@_], $class }
sub a { 'A' };
sub b { 'B' };
sub poly { $_[0]->b }

package main;

ok(my $p = Parent->new, "Parent can instantiate");
ok($p->isa('Parent'),   '$p is a Parent');
is($p->a(),    'A',        '$p->a is A');
is($p->b(),    'B',        '$p->b is B');
is($p->poly(), 'B',        '$p->poly is B');

my $ic = Class::Inner->new(
             parent => 'Parent',
             methods => { b => sub {
                                   my $self = shift;
                                   lc($self->SUPER);
                               },
                          c => sub { 'C' } },
             args => [qw/a b c/]
         );

ok(ref($ic) && $ic->isa('Parent'),
	                '$ic is a Parent');
my $ic_class = ref($ic);	# Remember this for later...
ok(eq_array($ic, [qw/a b c/]), 'constructor test');

is($ic->a(), 'A',         '$ic->a is A');
is($ic->b(), 'b',         '$ic->b is b');
is($ic->c(), 'C',         '$ic->c is C');
is($ic->poly(), 'b',      '$ic->poly is b');

# Check that destruction works.

undef $ic;
{
    no strict 'refs';
    is_deeply(\%{"${ic_class}::"}, {}, 'Class dismissed');
}
