package Cisco::Accounting::Data;

## ----------------------------------------------------------------------------------------------
## Cisco::Accounting::Data
##
## $Id: Data.pm 119 2007-08-18 21:36:42Z mwallraf $
## $Author: mwallraf $
## $Date: 2007-08-18 23:36:42 +0200 (Sat, 18 Aug 2007) $
##
## This program is free software; you can redistribute it and/or
## modify it under the same terms as Perl itself.
## ----------------------------------------------------------------------------------------------


$VERSION = "1.00";

use strict;
use warnings;
use Carp;
#use Data::Dumper;

my $DEBUG = 0;


# $data = reference to @output of the telnet command "show ip accounting"
sub new {
	my ($this) = shift;
	my (%parms) = @_;
	
	my  $class = ref($this) || $this;
	my  $self = {};
	bless($self, $class);

	$self->{'headers'} = [ 'source', 'destination', 'lastPollBytes', 'lastPollPackets', 'totalBytes', 'totalPakcets', 'polls' ];

	$self->{'data'} = {};  # "src-dest" -> [ source, destination, lastPollBytes, lastPollPackets, totalBytes, totalPakcets, polls ]

	$self->{'stats'}->{'totalpolls'} = 0;
	$self->{'stats'}->{'totalbytes'} = 0;
	$self->{'stats'}->{'totalpackets'} = 0;
	$self->{'stats'}->{'totalpolledlines'} = 0;
	$self->{'stats'}->{'totalskippedlines'} = 0;
	$self->{'stats'}->{'uniquehostpairs'} = 0;
	$self->{'stats'}->{'starttime'} = '';		# starttime of the first poll
	$self->{'stats'}->{'lastpolltime'} = '';		# time last poll has run

	$self->{'keep_history'} = (defined($parms{'keep_history'}))?($parms{'keep_history'}):(1);	# keep summarized historical data for each poll

	$self->{'historical'} = {};	#  {'timestamp'}	->  { 'totalBytes' -> '', 'totalPackets' -> '', 'hostPairs' -> ''}

	&_init($class);
	return($self);
} # end sub new


# initialization : set up logging  
sub _init  {
	my $class=shift;
	
	## enable debugging if needed
	$SIG{'__WARN__'} = sub { carp($_[0]) }  if ($DEBUG > 0);
}



#
# parse telnet data output into $self->{'data'} output
# data should always be in format : / *source *destination *packets *bytes */
#
sub parse  {
	my ($self) = shift;
	my ($acct_data) = shift;	# reference to array of output lines

	my ($row);
	my ($src, $dst, $packets, $bytes);
	
	## update last poll time
	$self->{'stats'}->{'lastpolltime'} = time();
	$self->{'stats'}->{'starttime'} = time() unless ($self->{'stats'}->{'starttime'});


	foreach $row (@{$acct_data})  {
		eval {
			($src, $dst, $packets, $bytes) = &_parse_row($row);
		};

		## update historical data if needed
		## in case there's no data, still update poll time to historical data
		if (!defined($self->{'historical'}->{$self->{'stats'}->{'lastpolltime'}}) && $self->{'keep_history'})  {
			$self->{'historical'}->{$self->{'stats'}->{'lastpolltime'}}->{'hostPairs'} = 0;
			$self->{'historical'}->{$self->{'stats'}->{'lastpolltime'}}->{'totalBytes'} = 0;			
			$self->{'historical'}->{$self->{'stats'}->{'lastpolltime'}}->{'totalPackets'} = 0;			
		}

		## skip row if we didn't find what we expected (src, dst, packets, bytes)
		if ($@)  {
			$self->{'stats'}->{'totalskippedlines'}++;
			if ($DEBUG > 0)  {
				carp("skipping row : " . $@);
			}
			next;
		}

		## update the statistics, if the source-destination combination already exists
		## then add the new data to existing
		if (exists $self->{'data'}->{"$src-$dst"})  {
			$self->{'data'}->{"$src-$dst"}->{'lastPollBytes'} = $bytes;
			$self->{'data'}->{"$src-$dst"}->{'lastPollPackets'} = $packets;
			$self->{'data'}->{"$src-$dst"}->{'totalBytes'} += $bytes;
			$self->{'data'}->{"$src-$dst"}->{'totalPackets'} += $packets;
			$self->{'data'}->{"$src-$dst"}->{'polls'} ++;
		}
		## if this is the first time we see this host pair then initialize stats
		else  {
			$self->{'data'}->{"$src-$dst"}->{'source'} = $src;
			$self->{'data'}->{"$src-$dst"}->{'destination'} = $dst;
			$self->{'data'}->{"$src-$dst"}->{'lastPollBytes'} = $bytes;
			$self->{'data'}->{"$src-$dst"}->{'lastPollPackets'} = $packets;
			$self->{'data'}->{"$src-$dst"}->{'totalBytes'} = $bytes;
			$self->{'data'}->{"$src-$dst"}->{'totalPackets'} = $packets;
			$self->{'data'}->{"$src-$dst"}->{'polls'} = 1;
			$self->{'stats'}->{'uniquehostpairs'} ++;
		}
		
#		## update historical data if needed
		if ($self->{'keep_history'})  {
#			if (defined($self->{'historical'}->{$self->{'stats'}->{'lastpolltime'}}))  {
			$self->{'historical'}->{$self->{'stats'}->{'lastpolltime'}}->{'hostPairs'}++;
			$self->{'historical'}->{$self->{'stats'}->{'lastpolltime'}}->{'totalBytes'} += $bytes;			
			$self->{'historical'}->{$self->{'stats'}->{'lastpolltime'}}->{'totalPackets'} += $packets;			
#			}
#			else {
#				$self->{'historical'}->{$self->{'stats'}->{'lastpolltime'}}->{'hostPairs'} = 1;
#				$self->{'historical'}->{$self->{'stats'}->{'lastpolltime'}}->{'totalBytes'} = $bytes;			
#				$self->{'historical'}->{$self->{'stats'}->{'lastpolltime'}}->{'totalPackets'} = $packets;			
#			}
		}
		
		## update global statistics
		$self->{'stats'}->{'totalbytes'} += $bytes;
		$self->{'stats'}->{'totalpackets'} += $packets;
		$self->{'stats'}->{'totalpolledlines'} ++;
	}

	## update stats
	$self->{'stats'}->{'totalpolls'} ++;

	return $self->{'data'};
}

