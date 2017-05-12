package Cisco::UCS::Common::EthernetPort;

use warnings;
use strict;

use Carp qw(croak);
use Scalar::Util qw(weaken);

our $VERSION = '0.51';

our @ATTRIBUTES = qw( dn epDn mac mode type);

our %ATTRIBUTES = (
	admin_state			=> 'adminState',
	chassis_id			=> 'chassisId',
	if_role				=> 'ifRole',
	if_type				=> 'ifType',
	label				=> 'usrLabel',
	license_state			=> 'licState',
	oper_state			=> 'operState',
	oper_speed			=> 'operSpeed',
	peer_dn				=> 'peerDn',
	peer_port_id			=> 'peerPortId',
	rcvr_type			=> 'xcvrType',
	switch_id			=> 'switchId',
	id				=> 'portId'
);

our %STATS = (
	err				=> 'etherErrStats',
	rx				=> 'etherRxStats',
	tx				=> 'etherTxStats'
	);

our %TX_STATS = our %RX_STATS = (
	intervals			=> 'intervals',
	timestamp			=> 'timeCollected',
	suspect				=> 'suspect',
	update				=> 'update',
	broadcast_packets		=> 'broadcastPackets',
	broadcast_packets_delta		=> 'broadcastPacketsDelta', 
	broadcast_packets_delta_avg	=> 'broadcastPacketsDeltaAvg',
	broadcast_packets_delta_min	=> 'broadcastPacketsDeltaMin',
	broadcast_packets_delta_max	=> 'broadcastPacketsDeltaMax',
	jumbo_packets			=> 'jumboPackets',
	jumbo_packets_delta		=> 'jumboPacketsDelta',
	jumbo_packets_delta_avg		=> 'jumboPacketsDeltaAvg',
	jumbo_packets_delta_min		=> 'jumboPacketsDeltaMin',
	jumbo_packets_delta_max		=> 'jumboPacketsDeltaMax',
	multicast_packets		=> 'multicastPackets',
	multicast_packets_delta		=> 'multicastPacketsDelta',
	multicast_packets_delta_avg	=> 'multicastPacketsDeltaAvg',
	multicast_packets_delta_min	=> 'multicastPacketsDeltaMin',
	multicast_packets_delta_max	=> 'multicastPacketsDeltaMax',
	total_bytes			=> 'totalBytes',
	total_bytes_delta		=> 'totalBytesDelta',
	total_bytes_delta_avg		=> 'totalBytesDeltaAvg',
	total_bytes_delta_min		=> 'totalBytesDeltaMin',
	total_bytes_delta_max		=> 'totalBytesDeltaMax',
	total_packets			=> 'totalPackets',
	total_packets_delta		=> 'totalPacketsDelta',
	total_packets_delta_avg		=> 'totalPacketsDeltaAvg',
	total_packets_delta_min		=> 'totalPacketsDeltaMin',
	total_packets_delta_max		=> 'totalPacketsDeltaMax',
	unicast_packets			=> 'unicastPackets',
	unicast_packets_delta		=> 'unicastPacketsDelta',
	unicast_packets_delta_avg	=> 'unicastPacketsDeltaAvg',
	unicast_packets_delta_min	=> 'unicastPacketsDeltaMin',
	unicast_packets_delta_max	=> 'unicastPacketsDeltaMax'
);

