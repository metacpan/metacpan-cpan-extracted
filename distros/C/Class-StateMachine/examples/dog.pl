#!/usr/bin/perl

use 5.010;
use strict;
# use warnings;
use mro;

package Dog;
use parent 'Class::StateMachine';

my %valid_states = map { $_ => 1 } qw( happy
                                       angry
                                       tired
                                       injuried );

sub new {
    my ($class, $name) = @_;
    my $dog = { name => $name };
    Class::StateMachine::bless($dog, $class, 'happy');
}

sub check_state {
    $valid_states{$_[1]} ||
        shift->maybe::next::method(@_); # other valid states may be defined
                                        # elsewhere in the hierarchy
                                        # tree!
}

sub on_touched_head :OnState('happy') { shift->move_tail }
sub on_touched_head :OnState('angry') { shift->bite }
sub on_touched_head :OnState(__any__) {} # otherwise do nothing

sub enter_state :OnState(angry) {
    my $self = shift;
    $self->bark;
    $self->maybe::next::method(@_)
}

sub move_tail { say "$_[0]{name}: my tail is moving" }
sub bite { say "$_[0]{name}: augch!!!" }
sub bark { say "$_[0]{name}: guau!, guau!" }

package AngryDog;
BEGIN { our @ISA = 'Dog' }

sub new {
    my $class = shift;
    my $dog = $class->SUPER::new(@_);
    $dog->state('angry');
    $dog
}

sub enter_state :OnState(__any__) {
    my ($self, $new_state) = @_;
    say "$_[0]{name} doesn't like being $new_state";
    $self->state('angry'); # that would reset the state to angry!
}


package main;

my $dog = Dog->new('Oscar');
$dog->on_touched_head;
$dog->state('angry');
$dog->on_touched_head;

my $angry_dog = AngryDog->new('Ion');
$angry_dog->on_touched_head;
$angry_dog->state('angry');
$angry_dog->on_touched_head;
$angry_dog->state('happy');
$angry_dog->on_touched_head;
