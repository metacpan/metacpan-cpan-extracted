#
# DB2::Admin::DataElement - Decode leaf value in self-describing binary
#                           data stream used for snapshot, monitor
#                           switches, and events
#
# Copyright (c) 2007-2009, Morgan Stanley & Co. Incorporated
# See ..../COPYING for terms of distribution.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation;
# version 2.1 of the License.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
# General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301  USA
#
# THE FOLLOWING DISCLAIMER APPLIES TO ALL SOFTWARE CODE AND OTHER
# MATERIALS CONTRIBUTED IN CONNECTION WITH THIS DB2 ADMINISTRATIVE API
# LIBRARY:
#
# THIS SOFTWARE IS LICENSED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE AND ANY WARRANTY OF NON-INFRINGEMENT, ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. THIS
# SOFTWARE MAY BE REDISTRIBUTED TO OTHERS ONLY BY EFFECTIVELY USING
# THIS OR ANOTHER EQUIVALENT DISCLAIMER AS WELL AS ANY OTHER LICENSE
# TERMS THAT MAY APPLY.
#
# $Id: DataElement.pm,v 165.1 2009/02/05 14:46:02 biersma Exp $
#

package DB2::Admin::DataElement;

use strict;
use Carp;
use Config;                     # For byte-order

use DB2::Admin::Constants;

#
# Create a new DataElement object
#
# Parameters:
# - Element number
# - Type number
# - String with binary data
# Returns:
# - Newly created object
#
sub new {
    my ($class, $element, $type, $binary) = @_;

    confess "Not a DataElement: have type 1 (DataStream)"
      if ($type == 1);

    my $name = $DB2::Admin::Constants::constant_index->{'Element'}{$element};
    if (defined $name) {
        $name =~ s/^SQLM_ELM_// ||
          confess "Cannot remove prefix from element name [$name]";
    } else {
        $name = $element;
    }

    return bless { 'Name'    => $name,
                   'Element' => $element,
                   'Type'    => $type,
                   'Data'    => $binary,
                 }, $class;
}


sub getName {
    my ($this) = @_;

    return $this->{'Name'};
}


sub getDescription {
    my ($this) = @_;

    my $elem = $this->{'Element'};
    my $name = $DB2::Admin::Constants::constant_index->{'Element'}{$elem};
    return "unknown element $elem" unless (defined $name);
    return $DB2::Admin::Constants::constant_info->{$name}{'Comment'};
}


sub getValue {
    my ($this) = @_;

    unless (defined $this->{'Display'}) {
        $this->_decode();
    }
    return $this->{'Display'};
}


sub getRawValue {
    my ($this) = @_;

    unless (defined $this->{'Value'}) {
        $this->_decode();
    }
    return $this->{'Value'};
}


my (%decode_table, %type_table);
BEGIN {
    %decode_table = ('u8bit'  => 'C',
                     '8bit'   => 'c',
                     '16bit'  => 's',
                     'u16bit' => 'S',
                     '32bit'  => 'l',
                     'u32bit' => 'L',
                     'float'  => 'f',
                    );
    if (length($Config{byteorder}) == 8) {
        %decode_table = (%decode_table,
                         'u64bit' => 'Q',
                         '64bit'  => 'q',
                         );
    }
    foreach my $key ('string', 'handle',
                     'u64bit', '64bit', keys %decode_table) {
        next if ($key eq 'float'); # Used for config param, not data stream
        my $constant = 'SQLM_TYPE_' . uc($key);

        #
        # The 'handle' type is only available on 8.2.3+, and even then
        # not on Solaris.  To cater for that, we always eval the
        # constant lookup (for all types) and ignore any type not
        # known for the OS / DB2 release.
        #
        eval {
            my $constant_value = DB2::Admin::Constants::->GetValue($constant);
            $type_table{$constant_value} = $key;
        };
    }
}
sub Decode {
    my ($class, $type, $binary, $size) = @_;

    my $format = $decode_table{$type};
    if (defined $format) {
        return unpack($format, $binary);
    } elsif ($type eq 'string') {
        return unpack("Z$size", $binary);
    } elsif ($type eq 'u64bit' || $type eq '64bit') {
        #
        # Ouch: we are running 32-bit.  Manually decode 64-bit value.
        #
        my $byte_order = $Config{byteorder};
        my ($low, $high);
        if ($type eq 'u64bit') {
            ($low, $high) = unpack("L L", $binary);
        } else {
            ($low, $high) = unpack("l l", $binary);
        }
        unless ($byte_order eq '1234') { # Not little-endian
            ($low, $high) = ($high, $low);
        }
        if ($high) {
            return (1.0 * $high * (2 ** 16) * (2 ** 16)) + $low;
        } else {
            return $low;
        }
    } elsif ($type eq 'handle') { # Blob: treat as hex
        my $retval = '0x';
        $retval .= sprintf("%02x", ord(substr($binary, $_-1, 1)))
          foreach (1..length($binary));
        return $retval;
    } else {
        confess "Unexpected type code [$type]";
    }
}


