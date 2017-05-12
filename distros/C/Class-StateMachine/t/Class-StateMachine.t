#! /usr/bin/perl

use 5.010;

use Test::More tests => 18;
BEGIN { use_ok('Class::StateMachine') };

package SM;

use warnings;
no warnings 'redefine';

use parent 'Class::StateMachine';
__PACKAGE__->set_state_isa(eigth => 'seven');

sub doz : OnState(eigth) { 8 }

sub foo : OnState(one) { 1 }

sub foo : OnState(two) { 2 }

sub foo : OnState(three) { 3 }

sub bar : OnState(__any__) { 'any' }

sub bar : OnState(five, six, seven) { 7 }

my $fuz = 0;
sub fuz : OnState(two) {
    $fuz = 1;
    shift->delay_until_next_state
}
sub fuz : OnState(__any__) { $fuz = 2 }

sub muz : OnState(two) {
    shift->delay_once_until_next_state;
}

sub muz : OnState(__any__) { $fuz++ }

sub enter_state {
    say "enter to: $_[1] from: $_[2]";
}

sub leave_state : OnState(new) {
    say "leaving state new";
}

sub leave_state : OnState(__any__) {
    say "leave from: $_[1] to: $_[2]";
}

sub new {
    my $class = shift;
    Class::StateMachine::bless {@_}, $class;
}

package SM2;

BEGIN { our @ISA = qw(SM) };

sub leave_state : OnState(two) {
    say "leaving state two!";
}

package main;

my $t = SM2->new;
$t->state('one');
is($t->foo, 1, 'one');
is($fuz, 0);
$t->fuz;
is($fuz, 2);
$t->state('five');
is($t->bar, 7, 'multi five');

$t->state('two');
is($t->foo, 2, 'two');
$t->fuz;
is($fuz, 1);

$t->state('three');
is($fuz, 2);
is($t->foo, 3, 'three');

$t->state('two');
is($fuz, 2);
$t->muz;
$t->muz;
is($fuz, 2);

$t->state('three');
is($fuz, 3);

$t->state('sdfkjl');
is($t->bar, 'any', 'any');

ok (!eval { $t->foo; 1 }, 'die on no state-method defined');

$t->state('six');
is($t->bar, 7, 'multi six');

$t->state('eigth');
is($t->bar, 7, 'state deriving');
is($t->doz, 8, 'state deriving - 2');

my @state_isa = $t->state_isa;
is_deeply(\@state_isa, [qw(eigth seven __any__)], 'state_isa');
