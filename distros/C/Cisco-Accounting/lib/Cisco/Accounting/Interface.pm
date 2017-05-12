package Cisco::Accounting::Interface;

## ----------------------------------------------------------------------------------------------
## Cisco::Accounting::Interface
##
## Cisco::Accounting::Interface object to store information for one interface
##
## $Id: Interface.pm 101 2007-08-03 23:10:17Z mwallraf $
## $Author: mwallraf $
## $Date: 2007-08-04 01:10:17 +0200 (Sat, 04 Aug 2007) $
##
## This program is free software; you can redistribute it and/or
## modify it under the same terms as Perl itself.
## ----------------------------------------------------------------------------------------------


our $VERSION = '1.00';

use strict;
use warnings;
use Carp;
#use Data::Dumper;

my $DEBUG = 0;


sub new {
	my ($this, $id, $interface, $accounting_status) = @_;
	my  $class = ref($this) || $this;
	my  $self = {};
	bless($self, $class);
	
	$self->{'interface'} = $interface;
	$self->{'accounting_status'} = $accounting_status;
	$self->{'id'} = $id;
	$self->{'description'} = "";
	
	&_init($class);
	
	return($self);
} # end sub new


# initialization : set up logging  
sub _init  {
	my $class=shift;
}

##
## return the interface name
##
sub get_interface()  {
	my $self = shift;
	return $self->{'interface'};
}

##
## return the interface status : IP Accounting enabled or disabled ?
##
sub get_accounting_status()  {
	my $self = shift;
	return $self->{'accounting_status'};
}


##
## set the name of the interface
##
sub set_interface()  {
	my $self = shift;
	my $int = shift;
	
	$self->{'interface'} = $int;
}

##
## set the interface status : IP Accounting enabled or disabled
##
sub set_accounting_status()  {
	my $self = shift;
	my $status = shift;
	
	$self->{'set_accounting_status'} = $status;
}

##
## get the id of this interface
##
sub get_id()  {
	my $self = shift;
	
	return $self->{'id'};
}

##
## set the id of this interface
##
sub set_id()  {
	my $self = shift;
	my $id = shift;
	
	$self->{'id'} = $id;
}

##
## get the description if it exists
##
sub get_description()  {
	my $self = shift;
	
	return $self->{'description'};
}

##
## set the interface description if it exists
##
sub set_description()  {
	my $self = shift;
	my $descr = shift;
	
	$self->{'description'} = $descr;
}

1;


__END__

=head1 NAME

Cisco::Accounting::Interface - Container for one interface

=head1 DESCRIPTION

This package is part of Cisco::Accounting. Cisco::Accounting->get_interfaces() will return an array of Interface objects.

=head1 PROCEDURES

=over 4

=item get_id()

Returns the unique id for this interface. This can be used for Cisco::Accounting->enable_accounting() and
Cisco::Accounting->disable_accounting()

=item get_interface()

This returns the actual name of the interface as found on the router or IPCAD host (ex. FastEthernet0/1 or eth0)

=item get_accounting_status()

Returns 0 or 1 depending if IP Accounting is enabled on the interface.

=back

=head1 AUTHOR

Maarten Wallraf, C<< <perl at 2nms.com> >>

=cut
