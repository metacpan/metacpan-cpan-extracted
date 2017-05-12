#!perl

use Test::Simple tests => 1;

use AnyEvent::CallbackStack;

my $cs = AnyEvent::CallbackStack->new;
my $cv = AE::cv;

$cs->add( sub { $cv->send( $_[0]->recv ) } );
$cs->start('hello world');
ok($cv->recv eq 'hello world', 'add() before start() works');
