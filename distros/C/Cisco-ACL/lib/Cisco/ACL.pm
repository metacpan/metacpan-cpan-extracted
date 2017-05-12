#
# $Id: ACL.pm 86 2004-06-18 20:18:01Z james $
#

=head1 NAME

Cisco::ACL - generate access control lists for Cisco IOS

=head1 SYNOPSIS

=for example begin

  use Cisco::ACL;
  my $acl = Cisco::ACL->new(
    permit   => 1,
    src_addr => '10.1.1.1/24',
    dst_addr => '10.1.2.1/24',
  );
  print "$_\n" for( $acl->acls );

=for example end

=head1 DESCRIPTION

Cisco::ACL is a module to create cisco-style access lists. IOS uses a
wildcard syntax that is almost but not entirely unlike netmasks, but
backwards (at least that's how it has always seemed to me).

This module makes it easy to think in CIDR but emit IOS-compatible access
lists.

=cut

package Cisco::ACL;

use strict;
use warnings;

our $VERSION = '0.12';

use Carp                    qw|croak|;
use Params::Validate        qw|:all|;

# set up class methods
use Class::MethodMaker(
    new_with_init => 'new',
    boolean       => [ qw|
        permit
        established
    |],
    get_set       => [ qw|
        protocol
    |],
    list         => [ qw|
        src_port
        dst_port
        src_addr
        dst_addr
    |],
);

# initialize a newly constructed object
sub init
{

    my $self = shift;
    
    # validate args
    my %args = validate(@_,{
        permit      => { type     => BOOLEAN,
                         optional => 1 },
        deny        => { type     => BOOLEAN,
                         optional => 1 },
        established => { type     => BOOLEAN,
                         default  => 0 },
        src_addr    => { type     => SCALAR|ARRAYREF,
                         optional => 1 },
        dst_addr    => { type     => SCALAR|ARRAYREF,
                         optional => 1 },
        src_port    => { type     => SCALAR|ARRAYREF,
                         optional => 1 },
        dst_port    => { type     => SCALAR|ARRAYREF,
                         optional => 1 },
        protocol    => { type     => SCALAR,
                         optional => 1 },
    });

    # permit and deny are mutually exclusive
    if( exists $args{permit} && exists $args{deny} ) {
        croak "'permit' and 'deny' are mutually exclusive";
    }
    
    # do we have allow and is it true?
    if( exists $args{permit} && $args{permit} ) {
        $self->permit(1);
    }
    
    # do we only want to match established sessions
    if( exists $args{established} && $args{established} ) {
        $self->established(1);
    }

    # populate the object
    $self->protocol( $args{protocol} );
    for( qw|src_addr src_port dst_addr dst_port| ) {
        if( ref $args{$_} eq 'ARRAY' && @{ $args{$_} } ) {
            $self->$_( @{ $args{$_} } );
        }
        elsif( $args{$_} ) {
            $self->$_( $args{$_} );
        }
	
    }

    return $self;

}

# generate the access lists
sub acls
{

    my $self = shift;
    
    # generate the ACLs
    my $acls = $self->_generate();
    
    return wantarray ? @{ $acls } : $acls;

}

# reset the object attributes
sub reset
{

    my $self = shift;

    $self->clear_permit;
    $self->clear_established;
    $self->clear_protocol;
    $self->clear_src_addr;
    $self->clear_src_port;
    $self->clear_dst_addr;
    $self->clear_dst_port;

}

## all code below here is from the original acl.pl with minor tweaks
sub _generate
{

    my $self = shift;
    my @source_addr_elements = breakout_addrs(
        $self->src_addr_count ? $self->src_addr : 'any'
    );
    my @destinatione_addr_elements = breakout_addrs(
        $self->dst_addr_count ? $self->dst_addr : 'any'
    );
    my @source_port_elements = breakout_ports(
        $self->src_port_count ? $self->src_port : 'any'
    );
    my @destination_port_elements = breakout_ports(
        $self->dst_port_count ? $self->dst_port : 'any'
    );

    my @rules;
    for my $current_src_addr (@source_addr_elements) {
        for my $current_dst_addr (@destinatione_addr_elements) {
        	for my $current_src_port (@source_port_elements) {
        	    for my $current_dst_port (@destination_port_elements) {
    	        	my $rule = make_rule(
    	        	    $self->permit,
                        $self->protocol ? $self->protocol : 'tcp',
                        $current_src_addr,
                        $current_dst_addr,
                        $current_src_port,
                        $current_dst_port,
                        $self->established,
                    );
                    push @rules, $rule;
                }
    	    }
    	}
    };
    
    return \@rules;

    #
    #-------------------------------------------------------------------
    #

    sub make_rule {
      
        # Return the rule as a string, withOUT a final CR.

        my($action, $protocol, $src_addr, $dst_addr,
           $src_port, $dst_port, $established) = @_;

        # $src_port and $dst_port are ready to be inserted in the rule string
        # as is; the clean_input routine prepared them, including prepending
        # "eq ".  They will be "" if the port was "any".

        my ($rule_string,$src_elem,$dst_elem,$src_p_elem,$dst_p_elem);

        if ($protocol eq "both") {
        	$protocol = "ip";
        };

        $rule_string = $action ? "permit" : "deny";
        $rule_string .= " $protocol ";

        if ($src_addr =~ /\//) {
    	$src_elem = parse_cidr($src_addr);
        }
        elsif ($src_addr =~ /any/) {
    	$src_elem = "any";
        }
        else {
    	$src_elem = "host $src_addr";
        };

        if ($dst_addr =~ /\//) {
    	$dst_elem = parse_cidr($dst_addr);
        }
        elsif ($dst_addr =~ /any/) {
    	$dst_elem = "any";
        }
        else {
            $dst_elem = "host $dst_addr";
        };

        if ($src_port =~ /any/) {
    	$src_p_elem = "";
        }
        else {
    	$src_p_elem = $src_port;
        };

        if ($dst_port =~ /any/) {
    	$dst_p_elem = "";
        }
        else {
    	$dst_p_elem = $dst_port;
        };

        $rule_string .= "$src_elem $src_p_elem $dst_elem $dst_p_elem";
        if( $established ) {
            $rule_string .= " established";
        }
        $rule_string =~ s/\s+/ /g;
        $rule_string =~ s/\s+$//;
        return $rule_string;

    };

    #
    #-------------------------------------------------------------------
    #

    sub breakout_addrs {

        # Split on commas, return a list where every element is either a
        # single address or a single cidr specification.

        my @list = @_;
        if ($list[0] =~ /any/) { return("any"); };

        my (@elements,$addr,@endpoints,@octets1,@octets2,$start,$end,$i,
    	$number_of_endpoints,$number_of_octets,$done,$dec_start,$dec_end,@george,$remaining);

        foreach $addr( @list ) {
    	if ($addr !~ /\-/) {
    	    push @elements, $addr;  # Not a range and we're returning single addresses and
                                        # cidr notation as is, so nothing to do
    	}
    	else {
    	    @endpoints = split(/\-/, $addr);
    	    $number_of_endpoints = @endpoints;
    	    if ($number_of_endpoints != 2) {
    		next;  # something is screwey; probably something like
                           # 10.10.10.10-20-30.  Silently shitcan it.
    	    };

    	    # Two cases left; x.x.x.x-y.y.y.y and x.x.x.x-y
    	    #
    	    @octets2 = split(/\./, $endpoints[1]);
    	    $number_of_octets = @octets2;
    	    if ($number_of_octets == 4) {
    		$dec_start = ip_to_decimal($endpoints[0]);
    		$dec_end = ip_to_decimal($endpoints[1]);
    		push @elements, ferment("$dec_start-$dec_end");
    	    }
    	    else {
    		@octets1 = split(/\./, $endpoints[0]);
    		my $newend = "$octets1[0].$octets1[1].$octets1[2].$octets2[0]";
    		$dec_start = ip_to_decimal($endpoints[0]);
    		$dec_end = ip_to_decimal($newend);
                    push @elements, ferment("$dec_start-$dec_end");
    	    }
    	}
        }
        return(@elements);
    }

    #
    #-------------------------------------------------------------------
    #

    sub breakout_ports {
        my @list = @_;
        my ($tidbit,@endpoints,$start,$end,$i,$number_of_endpoints,@elements);
	   
        foreach $tidbit( @list ) {

            if ($tidbit =~ /\-/) {

                @endpoints = split(/\-/, $tidbit);
            
                $number_of_endpoints = @endpoints;
                if ($number_of_endpoints != 2) {
                    next;
                };
                
                $start = $endpoints[0];
                $end = $endpoints[1];
	
                # flip range ends if they are backward
                if ($start >= $end) {
                    ($start, $end) = ($end, $start);
                };
		
                push @elements, "range $start $end";
	        
            }
            else {
            
                push @elements, "eq $tidbit";
            
            }
        };
        
        return(@elements);
    
    };
    
    #
    #-------------------------------------------------------------------
    #

    sub parse_cidr {
        my $bob = $_[0];
        my ($address, $block, $start, $end, $mask, $rev_mask);
        ($address, $block) = split(/\//, $bob);
        ($start, $end) = ip_to_endpoints($address, $block);
        $mask = find_mask($block);
        my $bin_mask = ip_to_bin($mask);
        my @bits = split(//, $bin_mask);
        foreach my $toggle_bait (@bits) {
    	if ($toggle_bait eq "1") {
    	    $toggle_bait = "0";
    	}
    	else {
    	    $toggle_bait = "1";
    	};
        };
        my $inv_bin = join "",@bits;
        my $inv_mask = bin_to_ip($inv_bin);
        return "$start $inv_mask ";
    }

    #
    #-------------------------------------------------------------------
    #

    sub ferment {

        # Ferment = "cidr-ize" the address range (ha ha, ok, I'll keep
        # my day job.)  Take the range given as xxxx-yyyy (it's decimal!!)
        # and find the most concise way to express it in cidr notation.

        # Return: The list of elements, or "" if the range given was ""

        # Arguments: the range, the list of elements to add to.

        my $range = shift(@_);
        my @list_to_date = @_;
        my ($start,$end,$difference,$i,$got_it,@working_list,
    	$trial_start,$trial_end,$dotted_start,$block_found,$remaining_range);

        if ($range eq "") { return(@list_to_date) };   # an end condition

        ($start, $end) = split(/\-/, $range);
        $difference = $end - $start;

        if ($difference == 0) {

    	# The range is one address (i.e. start and end are the same);
    	# return it in dotted notation and we're at another end condition.

    	push @list_to_date, decimal_to_ip($start);
    	return(@list_to_date);
        };

        $got_it = 0;
        for ($i = 1; $i < 31; $i++) {

    	# We'll only try to put 1 block per call of this subroutine
    	if ($got_it) { last };

    	# Using the cidr size for this loop iteration, calculate what
    	# the block of that size would be for the start address we
    	# have, then compare that to the range we're looking for.
    	# 
    	($trial_start, $trial_end) = ip_to_endpoints(decimal_to_ip($start),$i); # dotted
    	$trial_start = ip_to_decimal($trial_start);          # now decimal
    	$trial_end = ip_to_decimal($trial_end);

    	#
    	# Ok, now these are in decimal
    	#
    	if ($trial_start == $start) {
    	    # Woo hoo, the start of the range is aligned with a cidr boundary.
    	    # Is it the right one?  We know it's the biggest possible,
    	    # but it may be too big.  If so, just move on to the next
    	    # $i (i.e. next smaller sized block) and try again.
    	    #
    	    if ($trial_end > $end) { next; };

    	    # otherwise, it's the money...
    	    #
    	    $got_it = 1;
    	    $dotted_start = decimal_to_ip($start);
    	    $block_found = "$dotted_start/$i";
    	    $start += (($trial_end - $start) + 1);
    	    #
    	    # Ok, now we've reduced the range by the amount of space
    	    # in the block we just found.  
    	    #
    	    # The extra '+1' above means that the next start point
    	    # will be one address beyond the end of the block we
    	    # just found (otherwise we'd find a few individual addresses
    	    # twice).  However, it also means that for the final block,
    	    # $start is > $end by 1.  We have to check for that before
    	    # returning the values; if we let it through we'll
    	    # spin forever...
    	    #
    	}
    	else {
    	    next;  # try the next smaller size block
    	}
        }  # for loop

        # Ok, we're done trying cidr blocks.  If we found one, return it
        # and the remaining range.  Otherwise, return 1 address and the
        # remaining range.

        if ($got_it) {
    	# We already calculated $block_found
    	$remaining_range = "$start-$end";
    	if ($start > $end) { $remaining_range = "" }
        }
        else {
    	$block_found = decimal_to_ip($start);
    	$start++;
    	$remaining_range = "$start-$end";
    	if ($start > $end) { $remaining_range = "" }
        }

        push @list_to_date, $block_found;
        return(ferment($remaining_range,@list_to_date));

    };

    #
    #-------------------------------------------------------------------
    #

    sub ip_to_endpoints {
        #
        # Various of these routings use strings for bit masks where
        # it would undoubtedly be much more efficient to use real binary
        # data, but... it's fast enough, and this was easier.  :)
        #
        my($address,$cidr,$zeros,$ones,$bin_address);
        $address = $_[0];
        $bin_address = ip_to_bin($address);
        $cidr = $_[1];
        $zeros = "00000000000000000000000000000000";
        $ones  = "11111111111111111111111111111111";
        for(my $i=0; $i<=($cidr-1); $i++) {
    	substr($zeros,$i,1) = substr($bin_address,$i,1);
        substr($ones,$i,1) = substr($bin_address,$i,1)
        };
        return(bin_to_ip($zeros), bin_to_ip($ones));
    };

    ###########################################################################

    sub find_mask {
        my($cidr,$bin,$i);
        $cidr = $_[0];
        $bin = "00000000000000000000000000000000";
        for ($i=0; $i<=31; $i++) {
    	if ($i <= ($cidr-1)) {
    	    substr($bin,$i,1) = "1"
    	    }
        }
        my $mask = bin_to_ip($bin);
        return($mask);
    };

    ############################################################################

    sub ip_to_decimal {
        my($address, $i, $a, $b, $c, $d);
        $address = shift(@_);
        ($a, $b, $c, $d) = split(/\./, $address);
        $i = (256**3)*$a + (256**2)*$b + 256*$c + $d ;
        return($i);
    };

    ############################################################################
    #
    # Ok, so, it's a hack... sue me.  :)
    #

    sub decimal_to_ip {
        return bin_to_ip(decimal_to_bin($_[0]));
    };

    ############################################################################

    sub decimal_to_bin {
        my($decimal,@bits,$i,$bin_string);
        $decimal = $_[0];
        @bits = "";
        for ($i=0;$i<=31;$i++) {
    	$bits[$i] = "0";
        };
        if ($decimal >= 2**32) {
    	die "Error: exceeded MAXINT.\n\n";
        };
        
        for ($i=0; $i<=31; $i++) {
    	if ($decimal >= 2**(31 - $i)) {
    	    $bits[$i] = "1";
    	    $decimal -= 2**(31 - $i);
    	}
        };

        $bin_string = "";
        $bin_string = join('',@bits);

        if ($decimal != 0) {
    	print "\nWARNING!!\nDANGER, WILL ROBINSON!!\nTHERE IS A GRUE NEARBY!!\n\n";
    	print "A really simple check of decimal-to binary conversion choked!\n\n";
    	print "Decimal value (expected zero): $decimal\nBinary result: $bin_string\n";
    	die "\nSuddenly the lights go out...\n\nYou hear a grumbling sound...\n\nYou have been eaten by a grue.\n\n";
        };
        return($bin_string);
    };

    ##############################################################

    sub bin_to_ip {
        my($bin,$ip,@octets,$binoct1,$binoct2,$binoct3,$binoct4,$address);
        $bin = $_[0];
        @octets = "";
        $binoct1 = substr($bin,0,8);
        $binoct2 = substr($bin,8,8);
        $binoct3 = substr($bin,16,8);
        $binoct4 = substr($bin,24,8);
        $octets[0] = bin_to_decimal($binoct1);
        $octets[1] = bin_to_decimal($binoct2);
        $octets[2] = bin_to_decimal($binoct3);
        $octets[3] = bin_to_decimal($binoct4);
        $address = join('.',@octets);
        return($address);
    };

    ##############################################################
    # ip_to_bin
    #

    sub ip_to_bin {
        my($ipaddr,$x,$y);
        $ipaddr = $_[0];
        $x = ip_to_decimal($ipaddr);
        $y = decimal_to_bin($x);
        return($y);
    };

    ############################################################################

    sub bin_to_decimal {

        # Assume 8-bit unsigned integer max
        # This is only meant to be called from bin_to_ip

        my($binary,$decimal,$i,$power,$bit,$total);
        $binary = $_[0];
        $total = 0;
        for ($i=0; $i<=7; $i++) {
    	$power = 7 - $i;
    	$bit = substr($binary,$i,1);
    	if ($bit) {
    	    $total += 2**$power;
    	}
        };
        return($total);
    };

}

# keep require happy
1;


__END__


=head1 CONSTRUCTOR

To construct a Cisco::ACL object, call the B<new> method.  The following
optional arguments can be passed as a hash of key/val pairs:

=over 4

=item * permit

A boolean value indicating that this ACL is a permit ACL. If not provided,
defaults to true.

=item * deny

The opposite of permit.  The value must be true in Perl's eyes.

=item * established

A boolean value indicating that this ACL should only allow established
packets.  If not provided, defaults to false.

=item * src_addr

The source address in CIDR format. May be a single scalar or an arrayref of
addresses. See L<"src_addr()"> for more details. If not provided, defaults
to 'any'.

=item * src_port

The source port. May be a single scalar or an arrayref of ports or port
ranges. If not provided, defaults to 'any'.

=item * dst_addr

The destination address in CIDR format. May be a single scalar or an
arrayref of addresses. See L<"src_addr()"> for more details on address
format.  If not provided, defaults to 'any'.

=item * dst_port

The destination port. May be a single scalar or an arrayref of ports or port
ranges. If not provided, defaults to 'any'.

=item * protocol

The protocol.  If not provided, defaults to 'tcp'.

=back

=head1 ACCESSORS

A Cisco::ACL object has several accessor methods which may be used to
get or set the properties of the object. These accessors are generated by
Class::MethodMaker - for more information see L<Class::MethodMaker>. The
C::MM type of accessor is in brackets following the accessor name.

=head2 permit() [boolean]

A boolean accessor, it returns 1 or 0 depending on whether the object
represents a 'permit' rule or a 'deny' rule. Passing a true value to the
accessor sets it to 1.

There are also clear_permit() and set_permit() methods which set the
property without requiring an explicit argument.

=head2 established() [boolean]

A boolean accessor, it returns 1 or 0 depending on whether the object
represents a rule which should only allow established sessions or not. 
Passing a true value sets it to 1.

=head2 src_addr() [list]

A list of source addresses, returned as an arrayref in scalar context and an
array in list context. Passing an argument replaces the entire content of
the list. If you want to add an address to the list, use src_addr_push.

Source and destination addresses may be specified in any combination of
three syntaxes: a single IP address, a range of addresses in the format
a.a.a.a-b.b.b.b or a.a.a.a-b, or a CIDR block in the format x.x.x.x/nn. Use
the word "any" to specify all addresses. For example, all of the following
are legal:

  10.10.10.20
  10.10.10.10-200
  20.20.20.20-30.30.30.30
  10.10.10.20
  10.10.10.10-200
  10.10.10.10/8
  45.45.45.45 

Multiple entries may be passed to the accessor functions.

There are also src_addr_pop(), src_addr_shift(), src_addr_unshift(),
src_addr_unsplice(), src_addr_clear(), src_addr_count(), src_addr_index()
and src_addr_set() methods which perform the familiar array operations on
the list of addresses.

=head2 src_port() [list]

A list of source ports or source port ranges. A range of ports is denoted as two
port numbers joined by a C<->. The same methods as src_addr() (renamed) are also
available.

=head2 dst_addr() [list]

As with src_addr(), but for destination addresses.

=head2 dst_port() [list]

As with src_port(), but for destination ports.

=head2 protocol() [get_set]

If you have Class::MethodMaker v1.xx installed, the object will only have
the accessor methods described above. If you have Class::MethodMaker v2.xx
installed then there will be more accessor methods. Only the accessor
methods documented here are officially supported and tested.

=head1 METHODS

=head2 acls()

Generates the access lists and returns then as an array in list context or
an arrayref in scalar context.

=head2 reset()

Resets all of the ACL values.  Useful if you want to construct an object,
generate an ACL and then re-use the same object for a completely different
ACL rather than one which is incrementally different.

Resetting an ACL object:

=over 4

=item * clears the B<permit>, B<established> and B<protocol> attributes.

=item * empties the source and destination ports and address attribute
lists.

=back

=head1 EXAMPLES

To create an access list that allows traffic from 192.168.0.1 with any
source port to any host on the class B network 10.1.1.1/16 with a
destination port of 21937:

=for example begin

  my $acl = Cisco::ACL->new(
    src_addr => '192.168.0.1',
    dst_addr => '10.1.1.1/16',
    dst_port => 21937,
  );
  print "$_\n" for( $acl->acls );

=for example end

To create an access list that will deny all traffic (regardless of whether
it is TCP or UDP) to or from 24.223.251.222:

=for example begin

  my $acl = Cisco::ACL->new(
    src_addr => '24.223.251.222',
    protocol => 'ip',
  );
  print "$_\n" for( $acl->acls );
  $acl->src_addr_clear;
  $acl->dst_addr( '24.223.251.222' );
  print "$_\n" for( $acl->acls );

=for example end

Using multiple addresses and/or ports: permit SSH and SFTP traffic from
192.168.1.1/25 and 10.1.1.1/26 to anywhere.

=for example begin

  my $acl = Cisco::ACL->new(
    src_addr => [ '192.168.1.1/25', '10.1.1.1/26' ],
    dst_port => [ 22, 25 ],
  );
  print "$_\n" for( $acl->acls );

=for example end

Using the established parameter, permit any sessions which are already
established.

=for example begin

  my $acl = Cisco::ACL->new( established => 1 );
  print "$_\n" for( $acl->acls );

=for example end

=head1 BUGS

These are the known limitations from the original acl.pl. I hope to address
these in the near future.

=over 4

=item * Address Ranges Ordering

Address ranges must be supplied in ascending order, e.g.
10.10.10.10-10.10.20.20. If you use 10.10.20.20-10.10.10.10 it won't handle
that.

=item * Permit/Deny in one rule

Currently there is no way to specify a combination of permit and deny rules
in the same ACL. Generate them separately and edit them together by hand.

This may or may not be addressed based upon feedback received from CPAN
users. With a web app this bug is an annoyance, but in a program that can
have two distinct ACL objects, one for permit and one for deny it becomes
less of a problem.

=back

=head1 TODO

The initial version of this module is pretty much an OO wrapper around
Chris' original code.  Future plans include (hopefully in order
of implementation):

=over 4

=item * use CPAN modules where possible

The original code did all it's own CGI processing - I'd like to move to
CGI.pm instead.

=item * refactor mercilessly

I want to build up the test suite to a fair size and then start looking
for places to make things cleaner, faster, smaller, etc.

=item * make sure that everything produced is up-to-date with IOS

It's been a while since I've had to play with a Cisco, so what I know
might not be totally up to date with the latest software revs.

=back

=head1 SEE ALSO

This distribution includes aclmaker.pl, a simple CGI frontend to Cisco::ACL.

If you need a more generic framework for ACLs, take a look at Net::ACL by
Martin Lorensen.

=head1 AUTHOR

James FitzGibbon, E<lt>jfitz@CPAN.orgE<gt>.

=head1 ORIGINAL AUTHOR

The code in this module started life as acl.pl, a CGI script written by
Chris De Young (chd AT chud DOT net). I was about to embark on writing a
module to do this from scratch when I stumbed across his web version, which
was procedural. He graciously accepted my offer to OOP-ize the code. Any
mistakes in this module are probably mine.

=head1 CONTRIBUTORS

Nicolas Georgel contribued changes to implement Cisco's port range syntax and to
allow for port numbers to be specified in reverse order (highest first).

=head1 COPYRIGHT

This module is free software.  You may use and/or modify it under the
same terms as perl itself.

=cut

#
# EOF
