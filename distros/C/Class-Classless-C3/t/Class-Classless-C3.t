use strict;
use Test::More tests=>19;
use_ok('Class::Classless::C3');

my $a = Class::Classless::C3->new('a');

is( ref $a, 'Class::Classless::C3',	'blessed object');
is( $a->meta->name, 	'a',		'name assigned');

$b = $a->new;

is( ref $b, 'Class::Classless::C3',	'b blessed');
like( $b->meta->name, qr/\d/,		'not named a');

is( $b->meta->parent->meta->name, 'a',	'b inherits from a');

$a->meta->addmethod( 'test' => sub {
	my $self = shift;
	return join ',','a',$self->NEXT;
});

$b->meta->addmethod( 'test' => sub {
	my $self = shift;
	return join ',','b',$self->NEXT;
});

is( $a->test, 'a',			'a test method');
is( $b->test, 'b,a',			'b test method');

{
package Test::Inherit;
use base qw(Class::Classless::C3);

sub test
{
	my $self = shift;
	return join ',','base',$self->NEXT();
}
};

my $t = Test::Inherit->Class::Classless::C3::Meta::declassify();

my $m = $t->new('m',
 'test' => sub {
	my $self = shift;
	return join ',','m',$self->NEXT;
});

is( $m->test, 'm,base',			'inherited base class');



my $z = Class::Classless::C3->new('z');
my $x = $z->new('x');
my $y = $z->new('y');
my $w = $x->new('w');

my $ww = $w->new('ww');
$ww->can('x');
is( $ww->meta->show_c3cache, 'ww,w,x,z,ROOT', 'c3cache');
$w->meta->addparent($y);
$ww->can('x');
is( $ww->meta->show_c3cache, 'ww,w,x,y,z,ROOT', 'c3cache changed');

is( join(',', map { $_->meta->name } $w->meta->parents ), 'x,y', 'multiple parents');

$w->meta->addmethod( 'test' => sub {
	my $self = shift;
	return join ',','w',$self->NEXT;
});

$x->meta->addmethod( 'test' => sub {
	my $self = shift;
	return join ',','x',$self->NEXT;
});

$y->meta->addmethod( 'test' => sub {
	my $self = shift;
	return join ',','y',$self->NEXT;
});

$z->meta->addmethod( 'test' => sub {
	my $self = shift;
	return join ',','z',$self->NEXT;
});

is( $w->test, 'w,x,y,z',		'c3 multiple inheritance');

diag( join(',',map {$_->meta->name} @{$Class::Classless::C3::c3cache{'w'}}) );

ok($w->isa($z),				'isa');
ok(!$z->isa($w),			'not isa');

ok($w->isa('z'),			'isa by name');
ok(!$z->isa('w'),			'not isa by name');

{
my $trace;
local $Class::Classless::C3::trace = \$trace;
$w->test;
like($trace, qr/called w->test/,	'trace');
diag $trace;
};

ok( $x->can('NEXT'),			'can(NEXT)');