##
## parses a single row of data, returns array of (source, destination, packets, bytes)
## dies otherwise
##
sub _parse_row()  {
	my ($row) = shift;
	
	my (@cols);
	
	## remove leading and trailing spaces, eol characters
	## split row in columns delimited by spaces
	$row =~ s/^ *(.*)[ \n]*$/$1/;
	@cols = split(/ +/,$row);
	
	## die unless we've got 4 columns
	if ((scalar @cols) < 4)  {
		croak("skip row, we need 4 columns (\"$row\")");
	}
	
	## validate each column, make sure it contains the correct data
	eval {
		map {  &_validate_column('column' => $_, 'ip' => 1); }  ($cols[0], $cols[1]); # these columns should contain ip addresses
		map {  &_validate_column('column' => $_, 'ip' => 0); }  ($cols[2], $cols[3]); # these columns should contain positive number
	};
	if ($@)  {
		croak("skip row, invalid column format : " . $@);
	}
	
	## everything is ok, we got (source, destination, packets, bytes)
	return @cols;
}


##
## validate a single column
##  parameters =   column => $col,  ip => 0|1
##
sub _validate_column()  {
	my (%parms) = @_;
	
	my $column = $parms{'column'};
	my $is_ip = $parms{'ip'} || 0;
	
	if (!$column)  {
		croak("column does not contain a value ($column)");
	}
	
	## check if it's an ip address
	if ($is_ip > 0)  {
		unless ($column =~ /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/)  {
			croak("expecting ip address but not found in column \"$column\"");
		}
	}
	
	## check if it's a positive number
	else  {
		unless ($column =~ /^[0-9]+$/)  {
			croak("expecting positive number but not found in column \"$column\"");
		}
	}
}


##
## returns reference to array with the default headers for the columns
##
sub get_headers()  {
	my ($self) = shift;
	return $self->{'headers'};
}


##
## return reference to output hash,  hash contains reference to array of columns
##
sub get_data()  {
	my ($self) = shift;
	return $self->{'data'};
}

##
## return reference to hash with statistics
##
sub get_stats()  {
	my ($self) = shift;
	
	return $self->{'stats'};
}

##
## return reference to hash with statistics
##
sub get_history()  {
	my ($self) = shift;
	
	return $self->{'historical'};
}

sub get_total_polls()  {
	my ($self) = shift;
	return $self->{'stats'}->{'totalpolls'};
}

sub get_total_polled_lines()  {
	my ($self) = shift;
	return $self->{'stats'}->{'totalpolledlines'};
}

sub get_total_bytes()  {
	my ($self) = shift;
	return $self->{'stats'}->{'totalbytes'};
}

sub get_total_packets()  {
	my ($self) = shift;
	return $self->{'stats'}->{'totalpackets'};
}

sub get_last_poll_time()  {
	my ($self) = shift;
	return $self->{'stats'}->{'lastpolltime'};
}

sub get_first_poll_time()  {
	my ($self) = shift;
	return $self->{'stats'}->{'starttime'};
}

1;


__END__




