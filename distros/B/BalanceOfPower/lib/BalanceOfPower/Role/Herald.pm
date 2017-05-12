package BalanceOfPower::Role::Herald;
$BalanceOfPower::Role::Herald::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;

with 'BalanceOfPower::Role::Reporter';

requires 'get_nation';

sub broadcast_event
{
    my $self = shift;
    my $event = shift;
    my @nations = @_;
    $self->register_event($event);
    for(@nations)
    {
        my $nation = $self->get_nation($_);
        $nation->register_event($event);
    }
}
sub send_event
{
    my $self = shift;
    my $event = shift;
    my @nations = @_;
    for(@nations)
    {
        my $nation = $self->get_nation($_);
        $nation->register_event($event);
    }

}
1;