our %ERR_STATS = (
	intervals			=> 'intervals',
	update				=> 'update',
	suspect				=> 'suspect',
	timestamp			=> 'timeCollected',
	align				=> 'align',
	align_delta			=> 'alignDelta',
	align_delta_avg			=> 'alignDeltaAvg',
	align_delta_min			=> 'alignDeltaMin',
	align_delta_max			=> 'alignDeltaMax',
	deferred_tx			=> 'deferredTx',
	deferred_tx_delta		=> 'deferredTxDelta',
	deferred_tx_delta_avg		=> 'deferredTxDeltaAvg',
	deferred_tx_delta_min		=> 'deferredTxDeltaMin',
	deferred_tx_delta_max		=> 'deferredTxDeltaMax',
	fcs				=> 'fcs',
	fcs_delta			=> 'fcsDelta',
	fcs_delta_avg			=> 'fcsDeltaAvg',
	fcs_delta_min			=> 'fcsDeltaMin',
	fcs_delta_max			=> 'fcsDeltaMax',
	int_mac_tx			=> 'intMacTx',
	int_mac_tx_delta		=> 'intMacTxDelta',
	int_mac_tx_delta_avg		=> 'intMacTxDeltaAvg',
	int_mac_tx_delta_min		=> 'intMacTxDeltaMin',
	int_mac_tx_delta_max		=> 'intMacTxDeltaMax',
	int_mac_rx			=> 'intMacRx',
	int_mac_rx_delta		=> 'intMacRxDelta',
	int_mac_rx_delta_avg		=> 'intMacRxDeltaAvg',
	int_mac_rx_delta_min		=> 'intMacRxDeltaMin',
	int_mac_rx_delta_max		=> 'intMacRxDeltaMax',
	out_discard			=> 'outDiscard',
	out_discard_delta		=> 'outDiscardDelta',
	out_discard_delta_avg		=> 'outDiscardDeltaAvg',
	out_discard_delta_min		=> 'outDiscardDeltaMin',
	out_discard_delta_max		=> 'outDiscardDeltaMax',
	rcv				=> 'rcv',
	rcv_delta			=> 'rcvDelta',
	rcv_delta_avg			=> 'rcvDeltaAvg',
	rcv_delta_min			=> 'rcvDeltaMin',
	rcv_delta_max			=> 'rcvDeltaMax',
	undersize			=> 'underSize',
	undersize_delta			=> 'underSizeDelta',
	undersize_delta_avg		=> 'underSizeDeltaAvg',
	undersize_delta_min		=> 'underSizeDeltaMin',
	undersize_delta_max		=> 'underSizeDeltaMax',
	xmit				=> 'xmit',
	xmit_delta			=> 'xmitDelta',
	xmit_delta_avg			=> 'xmitDeltaAvg',
	xmit_delta_min			=> 'xmitDeltaMin',
	xmit_delta_max			=> 'xmitDeltaMax'
);

sub new {
        my ( $class, %args ) = @_; 

        my $self = {}; 
        bless $self, $class;

        defined $args{dn}
		? $self->{dn} = $args{dn}
		: croak 'dn not defined';

        defined $args{ucs}
		? weaken( $self->{ucs} = $args{ucs} )
		: croak 'ucs not defined';

        my %attr = %{ $self->{ucs}->resolve_dn(
				dn => $self->{dn}
			)->{outConfig}->{etherPIo}};

	{
        	no strict 'refs';
		no warnings qw(redefine);

		while ( my ( $pseudo, $attribute ) = each %STATS ) { 
			*{ __PACKAGE__ . '::' . 'get_' . $pseudo . '_stats' } = sub {
				my $self = shift;
				return $self->_get_stats( $pseudo, $attribute )
			}    
		} 
	}
    
        while ( my ( $k, $v ) = each %attr ) { $self->{$k} = $v }
    
        return $self;
}

sub _get_stats {
	my ( $self, $type, $class ) = @_;

	my %stats = %{ ( $self->{ucs}->resolve_dn(
				dn => "$self->{dn}/$type-stats"
			) )->{outConfig}->{$class} };
	
	while ( my ( $k, $v ) = each %stats ) { $self->{$type}->{$k} = $v }

	return %stats
}

