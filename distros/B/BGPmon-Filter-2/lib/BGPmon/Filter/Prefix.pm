package BGPmon::Filter::Prefix;
our $VERSION = '2.00';
use strict;
use warnings;
use constant TRUE => 1;
use constant FALSE => 0;
use Net::IP;




=head1 NAME

BGPmon::Filter::Prefix

This module is an object that keeps track of an IPv4 or IPv6 prefix.
It can compare two different prefixes and find if they're equivilent,
if one is more specific than the other, or if one is less specific than
the other.

=cut

=head1 SYNOPSIS

use BGPmon::Filter::Prefix.pm

#To make an object with an IPv4 address, the first argument must be 4.
#If you want to compare it with other IPv4 prefixes and return true when
#comparing for matches with more specific prefixes, the last argument must
#be a posive number.

my $ipv4_prefix = new BGPmon::Filter::Prefix(4, "192.168.1.0/24", 1);

#To make an object with an IPv6 address, the first argument must be 6.
#If you want to compare it with other IPv6 prefixes and return true when
#comparing for matches with less specific prefixes, the last argument must
#be 0.

my $ipv6_prefix = new BGPmon::Filter::Prefix(6, "2000:0a00::/32", 0);

#To compare two prefixes, take the object and pass in the prefix you want to
#compare it to.

#The following will return true since we're passing in a more specific prefix.

my $ret_val = $ipv4_prefix->matches("192.168.1.128/25"); # $ret_val will be 1

#The following will return true since we're passing in a less specific prefix.

my $ret_val6 = $ipv6_prefix->matches("2000::/16"); # $ret_val6 will be 1


=cut

=head1 EXPORT

new matches getVersion isV6 isV4 toString

=cut

=head1 SUBROUTINES/METHODS


=head2 new

This makes a new object.  You must pass in three arguments:

The version - 4 or 6

The prefix - e.g., "192.168.1.0/24"

The boolean for more specific matching - e.g., 1 for true, 0 for false


To make an object that is for an IPv4 address of "192.168.1.0/24" that wants
to filter more specific or equivilent prefixes, make the object with the 
following:

my $ipv4 = new BGPmon::Filter::Prefix.pm(4, "192.168.1.0/24", 1);

=cut
sub new{
	my $class = shift;
	my $self = {
		version => shift,
		prefix => shift,
		moreSpecific => shift,
	};

	my $temp = new Net::IP($self->{prefix});
	$self->{'netIP'} = $temp;

	bless ($self, $class);

	return $self;
}




sub canAggregateWith{
	my $self = shift;
	my $possPart = shift;

	my $netPref = $self->{'netIP'};
	my $partPref = $possPart->{'netIP'};
	my $res = $netPref->aggregate($partPref);

	return TRUE if defined $res;

	return FALSE;
}


sub getAggregate{
	my $self = shift;
	my $possPart = shift;

	my $netPref = $self->{'netIP'};
	my $partPref = $possPart->{'netIP'};
	my $res = $netPref->aggregate($partPref);
	$res = $res->prefix();

	return $res;
}


sub matchSpecific{
	my $self = shift;
	my $partner = shift;
	return TRUE if $self->{moreSpecific} == $partner->{moreSpecific};
	return FALSE;
}
=comment
sub equals{
	my ($self, $partner) = @_;
	#my $partner = shift;
	
	if($self->{prefix} eq $partner->{prefix} and $self->{moreSpecific} eq $partner->{moreSpecific}){
		return TRUE;
	}
	return FALSE;
}
=end

=head2 matches

This will take in another prefix of the same type and test if the prefix is
equivilent, more specific, or less specific.  

Note that if the object is made with the "more specific" set at true, then
this will return true if the given prefix is more specific or equivilent.


INPUT: A prefix of the same type to be matched to, e.g, "192.168.1.128/25"
OUTPUT: 1 - true, 0 - false

=cut
sub matches{
	my $self = shift;
	my $prefixIn = shift;
	
	if($prefixIn eq $self->{prefix}){
		return TRUE;
	}


	if($self->{moreSpecific}){
		return $self->moreSpecific($prefixIn);
	}
	else{
		return $self->lessSpecific($prefixIn);
	}

}


#comment
#Will test to see if the given prefix is equivilent or more specific than
#the one stored.
#cut
sub moreSpecific{
	my $self = shift;
	my $prefixIn = new Net::IP(shift);
	my $myNetIP = $self->{netIP};

	my $compVal = $myNetIP->overlaps($prefixIn);
	if(!defined($compVal)){
		return FALSE;
	}       
	elsif($compVal == $IP_B_IN_A_OVERLAP){
		return TRUE; 
	}       
	elsif($compVal == $IP_IDENTICAL){
		return TRUE; 
	}       
	else{   
		return FALSE;
	}
}

#comment
#Will test to see if the given prefix is equivilent or less specific than
#the one stored.
#=cut
sub lessSpecific{
	my $self = shift;
	my $prefixIn = new Net::IP(shift);
	my $myNetIP = $self->{netIP};

	my $compVal = $myNetIP->overlaps($prefixIn);
	if(!defined($compVal)){
		return FALSE;
	}       
	elsif($compVal == $IP_A_IN_B_OVERLAP){
		return TRUE; 
	}       
	elsif($compVal == $IP_IDENTICAL){
		return TRUE; 
	}       
	else{   
		return FALSE;
	}
}

=head2 toString

Will return a string that can be printed in human readable form, e.g.,

192.168.1.0/24 ms

ms - more specific
ls - less specific

INPUT: (none)
OUTPUT: A string of characters with information about the object.

=cut
sub toString{
	my $self = shift;
	my $a = $self->{prefix};
	my $b = $self->{moreSpecific};
	my $toReturn = "";
	$toReturn .= $a;
	if($b){
		$toReturn .= " ms";
	}
	else{
		$toReturn .= " ls";
	}

	return $toReturn;
}


sub prefix{
	my ($self) = shift;
	return $self->{prefix};
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

        perldoc BGPmon::Filter::Prefix

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

File: Prefix.pm

Authors: M. Lawrence Weikum

Date: 6 September 2012
=cut

