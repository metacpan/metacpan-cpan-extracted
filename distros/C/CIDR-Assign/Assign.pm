package CIDR::Assign;

# $Id: Assign.pm,v 1.14 1998/05/28 02:50:02 mrp Exp $

=head1 NAME

CIDR::Assign - Manage assignments out of a group of CIDR blocks

=head1 SYNOPSIS

use CIDR::Assign;

$obj = CIDR::Assign->new($filename);

$obj->DESTROY;

$network = $obj->assignNetwork($length, $customer, $ones, $zeros, $location);

$obj->changeState($network, $state, $customer, $location);

$obj->initialiseBlock($network);

($network, $state, $date, $customer, $location) = $obj->iterateAllocations;

=head1 DESCRIPTION

This module can be used to manage customer assigments out of a provider
block. The CIDR block is represented as a B-Tree in a Berkeley DB database
and is originally populated by invoking initialiseBlock with each provider
block.

=cut

# The B-Tree is keyed to the address, which is "normalised" into CIDR length
# form where the address component always contains 4 octets.
#
# The value of each element is constructed as a series of $separator terminated
# strings which are interpreted as key/value pairs.
#
# The keys present in the element are
#	state		- 'free', 'taken' or 'holding' (required)
#	date		- date of the last operation on the block (required)
#	customer	- some customer "code", at Connect this a customer ID
#	location	- a location code, Connect use a 3 letter city code
#

require 5.003;
require Exporter;

use Carp;
use FileHandle;
use DB_File;
use File::lockf;

$VERSION = '0.01';	# should be tied to the RCS rev eventually

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
$today = sprintf "%4d%02d%02d", $year+1900, $mon+1, $mday,

%states = (
	free	=> 'unallocated',
	taken	=> 'allocated',
	holding	=> 'being considered for reuse',
);

%messages = (
	OK	=> '',
	LENGTH	=> 'Length of request is invalid, must be between 2 and 32',
	NOMATCH	=> 'No suitable allocation available',
	STATE	=> 'New state "%s" is unrecognised',
	NETWORK	=> 'Network "%s" is invalid, illegal octet value %s',
	RANGE	=> 'Network not within the allocation pool',
	OVERLAP	=> 'New block "%s" overlaps existing allocation',
);

$separator = chr(0);

@ISA	= qw(Exporter);
@EXPORT	= qw($VERSION new DESTROY assignNetwork changeState iterateAllocations
		errorMessage);
@EXPORT_OK = qw(compareIP maskOfLength parseNet printIP overlap);