{
        no strict 'refs';

        while ( my ( $pseudo, $attribute ) = each %ATTRIBUTES ) {
                *{ __PACKAGE__ . '::' . $pseudo } = sub {
                        my $self = shift;
                        return $self->{$attribute}
                }       
        }               
                
        foreach my $attribute ( @ATTRIBUTES ) {
                *{ __PACKAGE__ . '::' . $attribute } = sub {
                        my $self = shift;
                        return $self->{$attribute} 
                }       
        }               

	foreach my $type ( keys %STATS ) {
		my $type_stats = uc( $type ) . '_STATS';

		while ( my ( $pseudo, $attribute ) = each %{$type_stats} ) {
			*{ __PACKAGE__ . '::' . $type . "_$pseudo" } = sub {
				my $self = shift;

				my $method = "get_$type" . "_$pseudo";
				defined $self->{$type}->{$attribute} or $self->$method;
				return $self->{$type}->{$attribute};
			};

			*{ __PACKAGE__ . '::' . "get_$type" . "_$pseudo" } = sub {
				my $self = shift;

				my $method = "get_$type" . '_stats';
				$self->$method;
				return $self->{$type}->{$attribute}
			}
		}
	}

}

1;

__END__

=pod

=head1 NAME

Cisco::UCS::Common::EthernetPort - Class for operations with a Cisco UCS 
Ethernet Port.

=head1 SYNOPSIS

    print "FI A port 1/2 operational_speed is " 
		. $ucs->interconnect(A)->card(1)->eth_port(2)->oper_speed;
		. ', total bytes transmitted is "
		. $ucs->interconnect(A)->card(1)->eth_port(1)->tx_total_bytes
		. ".\n";

    # Prints: 
    # FI A port 1/2 operational_speed is 10gbps, total bytes transmitted is 120230320434028.

=head1 DESCRIPTION

Cisco::UCS::Common::EthernetPort is a class used to represent a single 
Ethernet port in a L<Cisco::UCS> system.  This class provides functionality to 
retrieve information and statistics for Ethernet ports.

Please note that you should not need to call the constructor directly as 
Cisco::UCS::Common::EthernetPort objects are created for you automatically via 
methods in other L<Cisco::UCS> packages like the i<get_ports> method in 
L<Cisco::UCS::Interconnect>.

Dependent on UCSM version, some attributes of the Ethernet port may not be 
provided and hence the accessor methods may return an empty string.

=head1 METHODS

=head2 admin_state

The administrative state of the port.

=head2 chassis_id

The numeric id of the chassis to which this port is connected.  This value 
will be blank for port that are configured as network uplinks.

=head2 dn

The distinguished name of the port in the Cisco UCS management heirarchy.

=head2 epDn

The dn of the object to which the remote end of this port is connected.

=head2 id

The port number in the relevant to the current slot.

=head2 if_role

The role of the port. e.g. 'server' for server links or 'network' for network 
uplinks.

=head2 if_type

The type of the port - either physical or virtual.

=head2 label

The user-defined label given to the port (may be blank).

=head2 license_state

The license state of the port.

=head2 mac

The MAC address of the port.

=head2 mode

The access mode of the port.

=head2 peer_dn

The UCS management heirarchy distinguished name of the peer port to which this 
port is connected.

=head2 peer_port_id

The numerical identifier of the peer port to which this port is connected.

=head2 oper_state

The operational state of the port.

=head2 oper_speed

The operational speed of the port.

=head2 rcvr_type

The physical interface receiver type.

=head2 switch_id

The id of the Fabric Interconnect on which the port is located.

=head2 type

The network type of the port.

=head1 STATISTICAL METHODS

The statistics methods listed below allow retrieval of interface counter 
statistical data.  These methods fall into three broad categories; transmit 
(I<tx>), receive (I<rx>) and error (I<err>).

=head1 CACHING AND NON-CACHING STATISTICAL METHODS

All statistical methods are implemented in both a non-caching and caching 
form; non-caching methods always query the UCSM for data retrieval and 
therefore may be more expensive in terms of system and network resources than 
the equivalent caching method.  Non-caching methods are always named using the
form: 

   get_<type>_<counter_name>

Where B<type> is one of rx, tx or err as described in the B<STATISTICS METHODS>
section above, and B<counter_name> is the name of the counter as per the 
section below.

Caching methods return a cached result retrieved during a previous query if 
available, if cached data retrieved from a previous query is not available, 
then a the UCSM is queried for the requested data. Caching methods are named 
using the same form as non-caching methods excluding the prefix B<get_>.

