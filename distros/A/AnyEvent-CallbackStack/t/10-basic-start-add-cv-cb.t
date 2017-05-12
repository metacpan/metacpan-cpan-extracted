#!perl

use Test::Simple tests => 4;

use AnyEvent::CallbackStack;

my $cs = AnyEvent::CallbackStack->new;
my $cv = AE::cv;

my %foo;

$foo{'bar'} = 'vbar';
$foo{'yohoo'} = 'vyohoo';

$cs->start( %foo );
$cs->add( sub {
	my %foo = $_[0]->recv;
	
	ok($foo{'bar'} eq 'vbar', 'value 0 checked');
	ok($foo{'yohoo'} eq 'vyohoo', 'value 1 checked');
	
	$cs->next( $foo{'bar'}, $foo{'yohoo'} );
});

$cv = $cs->last;

ok('AnyEvent::CondVar' eq ref $cv, 'got last cv');

$cv->cb( sub { my @a = $_[0]->recv; $cv->send( $a[0].$a[1] ) } );

ok($cv->recv eq 'vbarvyohoo', 'got right result');
