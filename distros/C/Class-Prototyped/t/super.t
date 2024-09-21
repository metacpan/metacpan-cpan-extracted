use strict;
$^W++;
use Class::Prototyped qw(:REFLECT :EZACCESS :OVERLOAD);
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 33
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

my $p1 = Class::Prototyped->new( s1 => sub {'p1.s1'} );

my $p2 = Class::Prototyped->new(
	'*'   => $p1,
	s1    => sub {'p2.s1'},
	's2!' => sub { shift->reflect->super('s1') },
);

my $p2a = $p2->clone();

my $p3 = Class::Prototyped->new(
	'*'   => $p2,
	s1    => sub {'p3.s1'},
	[qw(s2 superable)] => sub { shift->super('s1') },
	[qw(s3 METHOD superable)] => sub { shift->super('s2') },
	[qw(s4 METHOD superable 1)] => sub { join('+', $_[0]->s2, $_[0]->super('s1'), $_[0]->super('s2') ) },
	[qw(s5 superable)] => sub { join('+', $_[0]->s2, $_[0]->super('s2'), $_[0]->super('s1') ) },
	's6'  => sub { join('+', map {$_[0]->$_()} map {"s$_"} (1..5) ) },
);

my $p3a = $p3->clone();

ok( $p1->s1,  'p1.s1' );
ok( $p2->s1,  'p2.s1' );
ok( $p2->s2,  'p1.s1' );
ok( $p2a->s1, 'p2.s1' );
ok( $p2a->s2, 'p1.s1' );
ok( $p3->s1,  'p3.s1' );
ok( $p3->s2,  'p2.s1' );
ok( $p3->s3,  'p1.s1' );
ok( $p3->s4,  'p2.s1+p2.s1+p1.s1' );
ok( $p3->s5,  'p2.s1+p1.s1+p2.s1' );
ok( $p3->s6,  'p3.s1+p2.s1+p1.s1+p2.s1+p2.s1+p1.s1+p2.s1+p1.s1+p2.s1' );
ok( $p3a->s1, 'p3.s1' );
ok( $p3a->s2, 'p2.s1' );
ok( $p3a->s3, 'p1.s1' );
ok( $p3a->s4, 'p2.s1+p2.s1+p1.s1' );
ok( $p3a->s5, 'p2.s1+p1.s1+p2.s1' );
ok( $p3a->s6, 'p3.s1+p2.s1+p1.s1+p2.s1+p2.s1+p1.s1+p2.s1+p1.s1+p2.s1' );


package MyClass;
@MyClass::ISA = qw(Class::Prototyped);

MyClass->addSlots(
	'new!' => sub {
		my $class = shift;
		my $self = $class->super('new');
		$self->reflect->addSlots(
			value => $self->value()*2,
			@_
		);
		return $self;
	},
	value => 2,
	foo => sub { $_[0] },
);

package main;

my $p4 = MyClass->new();
ok( $p4->value, 4 );



MyClass->value(3);

my $p5 = MyClass->new();
ok( $p4->value, 4 );
ok( $p5->value, 6 );

Class::Prototyped->newPackage('MyClass::Sub',
	'*' => 'MyClass',
	[qw(new superable)] => sub {
		my $class = shift;
		my $self = $class->super('new', @_);
		$self->value($self->value()+5);
		return $self;
	},
	[qw(foo superable)] => sub {
		'Supered: '.(shift->reflect->super('foo'));
	},
);

my $p6 = MyClass::Sub->new();
ok( $p4->value, 4 );
ok( $p5->value, 6 );
ok( $p6->value, 11);

my $p7 = MyClass::Sub->new(value => 20);
ok( $p7->value, 25);

my $mcs_dump = Data::Dumper->Dump([MyClass::Sub->reflect->getSlots(undef, 'rotated')]);
{
	my $np3 = bless {}, 'MyClass::Sub';
	ok( $np3->foo,  'Supered: '.$np3 );
	ok( Data::Dumper->Dump([$np3->reflect->getSlots(undef, 'rotated')]), $mcs_dump);
}
ok( Data::Dumper->Dump([MyClass::Sub->reflect->getSlots(undef, 'rotated')]), $mcs_dump);

MyClass::Sub->clonePackage('MyClass::SubClone');

my $p8 = MyClass::Sub->new();
my $p9 = MyClass::SubClone->new();

ok( $p4->value, 4 );
ok( $p5->value, 6 );
ok( $p6->value, 11);
ok( $p8->value, 11);
ok( $p9->value, 11);

my $mcsc_dump = Data::Dumper->Dump([MyClass::SubClone->reflect->getSlots(undef, 'rotated')]);
ok($mcs_dump, $mcsc_dump);


# vim: ft=perl