Because UCSM queries may be expensive it is important to note the way in which 
caching has been implemented and the potential side-effects that this may have.
In brief, when a non-caching method is executed for a particular counter type 
(tx, rx or err) either implicitly or explicitly, all other available counters 
for that type are also retrieved and cached.

This may introduce side-effects and action-at-a-distance and thus, and 
Cisco::UCS::Common::EthernetPort objects cannot be considered reentrant.

=head1 COMMON STATISTICAL METHODS

Transmit, receive and error counter data share the following common methods 
that are a function of the underlying collection method.

=head2 get_tx_intervals get_rx_intervals get_err_intervals tx_intervals rx_intervals err_intervals

Returns the number of counter collection intervals that have elapsed since 
the last clearing of interface counters.

=head2 get_tx_timestamp get_rx_timestamp get_err_timestamp tx_timestamp rx_timestamp err_timestamp

Returns the timestamp of the last time that the counter was updated.

=head2 get_tx_suspect get_rx_suspect get_err_suspect tx_suspect rx_suspect err_suspect

Returns a true value if the counter information is suspect, returns null 
otherwise.

=head2 get_tx_update get_rx_update get_err_update tx_update rx_update err_update

Returns the (assumed) update number for the retrieved statistics data.

=head1 TRANSMIT AND RECEIVE STATISTICAL METHODS

The methods listed below are common to transmit and receive methods with the 
implied understanding that transmit refers to counter values for data out and 
receive refers to counter data for traffic in.

=head2 get_tx_broadcast_packets get_rx_broadcast_packets tx_broadcast_packets rx_broadcast_packets

Returns the number of tranmitted or received broadcast packets for the 
specified interface.

=head2 get_tx_broadcast_packets_delta get_rx_broadcast_packets_delta rx_broadcast_packets_delta tx_broadcast_packets_delta 

Returns the delta value of the number of transmitted or received broadcast 
packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_broadcast_packets_delta_avg get_rx_broadcast_packets_delta_avg rx_broadcast_packets_delta_avg tx_broadcast_packets_delta_avg 

Returns the average delta value of the number of transmitted or received 
broadcast packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_broadcast_packets_delta_min get_rx_broadcast_packets_delta_min rx_broadcast_packets_delta_min tx_broadcast_packets_delta_min 

Returns the minimum delta value of the number of transmitted or received 
broadcast packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_broadcast_packets_delta_max get_rx_broadcast_packets_delta_max rx_broadcast_packets_delta_max tx_broadcast_packets_delta_max 

Returns the maximum delta value of the number of transmitted or received 
broadcast packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_jumbo_packets get_rx_jumbo_packets rx_jumbo_packets tx_jumbo_packets 

Returns the number of transmitted or received jumbo packets for the specified 
interface between the current and previous collection period.

=head2 get_tx_jumbo_packets_delta get_rx_jumbo_packets_delta rx_jumbo_packets_delta tx_jumbo_packets_delta 

Returns the delta value of the number of transmitted or received jumbo packets 
for the specified interface between the current and previous collection period.

=head2 get_tx_jumbo_packets_delta_avg get_rx_jumbo_packets_delta_avg rx_jumbo_packets_delta_avg tx_jumbo_packets_delta_avg 

Returns the average delta value of the number of transmitted or received jumbo 
packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_jumbo_packets_delta_min get_rx_jumbo_packets_delta_min rx_jumbo_packets_delta_min tx_jumbo_packets_delta_min 

Returns the minimum delta value of the number of transmitted or received jumbo 
packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_jumbo_packets_delta_max get_rx_jumbo_packets_delta_max rx_jumbo_packets_delta_max tx_jumbo_packets_delta_max 

Returns the maximum delta value of the number of transmitted or received jumbo 
packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_multicast_packets get_rx_multicast_packets rx_multicast_packets tx_multicast_packets

Returns the number of transmitted or received multicast packets for the 
specified interface between the current and previous collection period.

