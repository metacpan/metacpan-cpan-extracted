package Cisco::SNMP::Memory;

##################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
##################################################

use strict;
use warnings;

use Net::SNMP qw(:asn1);
use Cisco::SNMP;

our $VERSION = $Cisco::SNMP::VERSION;

our @ISA = qw(Cisco::SNMP);

##################################################
# Start Public Module
##################################################

sub _memOID {
    return '1.3.6.1.4.1.9.9.48.1.1.1';
}

sub memOIDs {
    return qw(Name Alternate Valid Used Free LargestFree Total);
}

sub memory_info {
    my $self = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %ret;
    my @MEMKEYS = memOIDs();

    # -1 because last key (Total) isn't an OID; rather, calculated from 2 other OIDs
    for my $oid ( 0 .. $#MEMKEYS - 1 ) {
        $ret{$MEMKEYS[$oid]} = Cisco::SNMP::_snmpwalk( $session,
            _memOID() . '.' . ( $oid + 2 ) );
        if ( not defined $ret{$MEMKEYS[$oid]} ) {
            $Cisco::SNMP::LASTERROR
              = "Cannot get memory `$MEMKEYS[$oid]' info";
            return undef;
        }
    }

    my @MemInfo;
    for my $mem ( 0 .. $#{$ret{$MEMKEYS[0]}} ) {
        my %MemInfoHash;
        for ( 0 .. $#MEMKEYS ) {
            if ( $_ == 2 ) {
                $MemInfoHash{$MEMKEYS[$_]}
                  = ( $ret{$MEMKEYS[$_]}->[$mem] == 1 ) ? 'TRUE' : 'FALSE';
            } elsif ( $_ == 6 ) {
                $MemInfoHash{$MEMKEYS[$_]}
                  = $ret{$MEMKEYS[3]}->[$mem] + $ret{$MEMKEYS[4]}->[$mem];
            } else {
                $MemInfoHash{$MEMKEYS[$_]} = $ret{$MEMKEYS[$_]}->[$mem];
            }
        }
        push @MemInfo, \%MemInfoHash;
    }
    return bless \@MemInfo, $class;
}

for ( memOIDs() ) {
    Cisco::SNMP::_mk_accessors_array_1( 'mem', $_ );
}

no strict 'refs';

# get_ direct
my @OIDS = memOIDs();

# -1 because last key (Total) isn't an OID; rather, calculated from 2 other OIDs
for my $o ( 0 .. $#OIDS - 1 ) {
    *{"get_mem" . $OIDS[$o]} = sub {
        my $self = shift;
        my ($val) = @_;

        if ( not defined $val ) { $val = 0 }
        my $s = $self->session;
        my $r = $s->get_request(
            varbindlist => [_memOID() . '.' . ( $o + 2 ) . '.' . $val] );
        return $r->{_memOID() . '.' . ( $o + 2 ) . '.' . $val};
      }
}

##################################################
# End Public Module
##################################################

1;

__END__

##################################################
# Start POD
##################################################

=head1 NAME

Cisco::SNMP::Memory - Memory Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::Memory;

=head1 DESCRIPTION

The following methods are for memory utilization.  These methods
implement the C<CISCO-MEMORY-POOL-MIB>.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP::Memory object

  my $cm = Cisco::SNMP::Memory->new([OPTIONS]);

Create a new B<Cisco::SNMP::Memory> object with OPTIONS as optional parameters.
See B<Cisco::SNMP> for options.

=head2 memOIDs() - return OID names

  my @memOIDs = $cm->memOIDs();

Return list of Memory MIB object ID names.

=head2 memory_info() - return memory utilization info

  my $meminfo = $cm->memory_info();

Populate a data structure with memory information.  If successful,
returns a pointer to an array containing memory information.

  $meminfo->[0]->{'Name', 'Used', 'Free', ...}
  $meminfo->[1]->{'Name', 'Used', 'Free', ...}
  ...
  $meminfo->[n]->{'Name', 'Used', 'Free', ...}

Allows the following accessors to be called.

=head3 memName() - return memory name

  $meminfo->memName([#]);

Return the name of the memory at index '#'.  Defaults to 0.

=head3 memAlternate() - return memory alternate count

  $meminfo->memAlternate([#]);

Return the alternate count of the memory at index '#'.  Defaults to 0.

=head3 memValid() - return memory valid count

  $meminfo->memValid([#]);

Return the valid count of the memory at index '#'.  Defaults to 0.

=head3 memUsed() - return memory used count

  $meminfo->memUsed([#]);

Return the used count of the memory at index '#'.  Defaults to 0.

=head3 memFree() - return memory free count

  $meminfo->memFree([#]);

Return the free count of the memory at index '#'.  Defaults to 0.

=head3 memLargestFree() - return memory largest free count

  $meminfo->memLargestFree([#]);

Return the largest free count of the memory at index '#'.  Defaults to 0.

=head3 memTotal() - return memory total count

  $meminfo->memTotal([#]);

Return the total count of the memory at index '#'.  Defaults to 0.  This is a 
derived value, not an actual MIB OID.

=head1 DIRECT ACCESS METHODS

The following methods can be called on the B<Cisco::SNMP::Memory> object 
directly to access the values directly.

=over 4

=item B<get_memName> (#)

=item B<get_memAlternate> (#)

=item B<get_memValid> (#)

=item B<get_memUsed> (#)

=item B<get_memFree> (#)

=item B<get_memLargestFree> (#)

Get Memory OIDs where (#) is the OID instance, not the index from 
C<memory_info>.  If (#) not provided, uses 0.

=back

=head1 INHERITED METHODS

The following are inherited methods.  See B<Cisco::SNMP> for more information.

=over 4

=item B<close>

=item B<error>

=item B<session>

=back

=head1 EXPORT

None by default.

=head1 EXAMPLES

This distribution comes with several scripts (installed to the default
C<bin> install directory) that not only demonstrate example uses but also
provide functional execution.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2015

L<http://www.VinsWorld.com>

All rights reserved

=cut
