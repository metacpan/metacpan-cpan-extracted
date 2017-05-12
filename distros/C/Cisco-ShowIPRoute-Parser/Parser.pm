
=head1 NAME

Cisco::ShowIPRoute::Parser - parse Cisco 'show ip route' command

=head1 SYNOPSIS

	use Cisco::ShowIPRoute::Parser;

	# Router.log holds the output from 'show ip route'
	my $log = 'Router.log';
	my $r = new Cisco::ShowIPRoute::Parser($log);

	my $dest   = '10.159.25.44';
	my @routes = $r->getroutes($dest);

	print "@routes\n";

=head1 DESCRIPTION

This File contains the encapsulation of Raj's route parser. It will
parse the output from a Cisco 'show ip route' command and return all
the routes to a specified IP address.

When collecting the routes please ensure it is in decimal format. This
can be enabled by doing the following at the router prompt:

	term len 0
	terminal ip netmask-format decimal
	show ip route

=head1 Methods

=cut

package Cisco::ShowIPRoute::Parser;

use 5.006;
use strict;
use warnings;

require DynaLoader;
use AutoLoader;

our $VERSION = 1.02;
our @ISA = qw(DynaLoader);
bootstrap Cisco::ShowIPRoute::Parser $VERSION;


=head2 new()

=over 4

=item Args: 

the log file as a string

=item Rtns: 

Handle to our object.

=item Description:


Define some initial states and open the log file that is to be used
when parsing routes       
       
=back

=cut

our %netmask_table = (
    '0'   => '0.0.0.0',
    '1'   => '128.0.0.0',
    '2'   => '192.0.0.0',
    '3'   => '224.0.0.0',
    '4'   => '240.0.0.0',
    '5'   => '248.0.0.0',
    '6'   => '252.0.0.0',
    '7'   => '254.0.0.0',
    '8'   => '255.0.0.0',
    '9'   => '255.128.0.0',
    '10'  => '255.192.0.0',
    '11'  => '255.224.0.0',
    '12'  => '255.240.0.0',
    '13'  => '255.248.0.0',
    '14'  => '255.252.0.0',
    '15'  => '255.254.0.0',
    '16'  => '255.255.0.0',
    '17'  => '255.255.128.0',
    '18'  => '255.255.192.0',
    '19'  => '255.255.224.0',
    '20'  => '255.255.240.0',
    '21'  => '255.255.248.0',
    '22'  => '255.255.252.0',
    '23'  => '255.255.254.0',
    '24'  => '255.255.255.0',
    '25'  => '255.255.255.128',
    '26'  => '255.255.255.192',
    '27'  => '255.255.255.224',
    '28'  => '255.255.255.240',
    '29'  => '255.255.255.248',
    '30'  => '255.255.255.252',
    '31'  => '255.255.255.254',
    '32'  => '255.255.255.255',
);

sub new
{
	my $class = shift;
	$class = ref($class) || $class;
	my $self  = {
		'log'			=>	$_[0],
		'bestRoute'		=>	[],
		'realRoutes'	=> 	[],
		'connInterface'	=> 	[],
		'bestMask'		=>	0
	};

	# This came from Damian Conway
	my $digit        =  q/(?:25[0-5]|2[0-4]\d|[0-1]??\d{1,2})/;
    $self->{'re'}     = "$digit\\.$digit\\.$digit\\.$digit";

	# We reduced the RE to this as it is safe to assume we have valid IPs
	# coming back from the router. If your paranoid then just comment out
	# this line. The code will run much slower though! You have been
	# warned!
    $self->{'re'}     = '\d+\.\d+\.\d+\.\d+';

	my $log = $self->{'log'};
	open(L, "< $log") || die "Can't open $log for read";
	@{$self->{'lines'}} = <L>;
	close L;

    # Fix the problem with non decimal netmasks. This is a real hach XXX
    # 20.3/24  becomes 20.3 255.255.255.0
    grep {s%(\d+\.\d+)/(\d+) %$1 $netmask_table{$2} %} @{$self->{'lines'}};

	bless($self,$class);
	return $self;
}

=head2 getroutes()

=over 4

=item Args: 

the IP address to get the routes for as a string

=item Rtns: 

An array of IP addresses, or "directly connected..." messages.

Or a null list if no routes found

=item Description:


We call ipRouteCheck() and routeIterate() to find all the routes. This is
the main interface. You shouldn't need any other methods.
       
=back

=cut

sub getroutes
{
	my $self = shift;
	$self->{'ip'} = shift || die;

	$self->{'bestRoute'}     = [];
	$self->{'realRoutes'}    = [];
	$self->{'connInterface'} = [];
	$self->{'bestMask'}      = 0;

	$self->ipRouteCheck($self->{'ip'},1,$self->{'lines'});
	$self->routeIterate();

	if($self->{'realRoutes'}[0])
	{
		return @{$self->{'realRoutes'}};
	}
	else
	{
		return();
	}
}

# Slow unused code to do a network check. You can use this if you like.
# If you don't have C compiler just find netCheck further down and
# uncomment it. Make sure you comment out the call to NetCheck.
sub netCheck {
	my $network = $_[1];
	my @mask = split(/\./,$_[2]); 
	my @destination = split(/\./,$_[3]);

	my $logicalAnd = sprintf("%d.%d.%d.%d",
						($destination[0] + 0 )&($mask[0] + 0),
						($destination[1] + 0 )&($mask[1] + 0),
						($destination[2] + 0 )&($mask[2] + 0),
						($destination[3] + 0 )&($mask[3] + 0));

	# MATCH
	if ($network eq $logicalAnd) {
		return 1;
	}
	else {
		return 0;
	}
}