#
# Encode a value into binary.  Used for db2CfgSet().
#
# Parameters:
# - Type name
# - Value
# Returns:
# - Binary value
#
sub Encode {
    my ($class, $type_name, $value) = @_;

    return $value if ($type_name eq 'string');
    my $format = $decode_table{$type_name};
    if (defined $format) {
        return pack($format, $value);
    } elsif ($type_name eq 'u64bit' ||
             $type_name eq '64bit') {
        #
        # 32-bit:  we only support 32-bit values, pack lower word only.
        #
        confess "Value [$value] too large for 32-bit systems"
          if (abs($value) > 2**32);
        my $low;
        if ($type_name eq 'u64bit') {
            $low = pack("L", $value);
        } else {
            $low = pack("l", $value);
        }
        if ($Config{byteorder} eq '1234') {
            return $low . pack("L", 0);
        } else {
            return pack("L", 0) . $low;
        }
    } else {
        confess "Unexpected type name [$type_name]";
    }
}


# ------------------------------------------------------------------------

sub _decode {
    my ($this) = @_;

    my $type = $type_table{ $this->{Type} } ||
      confess "No type name for type [$this->{Type}] and element [$this->{Name}]";
    my $value = $this->{'Value'} = $this->
      Decode($type, $this->{Data}, length($this->{Data}));

    #
    # Custom formatting
    #
    my $display = $value;
    if ($this->{'Name'} eq 'APPL_ID' ||
        $this->{'Name'} eq 'APPL_ID_HOLDING_LK' ||
        $this->{'Name'} eq 'CORR_TOKEN' ||
        $this->{'Name'} eq 'ROLLED_BACK_APPL_ID') {
        if ($value !~ /^\*(LOCAL|N\d)/) {
            #
            # According to the Viper GA docs, the format
            # this can have is:
            #
            # - APPC: CAIBMTOR.OSFDBX0.930131194520
            # - TCP/IP for IPv4: 900E1AA1.47E2.040326210233
            # - TCP/IP for IPv6: 1111:2222:3333:4444:5555:6666:
            #                    7777:8888.65535.0123456789AB
            # - IPX/SPX: C11A8E5C.400011528250.0131214645
            # - NetBIOS: *NETBIOS.SBOIVIN.930131214645
            # - Local: *LOCAL.DB2INST1.930131235945 or
            #          *N2.DB2INST1.0B5A12222841 (DPF)
            #
            # The docs are incomplete, though.  There's another
            # case for TCP/IP v4, for V9.1 clients, where you get:
            # - TCP/IP for IPv4: 192.168.1.14.12345.040326210233
            #
            # We only handle the TCP/IP case (who uses the other
            # protocols anymore).
            #
            # Another detail for TCP/IP v4:
            #
            # Data like 900E1AA1.47E2.040326210233
            # is IP:port:instance
            #
            # If the first letter of IP address or port would be
            # in 0-9, IBM uses G-P instead.  We fix that below.
            #
            if ($display =~ /^(\d+\.\d+\.\d+\.\d+)\.(\d+)\.(\d+)$/) {
                #
                # New IPV4 format
                #
                $display = "$1 port $2 ($3)";
                #print STDERR "XXX: new-style IP v4 - $display\n";
            } elsif ($display =~ /^(\d[\d:]+\d)\.(\d+)\.(\d+)$/) {
                #
                # IPv6 format
                #
                $display = "$1 port $2 ($3)";
            } else {            # Assume old-style IPv4
                my ($raw_ip, $raw_port, $raw_instance) =
                  split /\./, $display;
                #print STDERR "XXX: $this->{Name} display [$display], IP [$raw_ip], port [$raw_port]\n";
                substr($raw_ip, 0, 1) =~ tr/G-P/0-9/;
                substr($raw_port, 0, 1) =~ tr/G-P/0-9/;
                my @ip = map hex(substr($raw_ip, $_ * 2, 2)), (0..3);
                my @port = map hex(substr($raw_port, $_ * 2, 2)), (0..1);
                $display = join('.', @ip) . " port ";
                $display .= ($port[1] << 8) + $port[0];
                $display .= " ($raw_instance)";
                #print STDERR "XXX: old-style IP v4 - $display\n";
            }                   # End if: not new-style IPv4 / IPv6
        }
    } elsif ($this->{'Name'} eq 'APPL_STATUS') {
        my %status_table = (1  => 'connect pending',
                            2  => 'connect completed',
                            3  => 'UOW executing',
                            4  => 'UOW waiting',
                            5  => 'lock wait',
                            6  => 'commit active',
                            7  => 'rollback active',
                            8  => 'recompiling plan',
                            9  => 'compiling SQL stmt',
                            10 => 'request interrupted',
                            11 => 'disconnect pending',
                            12 => 'prepared transaction',
                            13 => 'heuristically committed',
                            14 => 'heuristically rolled back',
                            15 => 'transaction ended',
                            16 => 'creating database',
                            17 => 'restarting database',
                            18 => 'restoring database',
                            19 => 'performing backup',
                            20 => 'performing fast load',
                            21 => 'performing fast unload',
                            22 => 'wait to disable tablespace',
                            23 => 'quiescing tablespace',
                            24 => 'waiting for remote node',
                            25 => 'pending results from remote request',
                            26 => 'app decoupled from coord',
                            27 => 'rollback to savepoint',
                           );
        $display = $status_table{$value} ||
          "(unknown application status code $value)";
    } elsif ($this->{'Name'} eq 'CLIENT_PLATFORM' ||
             $this->{'Name'} eq 'SERVER_PLATFORM') {
        $display = DB2::Admin::Constants::->Lookup('Platform', $value) ||
          "<unknown client platform $value>";
    } elsif ($this->{'Name'} eq 'CONTAINER_TYPE') {
        $display = DB2::Admin::Constants::->Lookup('ContainerType', $value) ||
          "<unknown container type $value>";
    } elsif ($this->{'Name'} eq 'HADR_CONNECT_STATUS') {
        $display = DB2::Admin::Constants::->Lookup('HadrConnectStatus', $value) ||
          "<unknown HADR connect status $value>";
    } elsif ($this->{'Name'} eq 'HADR_ROLE') {
        $display = DB2::Admin::Constants::->Lookup('HadrRole', $value) ||
          "<unknown HADR role $value>";
    } elsif ($this->{'Name'} eq 'HADR_STATE') {
        $display = DB2::Admin::Constants::->Lookup('HadrState', $value) ||
          "<unknown HADR state $value>";
    } elsif ($this->{'Name'} eq 'HADR_SYNCMODE') {
        $display = DB2::Admin::Constants::->Lookup('HadrSyncMode', $value) ||
          "<unknown HADR sync mode $value>";
    } elsif ($this->{'Name'} eq 'LOCK_MODE' ||
             $this->{'Name'} eq 'LOCK_MODE_REQUESTED') {
        my $constant = DB2::Admin::Constants::->Lookup('LockMode', $value);
        if (defined $constant) {
            my $info = DB2::Admin::Constants::->GetInfo($constant);
            $display = $info->{'Comment'};
        } else {
            $display = "<unknown lock mode $value>";
        }
    } elsif ($this->{'Name'} eq 'LOCK_OBJECT_TYPE') {
        $display = DB2::Admin::Constants::->Lookup('LockObjectType', $value) ||
          "<unknown lock object type $value>";
    } elsif ($this->{'Name'} eq 'POOL_ID') {
        my $constant = DB2::Admin::Constants::->Lookup('Heap', $value);
        if (defined $constant) {
            $display = $constant;
        } else {
            $display = "<unknown pool id $value>";
        }
    } elsif ($this->{'Name'} eq 'REORG_STATUS') {
        $display = DB2::Admin::Constants::->Lookup('ReorgStatus', $value) ||
          "<unknown reorg status $value>";
    } elsif ($this->{'Name'} eq 'STMT_OPERATION') {
        my $constant = DB2::Admin::Constants::->Lookup('StatementOperation', $value);
        if (defined $constant) {
            my $info = DB2::Admin::Constants::->GetInfo($constant);
            $display = $info->{'Comment'};
        } else {
            $display = "<unknown statement operation $value>";
        }
    } elsif ($this->{'Name'} eq 'STMT_TYPE') {
        my $constant = DB2::Admin::Constants::->Lookup('StatementType', $value);
        if (defined $constant) {
            my $info = DB2::Admin::Constants::->GetInfo($constant);
            $display = $info->{'Comment'};
        } else {
            $display = "<unknown statement type $value>";
        }
    } elsif ($this->{'Name'} eq 'TABLE_TYPE') {
        my $constant = DB2::Admin::Constants::->Lookup('TableType', $value);
        if (defined $constant) {
            my $info = DB2::Admin::Constants::->GetInfo($constant);
            $display = $info->{'Comment'};
        } else {
            $display = "<unknown table type $value>";
        }
    } elsif ($this->{'Name'} eq 'TABLESPACE_TYPE') {
        if ($value == 0) {
            $display = 'DMS';
        } elsif ($value == 1) {
            $display = 'SMS';
        } else {
            confess "Unexpected value [$value] for element [$this->{Name}]";
        }
    } elsif ($this->{'Name'} eq 'UTILITY_TYPE') {
        my $constant = DB2::Admin::Constants::->Lookup('UtilityType', $value);
        if (defined $constant) {
            $display = $constant;
            $display =~ s/^SQLM_UTILITY_//;
        } else {
            $display = "<unknown utility type $value>";
        }
    }

    $this->{'Display'} = $display;
}


