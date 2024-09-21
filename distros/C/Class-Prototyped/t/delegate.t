use strict;
$^W++;
use Class::Prototyped qw(:EZACCESS :SUPER);
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 14;
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

package A;
sub a {
	my $self = shift;
	(ref($self) ? $self->name : $self) . 'A.a'
}

package main;

my $p1 = Class::Prototyped->new(
	name => 'p1',
	m1   => sub { $_[0]->name . ".m1" },
);

my $p2 = Class::Prototyped->new(
	name => 'p2',
	m2   => sub { $_[0]->name . ".m2" },
	m2a  => sub { $_[0]->name . ".m2a" },
);

my $p3 = Class::Prototyped->new(
	name      => 'p3',
	'parent*' => $p1,
	p2        => $p2,
	s1        => sub {},
);

ok( $p1->m1,  'p1.m1' );
ok( $p2->m2,  'p2.m2' );
ok( $p2->m2a, 'p2.m2a' );
ok( $p3->m1,  'p3.m1' );    # inheritance

$p3->reflect->delegate(
	m1  => 'parent*',
	m2  => $p2,
	m2a => 'p2',
	m3  => [ $p1, 'm1' ],
	m3a => [ 'parent*', 'm1' ],
	m4  => [ $p2, 'm2' ],
	m4a => [ 'p2', 'm2a' ],
);

ok( $p3->m1,  'p1.m1' );    # delegation
ok( $p3->m2,  'p2.m2' );
ok( $p3->m3,  'p1.m1' );
ok( $p3->m3a, 'p1.m1' );
ok( $p3->m4,  'p2.m2' );
ok( $p3->m4a, 'p2.m2a' );

# detect exceptions
eval { $p3->reflect->delegate( m9 => 's1' ) };
ok( $@ =~ /delegate to a subroutine/ );

eval { $p3->reflect->delegate( m1 => 'p1' ) };
ok( $@ =~ /conflict with existing/ );

my $p4 = Class::Prototyped->new(
	name      => 'p4',
	'parent*' => 'A',
);

ok( $p4->a, 'p4A.a' );
$p4->reflect->delegate( 'b' => [ 'parent*', 'a' ] );
ok( $p4->b, 'AA.a' );

# vim: ft=perl