#converts from decimal to bitcount.
sub decimalToBitcount  {

    my $mask = $_[1]; # eg 255.255.255.0
	my @octect   = split(/\./,$mask);

	return ($octect[0] + $octect[1] + $octect[2] + $octect[3]) ;
}

#Due to the classless nature, we follow the longest match rule
#return TRUE, if the proposed route has a higher mask than current
sub bestMaskProc {
	my $self = shift;
	my $tmpMask = $self->decimalToBitcount($_[0]);
	
	if ($self->{'bestMask'} == 0 ) {
		$self->{'bestMask'} = $tmpMask;
		return 1;
	}
	elsif ($self->{'bestMask'} < $tmpMask) {
		$self->{'bestRoute'} = [];
		$self->{'bestMask'}  = $tmpMask;
		return 1;
	}
	elsif ($self->{'bestMask'} == $tmpMask) {
		return 1; #means more than 1 nexthop for destination
	}
	else {
		return 0;
	}
}

#Insert the best routes(so far) into the array
sub insertRoute { 
	my $self = shift;
	push(@{$self->{'bestRoute'}}, @_); 
}

#The following subroutine looks through the lines and finds the best route
#Best routes are stored in bestRoutes and highest bitmask is found
#in reference bitMask.
sub ipRouteCheck {

	my $self         = shift;
	my $destination  = shift;
	my $getConnected = shift;
	my $lines        = shift;
	my $mask         = 0;
	my $network      = "0.0.0.0";
    my $re           = $self->{'re'};
	my $conCheck     = "";
	my $nextHop      = "";
	
	for (@$lines) {
		my $line = $_ ;

		if ($line =~ m/($re) ($re )?/o) {
			$network = $1;
			if ($2) {
				$mask    = $2;
				chop($mask);
			}
		}

		# First RE is for dynamic route, 2nd for obvious, 3rd for
		# static routes
		if ( ($line =~ m/via ($re),\s+.*$/o) || 
		     ($line =~ m/(is directly connected.*)$/o) || 
			 ($line =~ m/via ($re)$/o) ) 
		{
			$nextHop = $1;
			#pushes Connected interfaces into another
			#array to simplify searches
			if ($getConnected == 1) {
				push (@{$self->{'connInterface'}},"$network $mask $nextHop") if ((substr $nextHop, 0, 2) eq "is"); 
			}	

			# We use fast C code now. Use the line below if you can't
			# compile netCheck module up
			#if ($self->netCheck($network, $mask, $destination)) {
			if (&NetCheck($network, $mask, $destination)) {
				#print "Net: $network, Mask: $mask, Dest: $destination\n";
				if ($self->bestMaskProc($mask)) {
					$self->insertRoute($nextHop);
				}
			}
		}
	}	
}

sub routeIterate  {

		my $self = shift;
        my @validRoutes = @{$self->{'bestRoute'}};
        my @output = ();
        my $length = 0;
		my $route  = '';

        my $count = 0;


        while ($route = shift(@validRoutes) )  {

			if ($route =~ m/is directly connected.*$/) {
				push (@{$self->{'realRoutes'}}, $route);
				next;
			}

			for (;;) {
				@{$self->{'bestRoute'}} = ();
				$self->{'bestMask'} = 0;
				$self->ipRouteCheck($route,0,$self->{'connInterface'});
				@output = @{$self->{'bestRoute'}};
				$length = @output;

				if (!grep (/is directly connected.*$/,@output)) {
					$self->ipRouteCheck($route,0,$self->{'lines'})	;
					@output = @{$self->{'bestRoute'}};
					$length = @output;
				}

			    if (grep (/is directly connected.*$/,@output)) {
					last;
				}
				elsif ($length > 1) {
					$route = shift (@output);
					push(@{$self->{'validRoutes'}},@output);
				}
				else {
					$route = $output[0] ;
				}

				$count++;
				if ($count == 8) {
					print $self->{'log'},": loop was executed at least 8 times. Bailing out!\n";
					last;
				}
			}
			push (@{$self->{'realRoutes'}}, $route);
			$count = 0;
        }
}

=head1 BUGS

It is highly possible there are bugs. But we don't think so. We have
tested this over 4000 routers and pulled routes across this network
often. Whenever we think the code is wrong we invariably find we have a
network routing problems.

=head1 AUTHORS

Mark Pfeiffer <markpf@mlp-consulting.com.au>

Rajiv Santiago <batrax@hotmail.com>

=head1 COPYRIGHT
    
Copyright (c) 2003 Rajiv Santiago and Mark Pfeiffer. All rights
reserved. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Cisco is a registered trade mark of Cisco Systems, Inc.

This code is in no way associated with Cisco Systems, Inc.

All other trademarks mentioned in this document are the property of
their respective owners.

=head DISCLAIMER

We make no warranties, implied or otherwise, about the suitability
of this software. We shall not in any case be liable for special,
incidental, consequential, indirect or other similar damages arising
from the transfer, storage, or use of this code.

This code is offered in good faith and in the hope that it may be of use.


=cut

1;

__END__