=head2 get_tx_multicast_packets_delta get_rx_multicast_packets_delta rx_multicast_packets_delta tx_multicast_packets_delta 

Returns the delta value of the number of transmitted or received multicast 
packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_multicast_packets_delta_avg get_rx_multicast_packets_delta_avg rx_multicast_packets_delta_avg tx_multicast_packets_delta_avg 

Returns the average delta value of the number of transmitted or received 
multicast packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_multicast_packets_delta_min get_rx_multicast_packets_delta_min rx_multicast_packets_delta_min tx_multicast_packets_delta_min 

Returns the minimum delta value of the number of transmitted or received 
multicast packets for the specified interface between the current and 
previous collection period.

=head2 get_tx_multicast_packets_delta_max get_rx_multicast_packets_delta_max rx_multicast_packets_delta_max tx_multicast_packets_delta_max 

Returns the maximum delta value of the number of transmitted or received 
multicast packets for the specified interface between the current and 
previous collection period.

=head2 get_tx_total_bytes get_rx_total_bytes rx_total_bytes tx_total_bytes 

Returns the number of transmitted or received bytes for the specified 
interface between the current and previous collection period.

=head2 get_tx_total_bytes_delta get_rx_total_bytes_delta rx_total_bytes_delta tx_total_bytes_delta 

Returns the delta value of the number of transmitted or received bytes for the 
specified interface between the current and previous collection period.

=head2 get_tx_total_bytes_delta_avg get_rx_total_bytes_delta_avg rx_total_bytes_delta_avg tx_total_bytes_delta_avg 

Returns the average delta value of the number of transmitted or received bytes 
for the specified interface between the current and previous collection period.

=head2 get_tx_total_bytes_delta_min get_rx_total_bytes_delta_min rx_total_bytes_delta_min tx_total_bytes_delta_min 

Returns the minimum delta value of the number of transmitted or received bytes 
for the specified interface between the current and previous collection period.

=head2 get_tx_total_bytes_delta_max get_rx_total_bytes_delta_max rx_total_bytes_delta_max tx_total_bytes_delta_max 

Returns the maximum delta value of the number of transmitted or received bytes 
for the specified interface between the current and previous collection period.

=head2 get_tx_total_packets get_rx_total_packets rx_total_packets tx_total_packets 

Returns the number of transmitted or received packets for the specified 
interface between the current and previous collection period.

=head2 get_tx_total_packets_delta get_rx_total_packets_delta rx_total_packets_delta tx_total_packets_delta 

Returns the delta value of the number of transmitted or received packets for 
the specified interface between the current and previous collection period.

=head2 get_tx_total_packets_delta_avg get_rx_total_packets_delta_avg rx_total_packets_delta_avg tx_total_packets_delta_avg 

Returns the average delta value of the number of transmitted or received 
packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_total_packets_delta_min get_rx_total_packets_delta_min rx_total_packets_delta_min tx_total_packets_delta_min 

Returns the minimum delta value of the number of transmitted or received 
packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_total_packets_delta_max get_rx_total_packets_delta_max rx_total_packets_delta_max tx_total_packets_delta_max 

Returns the maximum delta value of the number of transmitted or received 
packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_unicast_packets get_rx_unicast_packets rx_unicast_packets tx_unicast_packets 

Returns the number of transmitted or received unicast packets for the 
specified interface between the current and previous collection period.

=head2 get_tx_unicast_packets_delta get_rx_unicast_packets_delta rx_unicast_packets_delta tx_unicast_packets_delta 

Returns the delta value of the number of transmitted or received unicast 
packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_unicast_packets_delta_avg get_rx_unicast_packets_delta_avg rx_unicast_packets_delta_avg tx_unicast_packets_delta_avg 

Returns the average delta value of the number of transmitted or received 
unicast packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_unicast_packets_delta_min get_rx_unicast_packets_delta_min rx_unicast_packets_delta_min tx_unicast_packets_delta_min 