sub compareIP {
	my($netA, $lenA) = split(/\//, shift);
	my($netB, $lenB) = split(/\//, shift);
	my(@a) = split(/\./, $netA);
	my(@b) = split(/\./, $netB);

	return $a[0] <=> $b[0] || $a[1] <=> $b[1]
		|| $a[2] <=> $b[2] || $a[3] <=> $b[3]
		|| $lenA <=> $lenB;
}

sub new {

=pod

new will create the DB file, whose name is passed as a parameter, if necessary,
and then tie it to an internal hash used by the other routines. This routine
attempts to acquire a lock on the DB file using lockf in an attempt to control
access to the file. Should acquiring the lock fail the routine will return
"undef".

=cut

	my($class) = shift;
	my($i, %hash);
	my($self) = {
		NAME	=> shift,
		FILE	=> new FileHandle,
		DB	=> undef,
		POS	=> undef,
		ERROR	=> 'OK',
		PARAMS	=> undef,
		};

	$DB_BTREE->{'compare'} = \&compareIP;

	unless ( $self->{DB} = tie(%hash, 'DB_File', $self->{NAME},
		O_CREAT|O_RDWR, 0660, $DB_BTREE) ) {
		carp "dbopen failed: $!\n";
		return undef;
	}

	$self->{FILE}->fdopen($self->{DB}->fd, "r+") || die "fdopen: $!\n";
	if ( File::lockf::tlock( $self->{FILE} ) != 0 ) {
		# wait for the lock
		my($i);
		for ( $i = 5; $i > 0 ; $i-- ) {
			sleep 5;
			break if File::lockf::tlock( $self->{FILE} ) == 0;
		}
		if ( $i == 0 ) {
			carp "Unable to acquire lock on DB\n";
			undef $self->{DB};
			$self->{FILE}->close;
			return undef;
		}
	}
	return bless ($self, ref $class || $class);
}

sub DESTROY {

=pod

DESTROY closes the DB file and releases the lock on the file.

=cut

	my($self) = shift;

	return unless defined $self->{DB};
	File::lockf::ulock( $self->{FILE} );
	$self->{FILE}->close;
	undef $self->{DB};
}

sub assignNetwork {

=pod

Networks can be allocated out of the assigned blocks by calling
assignNetwork specifying the size of the block required. The system then
scans the tree for a "free" block that is of the required size. If a block
isn't available then it splits the next largest block and invokes itself.
Should there be no free block available for allocation then the routing
returns "undef".

The parameters "ones" and "zeroes" are used to indicate if the allocation can
make use of an all ones or all zeros network if necessary.

The parameter "location" is optional but if present and the allocation is
smaller than a /24 it will try to choose a block in the same location as
other allocations in order to avoid too much fragmentation of the address
space.

=cut

	my($self) = shift;
	my($length, $customer, $ones, $zeroes, $location) = @_;
	my($status, $network, $value, $bits);
	my($spare, $match, $contents) = '';
	my($smallest) = 0;
	my($timestamp) = undef;
	my(%hash);

	# Sanity check.
	if ( $length < 2 || $length > 32 ) {
		$self->{ERROR} = 'LENGTH';
		return undef;
	}

	$location = lc $location;

	# Look for a free block that matches our requirements
	for ( $status = $self->{DB}->seq($network, $value, R_FIRST);
	    $status == 0;
	    $status = $self->{DB}->seq($network, $value, R_NEXT) ) {
		%hash = split($separator, $value);
		next unless $hash{'state'} eq 'free';
		$network =~ /\/(\d+)$/;
		$bits = $1;
		next if $length > 24
			&& $location ne '' && $hash{'location'} ne $location;
		if ( $bits > $length ) {	# Too small.
			next;
		} elsif ( $bits == $length ) {	# Match
			next if $match ne ''
				&& defined $timestamp && $hash{'date'} >= $timestamp;
			if ( $ones && $zeroes ) {
				$timestamp = $hash{'date'};
				$match = $network;
			} elsif ( $network =~ /^\d+\.\d+\.(\d+)\.\d+\// ) {
				my $subnet = $1;
				if ( ( $subnet != 0 && $subnet != 255 )
				    || ( $subnet == 0 && $zeroes )
				    || ( $subnet == 255 && $ones ) ) {
					$timestamp = $hash{'date'};
					$match = $network;
				}
			}
		} elsif ( $match eq '' ) {
			$network =~ /^\d+\.\d+\.(\d+)\.\d+\//;
			next if $bits >= 24
			    && ( ( $1 == 0 && $zeroes == 0 )
				|| ( $1 == 255 && $ones == 0 ) );
			# No match, store for possible later breakdown
			if ( $smallest < $bits ) {
				$timestamp = $hash{'date'};
				$smallest = $bits;
				$spare = $network;
			} elsif ( $smallest == $bits
			    && ( !defined $timestamp || $hash{'date'} < $timestamp ) ) {
				$timestamp = $hash{'date'};
				$spare = $network;
			}
		}
	}
	if ( $match ne '' ) {
		$self->{DB}->get($match, $value);
		%hash = split($separator, $value);
		$hash{'state'} = 'taken';
		$hash{'date'} = $today;
		$hash{'customer'} = $customer;
		$hash{'location'} = $location
			if $length > 24 && defined $location && $location ne '';
		$self->{DB}->put($match, join($separator, %hash) );
		$self->{DB}->sync;
		return $match;
	}

	# OK, if we've got this far, there's no match.
	# Do we have anything we can break down?
	# If not, we can't succeed, so return now.

	if ( $spare eq '' ) {
		$self->{ERROR} = 'NOMATCH';
		return undef;
	}

	# OK, we have something. Break it down, then try again.

	$self->{DB}->get($spare, $contents);
	$self->{DB}->del($spare);
	$spare =~ s/\/(\d+)$//;
	$bits = $1;
	%hash = split($separator, $contents);
	$hash{'location'} = $location
		if $bits == 24 && defined $location && $location ne '';
	$network = sprintf "%s/%d", $spare, $bits + 1;
	$self->{DB}->put( $network, join($separator, %hash) );
	$self->{DB}->sync;
	$spare = join ('.', unpack('C4',
		(pack('C4', split(/\./, $spare)) |
			pack('B32', scalar ('0' x $bits) . '1' .
				scalar ('0' x (31 - $bits))))));
	$network = sprintf "%s/%d", $spare, $bits + 1;
	$self->{DB}->put( $network, join($separator, %hash) );
	$self->{DB}->sync;
	return $self->assignNetwork(@_);
}

sub changeState {

=pod

changeState can be used to change the state of a block in the free, for
example, to add existing allocations to the tree or return an allocation
to the free pool.

=cut

	my($self) = shift;
	my($network, $state, $customer, $location) = @_;
	my($ip, $length) = parseNet($network);
	my($allocation) = sprintf "%s/%d", printIP($ip), $length;
	my(@candidates) = ();;
	my($net, $contents, $status, $bits);

	unless ( defined $states{$state} ) {
		$self->{ERROR} = 'STATE',
		$self->{PARAMS} = [ $state ];
		return undef;
	}
	if ( $ip == 0 ) {
		$self->{ERROR} = 'NETWORK';
		$self->{PARAMS} = [ $network, $length ];
		return undef;
	}

	if ( $self->{DB}->get($allocation, $contents) == 0 ) {
		%hash = split($separator, $contents);
		$hash{'state'} = $state;
		$hash{'date'} = $today;
		$hash{'customer'} = $customer if defined $customer;
		$hash{'location'} = $location
			if $length > 24 && defined $location && $location ne '';
		$self->{DB}->put($allocation, join($separator, %hash) );
		$self->{DB}->sync;
		# Should try to merge with surrounding nets if possible
		return $self->mergeNetwork( $allocation );
	}

	# It would be nice to use the cursor to just search the subtree
	# where the allocation would be located but it will return the
	# element in the tree after the one we want, since it returns
	# equal or greater than. As a consequence we need to run through
	# the whole of the tree looking for the bit we want.
	#
	for ( $status = $self->{DB}->seq($network, $value, R_FIRST);
	    $status == 0;
	    $status = $self->{DB}->seq($network, $value, R_NEXT) ) {
		push @candidates, $network if overlap($allocation, $network);
	}

	# Did we find an allocation that overlaps the bit we want to change?
	if ( $#candidates == 0 ) {
		($net, $bits) = split(/\//, $candidates[0]);
		if ( $bits < $length ) {
			# OK, we have something bigger.
			# Break it down, then try again.
			$self->{DB}->get($candidates[0], $contents);
			$self->{DB}->del($candidates[0]);
			%hash = split($separator, $contents);
			$hash{'location'} = $location
				if $bits == 24
				    && defined $location && $location ne '';
			$network = sprintf("%s/%d", $net, $bits + 1);
			$self->{DB}->put($network, join($separator, %hash) );
			$self->{DB}->sync;
			$net = join ('.', unpack('C4',
				(pack('C4', split(/\./, $net) ) |
					pack('B32', scalar ('0' x $bits) . '1' .
						scalar ('0' x (31 - $bits))))));
			$network = sprintf("%s/%d", $net, $bits + 1);
			$self->{DB}->put($network, join($separator, %hash) );
			$self->{DB}->sync;
			return $self->changeState(@_);
		} else {
			# The user wants us to change something that is not
			# in the allocation pool, complain...
			$self->{ERROR} = 'RANGE';
			return undef;
		}
	} elsif ( $#candidates > 0 ) {
		# We should check that these elements completely cover the
		# entry we want to change but that's too hard for now so
		# just assume they do...
		#
		# Remove the fragments enclosed by the new element
		foreach ( @candidates ) {
			$self->{DB}->del($_);
		}
		%hash = {};
		$hash{'state'} = $state;
		$hash{'date'} = $today;
		$hash{'customer'} = $customer if defined $customer;
		$hash{'location'} = $location
			if $length > 24 && defined $location && $location ne '';
		$self->{DB}->put($allocation, join($separator, %hash) );
		$self->{DB}->sync;
		return $self->mergeNetwork( $allocation );
	} else {
		# We can't find any evidence of the entry being part of
		# the allocation pool. 
		$self->{ERROR} = 'RANGE';
		return undef;
	}
}

sub initialiseBlock {

=pod

initialiseBlock adds a new block into the allocation pool.

=cut

	my($self) = shift;
	my($network, $length) = parseNet(@_);
	my($allocation) = sprintf "%s/%d", printIP($network), $length;
	my($status);
	my(%hash) = {};
	my(@candidates) = ();

	if ( $network == 0 ) {
		$self->{ERROR} = 'NETWORK';
		$self->{PARAMS} = [ @_, $length ];
		return undef;
	}

	if ( $self->{DB}->get($allocation, $contents) == 0 ) {
		$self->{ERROR} = 'OVERLAP';
		$self->{PARAMS} = [ $allocation ];
		return undef;
	}

	# OK now check that it's not part of an existing allocation
	for ( $status = $self->{DB}->seq($network, $value, R_FIRST);
	    $status == 0;
	    $status = $self->{DB}->seq($network, $value, R_NEXT) ) {
		push @candidates, $network if overlap($allocation, $network);
	}

	if ( $#candidates < 0 ) {
		$hash{'state'} = 'free';
		$hash{'date'} = $today;
		$status = $self->{DB}->put($allocation, join($separator, %hash) );
		$status = $self->{DB}->sync;
		return $self->mergeNetwork( $allocation );
	} else {
		$self->{ERROR} = 'OVERLAP';
		$self->{PARAMS} = [ $allocation ];
		return undef;
	}
}

sub mergeNetwork {
	my($self) = shift;
	my($network, $length) = parseNet(@_);
	my($allocation) = sprintf "%s/%d", printIP($network), $length;
	my($contents);
	my($bits, $merge, $status, $value, $dummy, $larger);
	my(@overlap) = ();
	my($state, $location, $customer, $date);
	my(%hash, %original);

	# Save the value of the component we want to merge so we can check
	# that all the other components are like it.
	$self->{DB}->get($allocation, $contents);

	%original = split($separator, $contents);

	$state = $original{state};
	$location = $original{location};
	$customer = $original{customer};
	$date = $original{date};

	# Should try to merge networks into larger CIDR blocks if surrounding
	# blocks are free or have the same customer ID
	#
	$bits = $length - 1;
	$larger = join('.', unpack('C4', ( pack('L', $network) &
			pack('B32', scalar('1' x $bits) .
				scalar('0' x (32 - $bits))))));
	$network = sprintf "%s/%d", $larger, $bits;

	# Initialise the cursor, this shouldn't be necessary but the for loop
	# below doesn't work as I expected without it for the last subtree :-(
	#
	$status = $self->{DB}->seq($dummy, $value, R_FIRST);

	# Just run through the subtree checking that the components are the
	# same, we don't care if the "free" date is different.
	#
	$merge = 1;
	for ( $status = $self->{DB}->seq($network, $value, R_CURSOR);
	    $status == 0 && $merge;
	    $status = $self->{DB}->seq($network, $value, R_NEXT) ) {
		if ( overlap( sprintf("%s/%d", $larger, $bits), $network ) ) {
			%hash = split($separator, $value);
			if ( $state ne $hash{'state'} ) {
				$merge = 0;
			} elsif ( $hash{'state'} ne 'free' ) {
				$merge = $customer eq $hash{'customer'};
				push @overlap, $network;
			} else {
				push @overlap, $network;
			}
		} else {
			last;
		}
	}

	# We have a valid overlap of like components so merge them into a
	# supernet then try to merge it
	#
	if ( $merge && $#overlap > 0 ) {
		$allocation = sprintf "%s/%d", $larger, $bits;
		undef $original{location} if defined $location && $bits >= 24;
		$self->{DB}->put($allocation, join($separator, %original) );
		$self->{DB}->sync;
		foreach ( @overlap ) {
			$self->{DB}->del($_);
		}
		return $self->mergeNetwork( $allocation );
	} else {
		return $allocation;
	}
}

sub iterateAllocations {

=pod

iterateAllocations allows the caller to traverse the tree, much like "each",
and returns a list of information about each allocation. This list is comprised
of network, state (currently 'taken', 'free' or 'holding'), date of last
operation and customer indentifer (and possibly location) if the block is not
free.

=cut

	my($self) = shift;
	my($status, $value);
	my(%hash);

	unless ( wantarray ) {
		$self->{POS} = undef;
		return undef;
	}
	if ( defined $self->{POS} ) {
		$self->{DB}->seq($self->{POS}, $value, R_CURSOR);
		$status = $self->{DB}->seq($self->{POS}, $value, R_NEXT);
	} else {
		$status = $self->{DB}->seq($self->{POS}, $value, R_FIRST);
	}
	if ( $status == 0 ) {
		%hash = split($separator, $value);
		return ($self->{POS}, $hash{'state'}, $hash{'date'},
			$hash{'customer'}, $hash{'location'});
	} else {
		$self->{POS} = undef;
		return ();
	}
}

sub errorMessage {

=pod

errorMessage return a string suitable for printing that describes the latest
error condition.

=cut

	my($self) = shift;
	my(@params) = @{ $self->{PARAMS} };

	return sprintf $messages{$self->{ERROR}}, @params;
}

sub maskOfLength {
	my($len) = @_;

	return(-( 1 << (32 - $len )));
}

sub parseNet {
	my($prefix, $length) = split('/', shift, 2);
	my(@bytes) = split(/\./, $prefix, 4);
	my($ip, $byte);

	foreach $byte ( @bytes ) {
		if ( $byte !~ /^\d+$/ || $byte > 255 ) {
			return (0, $byte);
		}
	}

	$ip = unpack('L', pack('C4', @bytes));
 
	#  Supply a classful default length ONLY if no length was specified.

	if ( $length eq "" ) {
		#  Old version:  user the classful default lengths.
		#
		# No explicit length given so default to classful definition
		$length = ( $bytes[0] < 128 ) ? 8 :
			  ( $bytes[0] < 192 ) ? 16:
						24;

		#  *IF* this default causes a CIDR-alignment problem,
		#    then that's probably not what they wanted.  Try
		#    8, 16, 24, or 32 based on the number of octets 
		#    that they supplied when they typed the address.  
		#    E.g.,:
		#    35   ->  35/8
		#    35.1 -> 35/16
		#    193  -> 193/8
		#    193.128.2.15 -> 193.128.2.15/32

		$mask = &maskOfLength($length);
		$length = (8,16,24,32)[$#bytes] if ($mask & $ip) != $ip;
	}

	return ( $ip, $length );
}

sub printIP {
	return join('.', unpack('C4', pack('L', @_)));
}

sub overlap {
	my($old, $new) = @_;
	my(@old, @new);

	@old = &parseNet($old);
	@new = &parseNet($new);
	if ( $old[1] == $new[1] ) {
		return $old[0] == $new[0];
	} else { # different lengths so we need to see if one is inside other
		if ( $old[1] < $new[1] ) {
			$mask = &maskOfLength($old[1]);
		} else {
			$mask = &maskOfLength($new[1]);
		}
		return ($old[0] & $mask) == ($new[0] & $mask);
	}
}

1;

=head1 AUTHOR

Mark Prior <mrp@connect.com.au>

Original idea and code by Andrew Rutherford <andrewr@iagu.net>

=head1 NOTES
 
This module uses the following modules

=over 4

=item DB_File

The Berkeley DB is used for storage of the allocations, in B-Tree format.

=item File::lockf

The allocations file is locked with lockf to avoid problems with NFS.

=back

=cut