1;

__END__


=head1 NAME

DB2::Admin::DataElement - Support for DB2 self-describing data stream

=head1 SYNOPSIS

  use DB2::Admin::DataStream;

  #
  # Get binary data from snapshot or event file/pipe, then...
  #
  my $stream = DB2::Admin::DataStream::->new($binary_data);

  #
  # Access to a particular node (two alternatives)
  #
  my $node = $stream->findNode('SWITCH_LIST/UOW_SWITCH/SWITCH_SET_TIME/SECONDS');
  my $time_sec = $node->getValue();
  my $time_msec = $stream->findValue('SWITCH_LIST/UOW_SWITCH/SWITCH_SET_TIME/MICROSEC');


=head1 DESCRIPTION

The DB2 administrative API returns several types of return values in a
so-called 'self-describing data stream'.  The data stored in event
files or written to event pipes is in the same format.  The data
format and all element types plus their values, are described in the
"System Monitor Guide and Reference" (SC09-4847).

Access to this data stream is provided through the
C<DB2::Admin::DataStream> class, which converts the data stream into a
tree of objects.  The leaf nodes of the tree hold the data and are
implemented using the present class, C<DB2::Admin::DataElement>.

In most cases, access to data elements is not performed through this
class, but through utiltiy methods in the C<DB2::Admin::DataStream>
class, such as C<findValue> and C<getValues>.  Data element objects
are most commonly used when traversing a tree hierarchicaly to process
all elements, or when access to raw data is required.

