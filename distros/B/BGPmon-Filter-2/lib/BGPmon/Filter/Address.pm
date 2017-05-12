package BGPmon::Filter::Address;
our $VERSION = '2.00';
use strict;
use warnings;
use constant TRUE => 1;
use constant FALSE => 0;
use Net::IP;




=head1 NAME

BGPmon::Filter::Address

This module is an object that keeps track of an IPv4 or IPv6 address.
It can compare two a prefix to itself to see if it belongs to that
prefix.

=cut

=head1 SYNOPSIS

use BGPmon::Filter::Address.pm

#To make an object with an IPv4 address, the first argument must be 4,
#followed by the address you wish to store.

my $ipv4_addr = new BGPmon::Filter::Address(4, "192.168.1.135");

#To make an object with an IPv6 address, the first argument must be 6.
#If you want to compare it with other IPv6 prefixes and return true when
#comparing for matches with less specific prefixes, the last argument must
#be 0.

my $ipv6_addr = new BGPmon::Filter::Address(6, "2000:0a00::");

#To compare the address to a prefixe, take the object and pass in the 
#prefix you want to compare it to.

#The following will return true since 192.168.1.135 is in 192.168.1.0/24.

my $ret_val = $ipv4_addr->matches("192.168.1.0/24"); # $ret_val will be 1


=cut

=head1 EXPORT

new matches getVersion isV6 isV4 toString

=cut

=head1 SUBROUTINES/METHODS


=head2 new

This makes a new object.  You must pass in two arguments:

The version - 4 or 6

The address - e.g., "192.168.1.135"


To make an object that is for an IPv4 address of "192.168.1.135",
make the object with the following:

my $ipv4 = new BGPmon::Filter::Address(4, "192.168.1.135");

=cut
sub new{
	my $class = shift;
	my $self = {
		version => shift,
		address => shift,
	};

	my $temp = new Net::IP($self->{address});
	$self->{'netIP'} = $temp;

	bless ($self, $class);

	return $self;
}


=head2 matches

This will take in a prefix of the same type and test if that prefix 
holds this address.

INPUT: A prefix of the same type to be matched to, e.g, "192.168.1.0/24"
OUTPUT: 1 - true, 0 - false

=cut
sub matches{
	my $self = shift;
	my $prefixIn = shift;
	my $inPrefix = new Net::IP($prefixIn);	

	my $compVal = $inPrefix->overlaps($self->{netIP});
	if(!defined($compVal)){
        	return FALSE;
	}
	elsif($compVal == $IP_B_IN_A_OVERLAP){
        	return TRUE;
	}
	else{
		return FALSE;
	}
}

=head2 toString

Will return a string that can be printed in human readable form, e.g.,

192.168.1.35

INPUT: (none)
OUTPUT: A string of characters with information about the address.

=cut
sub toString{
	my $self = shift;
	return $self->{address};
}

=head2 getVersion

Returns the version of IP the prefix is : 4 or 6

=cut
sub getVersion{
	my $self = shift;
	return $self->{version};
}

=head2 isV6

Tests to see if the version specified is of type IPv6

INPUT: (none)
OUTPUT: 1 - true, 0 - false

=cut
sub isV6{
	my $self = shift;
	return $self->{version} == 6;
}

=head2 isV4

Tests to see if the version specified is of type IPv4

INPUT: (none)
OUTPUT: 1 - true, 0 - false

=cut
sub isV4{
	my $self = shift;
	return $self->{version} == 4;
}


1;


=head1 AUTHOR

M. Lawrence Weikum C<< <mweikum@rams.colostate.edu> >>

=cut

=head1 BUGS

Please report any bugs or feature request to C<bgpmon at netsec.colostate.edu>
or through the web interface at at L<http://bgpmon.netsec.colostate.edu>.

=cut

=head1 SUPPORT

You can find documentation on this module with the perldoc command.

        perldoc BGPmon::Filter::Address

=cut

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Colorado State University

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom
the Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.\

File: Address.pm
Authors: M. Lawrence Weikum
Date: 29 January 2013
=cut