Returns the minimum delta value of the number of transmitted or received 
unicast packets for the specified interface between the current and previous 
collection period.

=head2 get_tx_unicast_packets_delta_max get_rx_unicast_packets_delta_max rx_unicast_packets_delta_max tx_unicast_packets_delta_max 

Returns the maximum delta value of the number of transmitted or received 
unicast packets for the specified interface between the current and previous 
collection period.

=head1 ERROR STATISTICAL METHODS

=head2 get_err_align err_align 

Returns the number of allignment errors for the specified interface between 
the current and previous collection period.

=head2 get_err_align_delta err_align_delta 

Returns the delta value of the number of alignment errors for the specified 
interface between the current and previous collection period.

=head2 get_err_align_delta_avg err_align_delta_avg 

Returns the delta value of the number of alignment errors for the specified 
interface between the current and previous collection period.

=head2 get_err_align_delta_min err_align_delta_min 

Returns the minimum delta value of the number of alignment errors for the 
specified interface between the current and previous collection period.

=head2 get_err_align_delta_max err_align_delta_max 

Returns the maximum delta value of the number of alignment errors for the 
specified interface between the current and previous collection period.

=head2 get_err_deferred_tx err_deferred_tx 

Returns the number of deferrment errors for the specified interface between 
the current and previous collection period.

=head2 get_err_deferred_tx_delta err_deferred_tx_delta 

Returns the delta value of the number of deferrment errors for the specified 
interface between the current and previous collection period.

=head2 get_err_deferred_tx_delta_avg err_deferred_tx_delta_avg 

Returns the average delta value of the number of deferrment errors for the 
specified interface between the current and previous collection period.

=head2 get_err_deferred_tx_delta_min err_deferred_tx_delta_min 

Returns the minimum delta value of the number of deferrment errors for the 
specified interface between the current and previous collection period.

=head2 get_err_deferred_tx_delta_max err_deferred_tx_delta_max 

Returns the maximum delta value of the number of deferrment errors for the 
specified interface between the current and previous collection period.

=head2 get_err_fcs err_fcs 

Returns the number of frame check sequence errors for the specified interface 
between the current and previous collection period.

=head2 get_err_fcs_delta err_fcs_delta 

Returns the delta value of the number of frame check sequence errors for the 
specified interface between the current and previous collection period.

=head2 get_err_fcs_delta_avg err_fcs_delta_avg 

Returns the average delta value of the number of frame check sequence errors 
for the specified interface between the current and previous collection period.

=head2 get_err_fcs_delta_min err_fcs_delta_min 

Returns the minimum delta value of the number of frame check sequence errors 
for the specified interface between the current and previous collection period.

=head2 get_err_fcs_delta_max err_fcs_delta_max 

Returns the maximum delta value of the number of frame check sequence errors 
for the specified interface between the current and previous collection period.

=head2 get_err_int_mac_tx err_int_mac_tx 

Returns the number of interface MAC transmit errors for the specified 
interface between the current and previous collection period.

=head2 get_err_int_mac_tx_delta err_int_mac_tx_delta 

Returns the delta value of the number of interface MAC transmit errors for the 
specified interface between the current and previous collection period.

=head2 get_err_int_mac_tx_delta_avg err_int_mac_tx_delta_avg 

Returns the average delta value of the number of interface MAC transmit errors 
for the specified interface between the current and previous collection period.

=head2 get_err_int_mac_tx_delta_min err_int_mac_tx_delta_min 

Returns the minimum delta value of the number of interface MAC transmit errors 
for the specified interface between the current and previous collection period.

=head2 get_err_int_mac_tx_delta_max err_int_mac_tx_delta_max 

Returns the maximum delta value of the number of interface MAC transmit errors 
for the specified interface between the current and previous collection period.

=head2 get_err_int_mac_rx err_int_mac_rx 

Returns the number of interface MAC receive errors for the specified interface 
between the current and previous collection period.

=head2 get_err_int_mac_rx_delta err_int_mac_rx_delta 

Returns the delta value of the number of interface MAC receive errors for the 
specified interface between the current and previous collection period.