=head1 METHODS

=head2 new

This method creates a C<Db2API::DataElement> object from a numerical
element code, a data type, and a string of binary data.  It is not
intended to be called from applications; instead it is invoked by the
C<DB2::Admin::DataStream> class when it needs to create leaf nodes.

=head2 getName

This method returns the name of a node, e.g. 'DBASE'.  The
C<DB2::Admin::DataStream> class supports the same method, so this can
safely be invoked on any object.

=head2 getDescription

This method returns the description of a node, e.g. 'database
information'.  This description is parsed from the DB2 header files at
C<DB2::Admin> module compile time.  The C<DB2::Admin::DataStream>
class supports the same method, so this can safely be invoked on any
object.

=head2 getValue

This method returns the value of a C<DB2::Admin::DataElement> object.
The value is in display format, i.e. for some enumerated element types
such as platform and container type, the data has been formatted from
a numerical value into a human-readable display format.  Use the
C<getRawValue> method to get the numerical data.

=head2 getRawValue

This method returns the 'raw' value of a C<DB2::Admin::DataElement>
object.  This is virtually always the same as the result of the
C<getValue> method, except for those cases where enumerate types have
been formatted into human-readblbe format.  This method is rarely
used.

=head2 Decode

This class method is invoked with a string type code, a binary value
and size as returned by the snapshot, event monitor, and configuration
parameter methods.  It decodes the bianry value into a string or
number and returns it.  It is used internally to get the raw value of
a data element, and is also invoked from the C<DB2::Admin> class to
decode values returned from the C<GetDbmConfig> and
C<GetDatabaseConfig> methods.

=head2 Encode

This class method is invoked with a string type code and a numerical
or string value, which is then encoded into binary.  It is invoked
from the C<DB2::Admin> class to encode values specified with the
C<SetDbmConfig> and C<SetDatabaseConfig> methods.

=head1 AUTHOR

Hildo Biersma

=head1 SEE ALSO

Db2API(3), DB2::Admin::Constants(3), DB2::Admin::DataStream(3)

=cut
