package CPU::Emulator::DCPU16::Device;
use strict;

=head1 NAME 

CPU::Emulator::DCPU16::Device - generic base memory mapped device for the DCPU16 emulator

=head1 SYNOPSIS

    $cpu->map_device('CPU::Emulator::DCPU16::Device::Console', $start_addr, $end_addr);
    
=head1 DESCRIPTION

This base class should not be used directly - it should be subclassed and get methods should be provided.

=head1 METHODS

=cut


=head2 new <memory reference> <start address> <end address> <options>

Create a new device and map it to the memory.

=cut
sub new {
    my $class = shift;
    my $mem   = shift;
    my $start = shift;
    my $end   = shift;
    my %opts  = @_;
    $opts{_start} = $start;
    $opts{_end}   = $end;
    my $self  = bless \%opts, $class;
    tie $mem->[$_], $class, $_, $self for ($start..$end);
    $self;    
}

=head2 start 

Get the start address of this mapped device
    
=cut
sub start { shift->{_start} }

=head2 end 

Get the end address of this mapped device
    
=cut
sub end { shift->{_end} }

=head2 tick 

Called after each instruction is called

=cut
sub tick {
    my $self = shift;
    # no-op
}

=head2 set <address> <value>

Set the address of the mapped device to value.

=cut
sub set {
    my $self = shift;
    my $addr = shift;
    my $val  = shift;
    # no-op
}

=head2 get <address>

Get the value at address of the mapped device.

=cut
sub get {
    my $self = shift;
    my $addr = shift;
    # no-op
}

sub TIESCALAR {
    my $class = shift;
    my $addr  = shift;
    my $dev   = shift;
    return bless { address => $addr, device => $dev }, $class; # create a proxy
}

sub STORE {
    my $proxy  = shift;
    my $value = shift;
    $proxy->{device}->set($proxy->{address}, $value);
}

sub FETCH {
    my $proxy = shift;
    $proxy->{device}->get($proxy->{address});
}


1;