=head2 get_err_int_mac_rx_delta_avg err_int_mac_rx_delta_avg 

Returns the average delta value of the number of interface MAC receive errors 
for the specified interface between the current and previous collection period.

=head2 get_err_int_mac_rx_delta_min err_int_mac_rx_delta_min 

Returns the minimum delta value of the number of interface MAC receive errors 
for the specified interface between the current and previous collection period.

=head2 get_err_int_mac_rx_delta_max err_int_mac_rx_delta_max 

Returns the maximum delta value of the number of interface MAC receive errors 
for the specified interface between the current and previous collection period.

=head2 get_err_out_discard err_out_discard 

Returns the number of out-discard errors for the specified interface between 
the current and previous collection period.

=head2 get_err_out_discard_delta err_out_discard_delta 

Returns the delta value of the number of out-discard errors for the specified 
interface between the current and previous collection period.

=head2 get_err_out_discard_delta_avg err_out_discard_delta_avg 

Returns the average delta value of the number of out-discard errors for the 
specified interface between the current and previous collection period.

=head2 get_err_out_discard_delta_min err_out_discard_delta_min 

Returns the minimum delta value of the number of out-discard errors for the 
specified interface between the current and previous collection period.

=head2 get_err_out_discard_delta_max err_out_discard_delta_max 

Returns the maximum delta value of the number of out-discard errors for the 
specified interface between the current and previous collection period.

=head2 get_err_rcv err_rcv 

Returns the number of rcv-err errors for the specified interface between the 
current and previous collection period.

=head2 get_err_rcv_delta err_rcv_delta 

Returns the delta value of the number of rcv-err errors for the specified 
interface between the current and previous collection period.

=head2 get_err_rcv_delta_avg err_rcv_delta_avg 

Returns the average delta value of the number of rcv-err errors for the 
specified interface between the current and previous collection period.

=head2 get_err_rcv_delta_min err_rcv_delta_min 

Returns the minimum delta value of the number of rcv-err errors for the 
specified interface between the current and previous collection period.

=head2 get_err_rcv_delta_max err_rcv_delta_max 

Returns the maximum delta value of the number of rcv-err errors for the 
specified interface between the current and previous collection period.

=head2 get_err_undersize err_undersize 

Returns the number of undersize errors for the specified interface between the 
current and previous collection period.

=head2 get_err_undersize_delta err_undersize_delta 

Returns the delta value of the number of undersize errors for the specified 
interface between the current and previous collection period.

=head2 get_err_undersize_delta_avg err_undersize_delta_avg 

Returns the average delta value of the number of undersize errors for the 
specified interface between the current and previous collection period.

=head2 get_err_undersize_delta_min err_undersize_delta_min 

Returns the minimum delta value of the number of undersize errors for the 
specified interface between the current and previous collection period.

=head2 get_err_undersize_delta_max err_undersize_delta_max 

Returns the maximum delta value of the number of undersize errors for the 
specified interface between the current and previous collection period.

=head2 get_err_xmit err_xmit 

Returns the number of xmit-err errors for the specified interface between the 
current and previous collection period.

=head2 get_err_xmit_delta err_xmit_delta 

Returns the delta value of the number of xmit-err errors for the specified 
interface between the current and previous collection period.

=head2 get_err_xmit_delta_avg err_xmit_delta_avg 

Returns the average delta value of the number of xmit-err errors for the 
specified interface between the current and previous collection period.

=head2 get_err_xmit_delta_min err_xmit_delta_min 

Returns the minimum delta value of the number of xmit-err errors for the 
specified interface between the current and previous collection period.

=head2 get_err_xmit_delta_max err_xmit_delta_max 

Returns the maximum delta value of the number of xmit-err errors for the 
specified interface between the current and previous collection period.

=cut

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cisco-ucs-common-ethernetport at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-Common-EthernetPort>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Common::EthernetPort


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-Common-EthernetPort>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Common-EthernetPort>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Common-EthernetPort>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Common-EthernetPort/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
