package CPU::Emulator::DCPU16::Device::Console;
use strict;
use base qw(CPU::Emulator::DCPU16::Device);

=head1 NAME 

CPU::Emulator::DCPU16::Device::Console - mapped console device for the DCPU16 emulator 

=head1 SYNOPSIS

    $cpu->map_device('CPU::Emulator::DCPU16::Device::Console', $start_addr, $end_addr);
    
=head1 DESCRIPTION

=head1 METHODS

=cut

=head2 new <memory reference> <start address> <end address> <options>

Create a new console

=cut
sub new {
    my $self = shift->SUPER::new(@_);
    $self->{_console} = ""x($self->end-$self->start);
    $self;
}

=head2 set <address> <value>

Set the address of the mapped device to value.

=cut
sub set {
    my $self = shift;
    my $addr = shift;
    my $val  = shift;
    substr $self->{_console}, $addr-$self->start, 1, chr($val);
}

=head2 get <address>

Get the value at address of the mapped device.

=cut
sub get {
    my $self = shift;
    my $addr = shift;
    ord substr $self->{_console}, $addr-$self->start, 1;
}

=head2 tick 

Called after each instruction is called.

Prints out the current console.

=cut
sub tick {
    my $self = shift;
    print "\r".$self->{_console} if defined $self->{_console};
}

sub DESTROY {
    my $self = shift;
    print "\r".$self->{_console}."\n" if defined $self->{_console};
}

1;
