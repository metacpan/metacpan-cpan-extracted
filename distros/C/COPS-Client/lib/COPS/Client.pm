package COPS::Client;

use warnings;
use strict;
use IO::Select;
use IO::Socket;
use IO::Handle;

=head1 NAME

COPS::Client - COPS Protocol - Packet Cable Client 

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    This module provides a simple COPS client for managing Packet Cable Multi
Media sessions for CMTS. It should provide all the neccessary functionality to
enable a service provider to deploy, manage and control service flows within
their network. This does not maintain a connection to the CMTS but issue the
configured command, get the response and then close the TCP connection. I am
working on a stateful Client however this is not yet available.

    As basic initial use of the module is as follows

    my $cops_client = new COPS::Client (
        [
        ServerIP => '192.168.0.1',
        ServerPort => '3918',
        Timeout => 2,
        DataHandler => \&display_data
        ]
        );

    $cops_client->set_command("set");
    $cops_client->subscriber_set("ipv4","172.20.1.1");

    $cops_client->gate_specification_add(
        [
        Direction       => 'Downstream',
        DSCPToSMark     => 0,
        Priority        => 0,
        PreEmption      => 0,
        Gate_Flags      => 0,
        Gate_TOSField   => 0,
        Gate_TOSMask    => 0,
        Gate_Class      => 0,
        Gate_T1         => 0,
        Gate_T2         => 0,
        Gate_T3         => 0,
        Gate_T4         => 0
        ]
        );

    $cops_client->classifier_add(
        [
        Classifier_Type         => 'Classifier',
        Classifier_Priority => 64,
        Classifier_SourceIP => "172.20.1.1",
        ]
        );

    $cops_client->envelope_add (
        [
        Envelope_Type           => "authorize,reserve,commit",
        Service_Type            => 'DOCSIS Service Class Name',
        ServiceClassName 	=> 'S_down'
        ]
        );

    $cops_client->connect();
    $cops_client->check_data_available();

    This will connect to a CMTS on IP 192.168.0.1 and apply a PCMM gate to 
the subscriber with IP address 172.20.1.1 and apply the service class S_down.

    It should be noted not all CMTS support all the functions available, so
    if the COPS request is failing for you remove opaque_set, timebase_set or
    volume_set and try again.

    You may also get a very cryptic error if an envelope or classifier is
    incorrectly configured.

=head1 EXPORT

There are no exports.

=head1 FUNCTIONS

    new
    set_command
    subscriber_set
    gate_specification_add
    classifier_add
    envelope_add
    rks_set
    decode_radius_attribute
    volume_set
    timebase_set
    opaque_set

=head2 new

    The new function initialises the module and sets the CMTS IP, Port and
the data handling function which gets called if a RTP message is received.

    The parameters are

        ServerIP    -  The IP address of the CMTS to connect to

        ServerPort  -  The port that the Packet Cable service is running
                       on. There is no default value however most server
                       implementations use port 3918, so this should be
                       set to that

        Timeout     -  This is a timeout parameter for the connection to the
                       CMTS. It has a default of 5 so can be omitted.

        DataHandler -  This should be set to point to a local function to
                       handle any data returned by a COPS message sent.

                       The function will accept 2 variables as input the
                       first is the module point, the second is a point to
                       a hash containing any data returned.

    An example of use would be.

    my $cops_client = new COPS::Client (
        [
        ServerIP => '192.168.0.1',
        ServerPort => '3918',
        Timeout => 2,
        DataHandler => \&display_data
        ]
        );

    sub display_data
        {
        my ( $self ) = shift;
        my ( $data ) = shift;
        print "Report Datagram sent.\n\n";
        foreach my $name ( sort { $a cmp $b } keys %{$data} )
            {
            print "Attribute Name  is '$name' value is '${$data}{$name}'\n";
            }
        }

=head2 set_command

    This command sets the type of command to be sent in the connection. It
    can be one of 4 types as follows

            set        -    Meaning GateSet
            delete     -    Meaning GateDelete
            info       -    Meaning GateInfo
            synch      -    Meaning Synch Request

    An example of use is

        $cops_client->set_command ( "set" );

    The command specified must match *Exactly* otherwise it will be ignored. It
    appears Cisco CMTS do NOT respond to Synch requests. Cisco have been asked
    to respond to this query but no information has been forthcoming.

=head2 subscriber_set

    This function sets the subscriber ID to be used. The subcriber ID can be
    either an IPV4 or IPV6 address. If you use an IPV6 address it *MUST* be
    fully qualified.

    The function takes two parameters the first specifies which IPVx to use,
    the second is the IPVx value.

    An example of use is

        $cops_client->subscriber_set("ipv4","172.20.1.1");

    The subscriber ID is required for 99% of all COPS messages.

=head2 gate_specification_add

    This function builds a gate with the attributes specified. Possible
    attributes are

        Direction      -  This can be 'Upstream' or 'Downstream' only.
                          If specified this overrides Gate_Flags as
                          direction is one bit of the Gate_Flags 
                          parameter.

        Priority       -  This is a value of 0 to 7. If specified this
                          overrides Gate_Class as Priority is 3 bits
                          of that parameter.

        PreEmption     -  This has a value of 0 or 1. This allows this
                          gate to take bandwidth from any other gates
                          already set against this subscriber. If
                          specified this overrides Gate_Class as this is
                          1 bit of that parameter.

        DSCPToSMark    -  This has a value of 0 or 1

        Priority       -  This has a value between 0 and 255 and should
                          determine the priority of the gate.

        Gate_Flags     -  This field is broken down into 2 used bits and
                          6 unused bits.

                          Bit 0    -  Direction. 
                                      0 is Downstream
                                      1 is Upstream
 
                                      If you use the Direction parameter
                                      this is set for you.

                          Bit 1    -  DSCP/TOS Field
                                      0 is enable
                                      1 is overwrite

        GateTOSField    - IP TOS and Precedence value.

        GateTOSMask     - IP TOS Mask settings

        GateClass       - This field is broken down into 8 bits as follows
                       
                          Bit 0-2   - Priority of 0-7
                          Bit 3     - PreEmption bit
                          Bit 4-7   - Configurable but should default 0

        Gate_T1         - Gate T1 timer

        Gate_T2         - Gate T2 timer

        Gate_T3         - Gate T3 timer

        Gate_T4         - Gate T4 timer

    An example of use would be

    $cops_client->gate_specification_add(
        [
        Direction       => 'Downstream',
        DSCPToSMark     => 0,
        Priority        => 0,
        PreEmption      => 0,
        Gate_Flags      => 0,
        Gate_TOSField   => 0,
        Gate_TOSMask    => 0,
        Gate_Class      => 0,
        Gate_T1         => 0,
        Gate_T2         => 0,
        Gate_T3         => 0,
        Gate_T4         => 0
        ]
        );

=head2 classifier_add

    This function adds a classifier to the COPS request being sent and
    supports normal and extended classifiers.

    The function requires two types of parameters depending on the type
    of classifier specified.

    To specify the correct classifier the attribute Classifier_Type
    can be used as follows

        Classifier_Type   -  This should be 'Classifier' or 'Extended'

    Classifier_Type 'Classifier' attributes are as follows

        Classifier_IPProtocolId      - This is a standard IP protocol
                                       number. You can set this to 0
                                       or omit this and a default of 0
                                       will be used.

        Classifier_TOSField          - The TOSField of the IP packets
                                       to match. You can set this to 0
                                       or omit this and a default of 0
                                       will be used.

        Classifier_TOSMask           - The TOSMask of the IP packets 
                                       to match. you can set this to 0
                                       or omit this and a default of 0
                                       will be used.

        Classifier_SourceIP          - This should be set to the source
                                       IP address of the associated flow.
                                       If you have a device attached to
                                       the cable modem such as a PC, then
                                       you should use the IP of that
                                       device, not that of the cable modem.

        Classifier_DestinationIP     - This is the destination IP of the 
                                       flow. It can be a wildcard of 0.
                                       If you omit this then a default 0
                                       will be used.

        Classifier_SourcePort        - The source port of the flow. If
                                       you omit this then a default of 0
                                       will be used.

        Classifier_DestinationPort   - This is the destination port of the
                                       flow. If you omit this then a default
                                       if 0 will be used.

        Classifier_Priority          - The priority of this Classifier. If
                                       you have multiple Classifiers then
                                       this determines the order they are
                                       checked.

    An example of use would be

    $cops_client->classifier_add(
        [
        Classifier_Type         => 'Classifier',
        Classifier_Priority => 64,
        Classifier_SourceIP => "172.20.1.1",
        ]
        );

    This sets up a Standard classifier with a priority of 64, Source IP of
    172.20.1.1,any port and a wildcard destination address any port.

    Classifier_Type 'Extended' attributes are as follows

        EClassifier_IPProtocolId     - This is a standard IP protocol
                                       number. You can set this to 0
                                       or omit this and a default of 0
                                       will be used.

        EClassifier_TOSField         - The TOSField of the IP packets
                                       to match. You can set this to 0
                                       or omit this and a default of 0
                                       will be used.

        EClassifier_TOSMask          - The TOSMask of the IP packets
                                       to match. you can set this to 0
                                       or omit this and a default of 0
                                       will be used.

        EClassifier_SourceIP         - This should be set to the source
                                       IP address of the associated flow.
                                       If you have a device attached to
                                       the cable modem such as a PC, then
                                       you should use the IP of that
                                       device, not that of the cable modem.
                                       With an extended classifier you can
                                       also specify a network address.

        EClassifier_SourceMask       - This is the associated netmask for
                                       the SourceIP specified.

        EClassifier_DestinationIP    - This is the destination IP of the
                                       flow. It can be a wildcard of 0.
                                       If you omit this then a default 0
                                       will be used.
                                       With an extended classifier you can
                                       also specify a network address.

        EClassifier_DestinationMask  - This is the associated netmask for
                                       the DestinationIP specified.

        EClassifier_SourcePortStart  - The start source port of the flow.
                                       If you omit this then a default of 0
                                       will be used.

        EClassifier_SourcePortEnd    - The end source port of the flow. If
                                       both the start and end ports are 0
                                       then all ports are matched.

        EClassifier_DestinationPortStart - The start destination port of the
                                       flow. If you omit this then a default
                                       of 0 will be used.

        EClassifier_DestinationPortEnd - The end destination port of the flow.
                                       If both the start and end ports are 0
                                       then all ports are matched.

        EClassifier_ClassifierID     - An extended classifier must have numerical
                                       ID and it should unique per classifier per
                                       gate. It can range from 1 to 65535 (16bit)

        EClassifier_Priority         - The priority of this Classifier. If
                                       you have multiple Classifiers then
                                       this determines the order they are
                                       checked.

        EClassifier_State            - This determines if this classifier is
                                       Inactive or Active, values 0 and 1
                                       respectively.

        EClassifier_Action           - This has 4 possible values

                                       0 - Means Add - This is the default if not
                                                       specified.
                                       1 - Replace
                                       2 - Delete
                                       3 - No Change

    An example of use would be

    $cops_client->classifier_add(
        [
        Classifier_Type         => 'Extended',
        EClassifier_Priority => 64,
        EClassifier_SourceIP => "172.20.1.1",
        EClassifier_ClassifierID => 100,
        EClassifier_State => 1
        ]
        );

    This sets up an Extended classifier with a priority of 64, Source IP of
    172.20.1.1,any port and a wildcard destination address any port. The ID is set
    to 100 and it is set to State 1 which is Active.

=head2 envelope_add

    This function adds the correct envelope type to the gate. All the possible parameters
    can not be detailed here as it would this man page *VERY* long. I may add them in the
    future.

    The Attributes that are *ALWAYS* required at

        Envelope_Type                - This specifies the type of request and is managed
                                       by three bits (LSB first), lowest value 1 highest
                                       value 7

                                       0 - Authorize    - Value 1
                                       1 - Reserve      - Value 2
                                       2 - Commit       - Value 4

				       This is a string and should be one/more of the following

				       authorize reserve commit

        Service_Type                 - This determines the type of service that the gate
                                       will apply. By specifying the Service_Type and
                                       Envelope_Type this determines the additional
                                       parameters required.

                                       The following values are valid for Service_Type

                                       Flow Spec
                                       DOCSIS Service Class Name
                                       Best Effort Service
                                       Non-Real-Time Polling Service
                                       Real-Time Polling Service
                                       Unsolicited Grant Service
                                       Unsolicited Grant Service with Activity Detection
                                       Downstream

                                       There is an example of each one in the examples
                                       directory examples/profiles/
    
    An example of use would be

    $cops_client->envelope_add (
        [
        Envelope_Type           => "authorize reserve commit",
        Service_Type            => 'DOCSIS Service Class Name',
        ServiceClassName 	=> 'S_down'
        ]
        );

    This sets up the Envelope to be authorized, reserved and committed. It contains a Service
    Class Name (this should be configured on the CMTS already) and it has been named as
    S_down. If the specified ServiceClassName is incorrect or does not correspond to the
    direction specified an error will be returned.

=head2 rks_set

    This function add a Reporting server to the COPS request. You can have a primary and
    secondary Reporting server and events, such as volume quota reached, time reached should
    be report to the Reporting server configured. All Reporting server messages are via 
    the RADIUS protocol. This rks_set only supports IPV4 addressing.

    As part of a RKS request you can also specify unique indentifiers that will be sent in
    the Reporting request for each specific gate created. The Gate ID is not sent in the 
    reporting request so some external management system will need to track these.

    The variables you can set in an RKS configuration are as follows

    PRKS_IPAddress                 - This is the PRIMARY (PRKS) reporting server IP address.
                                     It should be specified as an IP, hostnames are not
                                     supported and only IPV4 is available.

    PRKS_Port                      - This is the Port that reporting messages are sent to.
                                     The protocol used is RADIUS so the standard 1813 port
                                     should be used if a default RADIUS server configuration
                                     is to be used.

    PRKS_Flags                     - Ignore, further work is required, however if you
                                     understand this usage it is available to be set.

    SRKS_IPAddress                 - This is the SECONDARY (SRKS) reporting server IP address.
                                     This is ONLY used if the primary is considered down.
                                     It should be specified as an IP, hostnames are not
                                     supported and only IPV4 is available.

    SRKS_Port                      - This is the Port that reporting messages are sent to
                                     for the SECONDARY reporting server.

    SRKS_Flags                     - Ignore, further work is required, however if you
                                     understand this usage it is available to be set.

    
    Billing Correlation Identification

    BCID_TimeStamp                 - This is a 32bit number and EPOCH is a good use here.
                                  
    BCID_ElementID                 - This is an eight (8) character entry and should be
                                     alphanumeric only to be supported by all vendors.

    BCID_TimeZone                  - This is an eight(8) character entry and specifies
                                     the timezone of the entry. 

    BCID_EventCounter              - This is a 32bit number and can be anything within that
                                     range. This could be an auto-increment in a table, so
                                     allowing GateID to be linked back later.

    An example of use would be

        my $timer=time();

        $cops_client->rks_set (
                        [
                        PRKS_IPAddress          => '192.168.50.2',
                        PRKS_Port               => 2000,
                        PRKS_Flags              => 0,
                        SRKS_IPAddress          => 0,
                        SRKS_Port               => 0,
                        SRKS_Flags              => 0,
                        BCID_TimeStamp          => $timer,
                        BCID_ElementID          => '99999999',
                        BCID_TimeZone           => '00000000',
                        BCID_EventCounter       => 12347890
                        ]
                        );

    You can omit fields which are not used and they will default to 0, but for completeness
    are included above.
 
=head2 decode_radius_attribute

    This function takes the output from FreeRadius 2.1.9 and expands it where possible. The
    supported attributes are

         CableLabs-Event-Message
         CableLabs-QoS-Descriptor

    When called this function returns the converted attribute into a hash of the attributes
    found and decoded.

    An example of use would be

    my %return_data;

    $cops_client->decode_radius_attribute("CableLabs-Event-Message",
        "
        0x00034c163b873939393939393939303030303030303000bc69f2000700022020203232323200312b3030303030300000002b32303130303631343135313233382e3032330000000080000400",
        \%return_data);

    Note the 0x is required at the beginning so validity checking will pass.

    The %return_data has should then contain the following keys with values.

        EventMessageVersionID        -  3
        TimeZone                     -  1+000000
        Status                       -  0
        AttributeCount               -  4
        SequenceNumber               -  43
        BCID_TimeZone                -  00000000
        EventObject                  -  0
        ElementType                  -  2
        EventMessageType             -  7
        BCID_Timestamp               -  1276525447
        BCID_ElementID               -  99999999
        BCID_EventCounter            -  12347890
        EventMessageTypeName         -  QoS_Reserve
        Priority                     -  128
        ElementID                    -  '   2222'
        EventTime                    -  20121019163303.51

=head2 volume_set

    This functions adds a volume limit to the gate being sent. You should be aware the CMTS
    may not stop traffic flowing through the gate when the limit is reached, implementation
    dependent, however should send a RKS notification.

    This function just takes the Volume in the number of bytes, 64 bit number.

    An example of use would be

    $cops_client->volume_set( 3000000000 );
   
    This would set the volume to 3Gigabytes.

=head2 timebase_set

    This function add a time limit to the gate being sent. You should be aware the CMTS may
    not stop traffifc flowing through the gate when the limit is reached, implementation
    dependent, however should sent a RKS notification.

    This function just takes the time in seconds , 32bit number.
        
    An example of use would be

    $cops_client->timebase_set( 60 );

    This would set the time limit to 60 seconds.

=head2 opaque_set

    This function allows you to add arbitary data to the COPS message sent which *may* be
    recorded against the gate by the remote CMTS.

    The only attribute for this function is

        OpaqueData                   - This be any data, although keeping it to something
                                       humanly readable is probably a good idea.

    An example of use would be

    $cops_client->opaque_set(
        [
        OpaqueData => 'a test string'
        ]
        );

    This would add 'a test string' as Opaque data to the gate.

=head2 Summary

    This is very much a 'work in progress'. 

=cut

sub new {

        my $self = {};
        bless $self;

        my ( $class , $attr ) =@_;

        my ( %template );
        my ( %current_data );
        my ( %complete_decoded_data );
        my ( %handles );

        $self->{_GLOBAL}{'DEBUG'}=0;

        while (my($field, $val) = splice(@{$attr}, 0, 2))
                { $self->{_GLOBAL}{$field}=$val; }

        $self->{_GLOBAL}{'STATUS'}="OK";

        if ( !$self->{_GLOBAL}{'VendorID'} )
                { $self->{_GLOBAL}{'VendorID'}="Generic Client"; }

        if ( !$self->{_GLOBAL}{'ServerIP'} )
                { die "ServerIP Required"; }

        if ( !$self->{_GLOBAL}{'ServerPort'} )
                { die "ServerPort Required"; }

        if ( !$self->{_GLOBAL}{'KeepAlive'} )
                { $self->{_GLOBAL}{'KeepAlive'}=60; }

        if ( !$self->{_GLOBAL}{'Timeout'} )
                { $self->{_GLOBAL}{'Timeout'}=5; }

        if ( !$self->{_GLOBAL}{'ListenIP'} )
                { $self->{_GLOBAL}{'ListenIP'}=""; }

        if ( !$self->{_GLOBAL}{'ListenPort'} )
                { $self->{_GLOBAL}{'ListenPort'}=""; }

        if ( !$self->{_GLOBAL}{'ListenServer'} )
                { $self->{_GLOBAL}{'ListenServer'}=0; }

        if ( !$self->{_GLOBAL}{'RemotePassword'} )
                { $self->{_GLOBAL}{'RemotePassword'}=""; }

        if ( !$self->{_GLOBAL}{'RemoteSpeed'} )
                { $self->{_GLOBAL}{'RemoteSpeed'}=10; }

        if ( !$self->{_GLOBAL}{'TMPDirectory'} )
                { $self->{_GLOBAL}{'TMPDirectory'}="/tmp/"; }

        $self->{_GLOBAL}{'data_ack'}=0;
        $self->{_GLOBAL}{'TRANSACTION_COUNT'}=1;
        $self->{_GLOBAL}{'ERROR'}="" ;
        $self->{_GLOBAL}{'data_processing'}=0;
        $self->{_GLOBAL}{'current_command'}="";
	$self->{_GLOBAL}{'Classifier_Encoded'}="";
	$self->{_GLOBAL}{'Envelope_Encoded'}="";
	$self->{_GLOBAL}{'TimeLimit'}="";
	$self->{_GLOBAL}{'VolumeLimit'}="";
	$self->{_GLOBAL}{'OpaqueData'}="";
	$self->{_GLOBAL}{'RKS_Encoded'}="";

        $self->{_GLOBAL}{'template'}= \%template;
        $self->{_GLOBAL}{'current_data'}= \%current_data;
        $self->{_GLOBAL}{'complete_decoded_data'} = \%complete_decoded_data;

	$self->{_GLOBAL}{'Listener_HandlesP'}= \%handles;

        return $self;
}

sub disconnect
{
my ( $self ) = shift;
if ( $self->{_GLOBAL}{'Handle'} )
	{
	$self->{_GLOBAL}{'Handle'}->close();
	}
return 1;
}

sub connect
{
my ( $self ) = shift;

my $lsn = IO::Socket::INET->new
                        (
                        PeerAddr => $self->{_GLOBAL}{'ServerIP'},
                        PeerPort => $self->{_GLOBAL}{'ServerPort'},
                        ReuseAddr => 1,
                        Proto     => 'tcp',
                        Timeout    => $self->{_GLOBAL}{'Timeout'}
                        );

if (!$lsn)
        {
        $self->{_GLOBAL}{'STATUS'}="Failed to bind to address '".$self->{_GLOBAL}{'ServerIP'}."' ";;
        $self->{_GLOBAL}{'STATUS'}.="and port '".$self->{_GLOBAL}{'ServerPort'};
        $self->{_GLOBAL}{'ERROR'}=$!;
        return 0;
        }

$self->{_GLOBAL}{'LocalIP'}=$lsn->sockhost();
$self->{_GLOBAL}{'LocalPort'}=$lsn->sockport();
$self->{_GLOBAL}{'Handle'} = $lsn;
$self->{_GLOBAL}{'Selector'}=new IO::Select( $lsn );
$self->{_GLOBAL}{'STATUS'}="Success Connected";

if ( $self->{_GLOBAL}{'ListenServer'} )
	{
	# we should do a fork here so the listener can wait for commands
	# how we signal when data is ready not sure.
	my $child;
	if ($child=fork)
		{}
		elsif (defined $child)
		{
		my $lsn2 = IO::Socket::INET->new
       	                 (
       	                 Listen    => 1024,
       	                 LocalAddr => $self->{_GLOBAL}{'ListenIP'},
       	                 LocalPort => $self->{_GLOBAL}{'ListenPort'},
       	                 ReuseAddr => 1,
       	                 Proto     => 'tcp',
       	                 Timeout    => $self->{_GLOBAL}{'Timeout'}
       	                 );
		if ( !$lsn2)
			{
			$self->{_GLOBAL}{'STATUS'}="Failed to bind to address '".$self->{_GLOBAL}{'ListenIP'}."' ";
      			$self->{_GLOBAL}{'STATUS'}.="and port '".$self->{_GLOBAL}{'ListenPort'};
			$self->{_GLOBAL}{'ERROR'}=$!;
			exit(0);
			}

		$self->{_GLOBAL}{'Listen_LocalIP'}=$lsn2->sockhost();
		$self->{_GLOBAL}{'Listen_LocalPort'}=$lsn2->sockport();
		$self->{_GLOBAL}{'Listen_Handle'} = $lsn2;
		$self->{_GLOBAL}{'Listen_Selector'}=new IO::Select( $lsn2 );
		$self->{_GLOBAL}{'Listen_STATUS'}="Success Connected";
		$self->check_listeners_available();
		exit(0);
		}
	}

return 1;
}

sub connect_flush
{
my ( $self ) = shift;
undef $self->{_GLOBAL}{'LocalIP'};
undef $self->{_GLOBAL}{'LocalPort'};
undef $self->{_GLOBAL}{'Handle'};
undef $self->{_GLOBAL}{'Selector'};
undef $self->{_GLOBAL}{'STATUS'};
return 1;
}

sub connected
{
my ( $self ) = shift;
return $self->{_GLOBAL}{'Selector'};
}


sub check_data_handles
{
my ( $self ) = shift;
my ( @handle ) = $self->{_GLOBAL}{'Selector'}->can_read;
if ( !@handle ) {  $self->{_GLOBAL}{'ERROR'}="Not Connected"; }
$self->{_GLOBAL}{'ready_handles'}=\@handle;
}

sub get_data_segment
{
my ( $self ) = shift;
my ( $header );
my ( $buffer ) = "";
my ( $dataset ) ;

my $link;
my ( $version, $type, $session, $flags, $length );
my ( $handles ) = $self->{_GLOBAL}{'ready_handles'};

foreach my $handle ( @{$handles} )
        {
        $link = sysread($handle,$buffer,1024);
        if ( !$buffer )
                {
                $handle->close(); return 1;
                }
        print "Read buffer size of '".length($buffer)."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
        $self->{_GLOBAL}{'data_received'} .=$buffer;
	$self->{_GLOBAL}{'last_handle'}=$handle;
        }
$self->{_GLOBAL}{'data_processing'}=1;
}

sub check_listener_handles
{
my ( $self ) = shift;
my ( @handle ) = $self->{_GLOBAL}{'Listen_Selector'}->can_read;
if ( !@handle ) {  $self->{_GLOBAL}{'ERROR'}="Not Connected"; return 0; }
print "Handles available as '".@handle."'\n";
$self->{_GLOBAL}{'Listener_Handles'}=\@handle;
return 1;
}

sub check_listeners_available
{
my ( $self ) = shift;

while ( $self->check_listener_handles )
        {
	print "Checking handles.\n";
	$self->get_listener_connect(); 
	}

$self->{_GLOBAL}{'STATUS'}="Socket Closed";
$self->{_GLOBAL}{'ERROR'}="Socket Closed";
}

sub get_listener_connect
{
my ( $self ) = shift;
my ( $dataset ) = "";
my ( $handles ) = $self->{_GLOBAL}{'Listener_HandlesP'};
my ( $current_handles ) = $self->{_GLOBAL}{'Listener_Handles'};

foreach my $handle ( @{$current_handles} )
        {
        print "Handle is '$handle'\n" if $self->{_GLOBAL}{'DEBUG'}>5;
        if ( $handle==$self->{_GLOBAL}{'Listen_Handle'} )
                {
                my $new = $self->{_GLOBAL}{'Listen_Handle'}->accept;
                $self->{_GLOBAL}{'Listen_Selector'}->add($new);
                }
                else
                {
                my $link = 0;
                $dataset="";
                $link = sysread($handle,$dataset,1024);
                if ( !$link )
                        {
                        my $child;
                        ${$handles}{$handle}{'data'}.=$dataset;
                        if ($child=fork)
                                { } elsif (defined $child)
                                {
                                print "rmote address is '".${$handles}{$handle}{'addr'}."'\n" if $self->{_GLOBAL}{'DEBUG'}>5;
                                print "rmote port is '".${$handles}{$handle}{'port'}."'\n" if $self->{_GLOBAL}{'DEBUG'}>5;
                                if ( !${$handles}{$handle}{'data'} )
                                        {} else {
					my $tmp_filename="COPS_".time().rand(5000);
					print "Writing data to '".$self->{_GLOBAL}{'TMPDirectory'}."/".$tmp_filename."-data'\n";
                                        if ( open (__FILE,">".$self->{_GLOBAL}{'TMPDirectory'}."/".$tmp_filename."-data") )
                                                {
                                                print __FILE ${$handles}{$handle}{'data'};
                                                close __FILE;
                                                }
					if ( open (__FILE,">".$self->{_GLOBAL}{'TMPDirectory'}."/".$tmp_filename."-lock") )
						{
						close (__FILE);
						}
                                	}
                                foreach my $handler ( keys %{$handles} )
                                        { if ( $handler ne $handle ) { delete ${$handles}{$handler}; } }
                                if ( !${$handles}{$handle} ) { waitpid($child,0); exit(0); }
                                waitpid($child,0);
                                exit(0);
                                }
                        if ( ${$handles}{$handle}{'addr'} )
                                {
                                if ( $self->{_GLOBAL}{'complete_decoded_data'}{ ${$handles}{$handle}{'addr'} } )
                                        { undef $self->{_GLOBAL}{'complete_decoded_data'}{ ${$handles}{$handle}{'addr'} }; }
                                }
                        delete ${$handles}{$handle};
                        $self->{_GLOBAL}{'Listen_Selector'}->remove($handle);
                        $handle->close();
                        }

                        if ( $link )
                                {
				print "Got data set as '$dataset'\n";
                                ${$handles}{$handle}{'data'}.=$dataset;
                                ${$handles}{$handle}{'addr'}=$handle->peerhost() if !${$handles}{$handle}{'addr'};
                                ${$handles}{$handle}{'port'}=$handle->peerport() if !${$handles}{$handle}{'port'};
                                }
                }
        }
return 1;
}



sub check_data_available
{
my ( $self ) = shift;

$self->{_GLOBAL}{'data_sync'}=0;

while ( $self->check_data_handles && $self->{_GLOBAL}{'ERROR'}!~/not connected/i )
        {

        $self->get_data_segment();

	while ( $self->{_GLOBAL}{'data_processing'}==1 )
		{

		my $message = $self->{_GLOBAL}{'data_received'};
	
		$self->decode_message_type();

		

	        if ( length($message)==0 || $self->{_GLOBAL}{'message_opcode'}=~/^null$/i )
                {
                $self->{_GLOBAL}{'data_processing'}=0;
                }

		if ( $self->{_GLOBAL}{'DEBUG'}>0 )
			{
			if ( $self->{_GLOBAL}{'message_client_id'} )
				{
				print "Client is is '".$self->{_GLOBAL}{'message_client_id'}."'\n\n\n\n";
				}

			for($a=0;$a<length($message);$a++)
				{
				printf("%02x-", ord(substr($message,$a,1)));
				}
	        	print "\n";
			}

		if ( $self->{_GLOBAL}{'message_opcode'}=~/^opn$/i )
			{
			print "OPN Message received, sending CAT message.\n" if $self->{_GLOBAL}{'DEBUG'}>0;
			my ( $response ) = $self->encode_cops_object(10,1,
				pack("N",30) );
			$response.=$self->encode_cops_object(15,1,
				pack("N",30) );
			my ( $cops_message ) = $self->encode_cops_message(
					1,0,7,$self->{_GLOBAL}{'message_client_id'}, $response);

			$self->{_GLOBAL}{'major_client_id'} = $self->{_GLOBAL}{'message_client_id'};
				
			$self->send_message($cops_message);
			}


		if ( $self->{_GLOBAL}{'message_opcode'}=~/^req$/i )
			{
			print "REQ message received.\n" if $self->{_GLOBAL}{'DEBUG'}>0;

			$self->{_GLOBAL}{'message_client_handle'} = $self->{_GLOBAL}{'message'}{'Handle'}{'Handle'};

			if ( $self->get_command()=~/^set$/ )
				{

				my $subscriber_ip=$self->subscriber_get();

			        my $handle_object = $self->encode_handle_object($self->{_GLOBAL}{'message_client_handle'});
			        my $context_object = $self->encode_context_object( 8, 0 );

				my $temp = pack("nn",1,1);

			        my $decision_object = $self->encode_decision_object ( 1, $temp);

				my $gate_command = $self->encode_sub_transaction_id(4,rand(4095));
				my $amid_command = $self->encode_sub_amid(1,1);
				my $subscriber_command = $self->encode_sub_subscriber_id(
								$self->subscriber_type(),$subscriber_ip);

				
				my $gate_id = "";
				if ( $self->get_gate_id() )
					{
					$gate_id = $self->encode_gate_id ();
					}

				my $total_object;

				$total_object = $self->gate_specification_get();
				$total_object.= $self->envelope_get();
				$total_object.= $self->classifier_get();
				$total_object.= $self->rks_get();

				if ( length($self->volume_get())>0 )
					{
					if ( $self->{_GLOBAL}{'DEBUG'}> 5 )
						{
						print "Volume set adding in object.\n";
						print "Object size before is '".length($total_object)."'\n";
						}
					$total_object.= $self->volume_get();
					if ( $self->{_GLOBAL}{'DEBUG'}> 5 )
						{
						print "Object size after is '".length($total_object)."'\n";
						}
					}

				if ( length($self->timebase_get())>0 )
					{
					if ( $self->{_GLOBAL}{'DEBUG'}> 5 )
						{
						print "Timebase set adding in object.\n";
						print "Object size before is '".length($total_object)."'\n";
						}
					$total_object.= $self->timebase_get();
					if ( $self->{_GLOBAL}{'DEBUG'}> 5 )
						{
						print "Object size after is '".length($total_object)."'\n";
						}
					}

                                if ( $self->opaque_get() )
                                        {
                                        $total_object.= $self->opaque_get();
                                        }

				my $decision2_object = $self->encode_decision_object 
					( 
					4, 
					$gate_command.
					$amid_command.
					$subscriber_command.
					$gate_id.
					$total_object
					);

			        my $data_block = $handle_object.$context_object.$decision_object.$decision2_object;

			        my ( $cops_message ) = $self->encode_cops_message(
		                        1,0,2, 32778, $data_block);
				$self->send_message($cops_message);
				}
			if ( $self->get_command()=~/^info$/ )
				{
				my $subscriber_ip=$self->subscriber_get();
                                my $handle_object = $self->encode_handle_object($self->{_GLOBAL}{'message_client_handle'});
                                my $context_object = $self->encode_context_object( 8, 0 );

                                my $temp = pack("nn",1,1);

                                my $decision_object = $self->encode_decision_object ( 1, $temp);

                                my $gate_command = $self->encode_sub_transaction_id(7,rand(4095));
                                my $amid_command = $self->encode_sub_amid(1,1);
                                my $subscriber_command = $self->encode_sub_subscriber_id(
								$self->subscriber_type(),$subscriber_ip);

				my $gate_id = $self->encode_gate_id ();

				my $decision2_object = $self->encode_decision_object
					(
					4,
					$gate_command.
					$amid_command.
					$subscriber_command.
					$gate_id
					);
				my $data_block = $handle_object.$context_object.$decision_object.$decision2_object;
				my ( $cops_message ) = $self->encode_cops_message(
					1,0,2, 32778, $data_block);
				$self->send_message($cops_message);
				}
			if ( $self->get_command()=~/^delete$/ )
				{
				my $subscriber_ip=$self->subscriber_get();
				my $handle_object = $self->encode_handle_object($self->{_GLOBAL}{'message_client_handle'});
				my $context_object = $self->encode_context_object( 8, 0 );
				my $temp = pack("nn",1,1);
				my $decision_object = $self->encode_decision_object ( 1, $temp);
				my $gate_command = $self->encode_sub_transaction_id(10,rand(4095));
				my $amid_command = $self->encode_sub_amid(1,1);
				my $subscriber_command = $self->encode_sub_subscriber_id(
						$self->subscriber_type(),$subscriber_ip);
				my $gate_id = $self->encode_gate_id ();
				my $decision2_object = $self->encode_decision_object
					(
					4,
					$gate_command.
					$amid_command.
					$subscriber_command.
					$gate_id
					);
				my $data_block = $handle_object.$context_object.$decision_object.$decision2_object;
				my ( $cops_message ) = $self->encode_cops_message(
					1,0,2, 32778, $data_block);
				$self->send_message($cops_message);
				}

			if ( $self->get_command()=~/^synch$/i )
				{
				print "Enter SYNC HERE!!!!!!\n" if $self->{_GLOBAL}{'DEBUG'}>0;
				my $subscriber_ip=$self->subscriber_get();
				my $handle_object = $self->encode_handle_object($self->{_GLOBAL}{'message_client_handle'});
				my $context_object = $self->encode_context_object( 8, 0 );
				my $temp = pack("nn",1,1);
				my $decision_object = $self->encode_decision_object ( 1, $temp);
				my $gate_command = $self->encode_sub_transaction_id(20,rand(4095));
				my $amid_command = $self->encode_sub_amid(1,1);
				my $synch_id = $self->encode_synch_id();
				my $subscriber_command = $self->encode_sub_subscriber_id(
							$self->subscriber_type(),$subscriber_ip);
				my $decision2_object = $self->encode_decision_object
					(
					4,
					$gate_command.
					$amid_command.
					$synch_id
					);
				my $data_block = $handle_object.$context_object.$decision2_object;
				my ( $cops_message ) = $self->encode_cops_message(
					1,0,5, 32778, $data_block);
				$self->{_GLOBAL}{'wait_for_SSC'}=1;
				$self->send_message($cops_message);
				}
			}
		if ( $self->{_GLOBAL}{'message_opcode'}=~/^rpt$/i )
			{
			my %returned_data;

			my $classifier_count = 0;

			my $data_block =  $self->{_GLOBAL}{'message'}{'Client Specific Info'}{'Handle'};

			while ( length($data_block)> 0 )
				{
				my ( $sub_length,$major, $minor) = unpack("nCC",$data_block);
				my $data_part  = substr($data_block,4,$sub_length-4);

				my $type = $self->object_type_decode($major,$minor);

				print "Sub batch data block length '".$sub_length."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
				print "Major is '$major' minor is '$minor' type is '$type'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

				if ( $type=~/^transaction identifier$/i )
					{
					my ( $mtid, $gate_command ) = $self->decode_transaction_identifier( $data_part );
					my ( $gate_transform ) = $self-> decode_gate_actions( $gate_command );
					print "Transaction ID is '$mtid' gate command '$gate_command' was '$gate_transform'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
					$returned_data{'MM_GateCommandType'} = $gate_transform;
					$returned_data{'MM_TransactionId'} = $mtid;
					}
				if ( $type=~/^Gate Identifier$/i )
					{
					my ( $gate_id ) = $self->decode_gate_id ($data_part);
					$returned_data{'GateId_GateIdentifier'} = $gate_id;
					print "Gate ID is '$gate_id'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
					}

				if ( $type=~/^Application Manager Identifier$/i )
					{
					my ( $amidat, $amidam ) = $self->decode_application_manager_identifier( $data_part );
					$returned_data{'AMID_ApplicationManagerIDApplicationType'}=$amidat;
					$returned_data{'AMID_ApplicationManagerIDApplicationManagerTag'}=$amidam;
					}

				if ( $type=~/^Classifier$/i )
					{
					print "\n\n\nEntering Classifier Decode\n\n\n\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
					my $classifier_array = $self->classifier_arrays(1);
					my $unpacker="";
					foreach my $class_entry ( @{${$classifier_array}} )
						{
						my $type_c = $self->attribute_pack($class_entry);
						$unpacker.=$type_c;
						}
					my @temp=unpack($unpacker,$data_part);
					my $class_prefix=$type."_".$classifier_count."_";
					my $attribute_count =0;
					foreach my $class_entry ( @{${$classifier_array}} )
						{
						my $class_name = $class_prefix.$class_entry;
						if ( $class_entry=~/IP$/ )
							{ $temp[$attribute_count]=$self->_IpIntToQuad($temp[$attribute_count]); }
						$returned_data{$class_name}=$temp[$attribute_count];
						$attribute_count++;
						}
					$class_prefix=$type."_Count";
					$returned_data{$class_prefix}++;
					$classifier_count++;
					}

				if ( $type=~/^Gate Specification$/ )
					{
					print "\n\n\nEntering Gate Specification Decode\n\n\n\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
					my $gate_array = $self->gate_array();
					my $unpacker="";
					my $attribute_count =0;
					foreach my $gate_entry ( @{${$gate_array}} )
						{
						my $type_g = $self->attribute_pack($gate_entry);
						$unpacker.=$type_g;
						}
					my @temp=unpack($unpacker,$data_part);
					my $gate_prefix = $type."_"; $gate_prefix=~s/ //g;
					foreach my $gate_entry ( @{${$gate_array}} )
						{
						my $gate_name = $gate_prefix.$gate_entry;
						$returned_data{$gate_name}=$temp[$attribute_count];
						$attribute_count++;
						}
					}

				if ( $type=~/^Event-Generation-Info$/i )
					{
					print "\n\nEntering Event Generation Info Decode\n\n\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
					my $event_array = $self->rks_array();
					my $unpacker="";
					my $attribute_count =0;
					foreach my $event_entry ( @{${$event_array}} )
						{
						my $event_g = $self->attribute_pack($event_entry);
						if ( $event_g=~/^string/ig )
							{
							my ( $name, $number ) = (split(/-/,$event_g))[0,1];
							$event_g="A[$number]";
							}
						$unpacker.=$event_g;
						}
					my @temp=unpack($unpacker,$data_part);
					foreach my $event_entry ( @{${$event_array}} )
						{
						if ( $event_entry=~/_IP/g )
							{
							$temp[$attribute_count] = $self->_IpIntToQuad($temp[$attribute_count]);
							}
						$returned_data{$event_entry}=$temp[$attribute_count];
						$attribute_count++;
						}
					}

				if ( $type=~/^Time Based Usage Limit$/i )
					{
					my $time = unpack ("N",$data_part);
					$returned_data{'TimeBasedUsageLimit'}=$time;
					print "Time found set is '$time'\n";
					}

				if ( $type=~/^Gate Time Info$/i )
					{
					my $time = unpack("N",$data_part);
					$returned_data{'GateTimeInfo'} = $time;
					}

				if ( $type=~/^Gate Usage Info$/i )
					{
					if ( $self->{_GLOBAL}{'DEBUG'}>0 )
						{
						print "Length of decode is '".length($data_part)."'\n";
						for($a=0;$a<length($data_part);$a++)
							{
							printf("%02x-", ord(substr($data_part,$a,2)));
							}
						print "\n";
						}

					my $data_transfer = $self->decode_64bit_number($data_part);
					$returned_data{'GateUsageInfo'}=$data_transfer;
					}

				if ( $type=~/^Gate State$/i )
					{
					my ( $state, $reason ) = unpack("nn",$data_part);
					$returned_data{'GateState_State_Number'} = $state;
					$returned_data{'GateState_Reason_Number'} = $reason;
					$returned_data{'GateState_State_Description'} = $self->gate_states($state);
					$returned_data{'GateState_Reason_Description'} = $self->gate_reasons($reason);
					}

				if ( $type=~/^Packet Cable Error$/i )
					{
					my ( $error, $sub_error ) = unpack("nn",$data_part);
					$returned_data{'PacketCableError_Main_Number'}= $error;
					$returned_data{'PacketCableError_Main_Description'}= $self->packetcable_errors($error);
					$returned_data{'PacketCableError_Sub_Number'}= $sub_error;
					foreach my $env_codes ( grep { /^current_Envelope/ } keys %{$self->{_GLOBAL}} )
						{
						my $temp = $env_codes;
						$temp=~s/current_Envelope_/Error_/g;
						$returned_data{$temp}= $self->{_GLOBAL}{$env_codes};
						}
						
					}


				$data_block = substr($data_block,$sub_length,length($data_block)-$sub_length);
				}
	                $self->{_GLOBAL}{'DataHandler'}->(
        	                $self,
        	                \%returned_data
        	                );


			if ( !$self->{_GLOBAL}{'wait_for_SSC'} )
				{ 
				if ( $self->{_GLOBAL}{'ListenServer'}==0 )
					{
					return 1; 
					}
				}
			}

		if ( $self->{_GLOBAL}{'message_opcode'}=~/^ssc$/i ) 
			{
			$self->{_GLOBAL}{'wait_for_SSC'}=0;
			if ( $self->{_GLOBAL}{'ListenServer'}==0 )
				{
				return 1;
				}
			}

		if ( $self->{_GLOBAL}{'message_opcode'}=~/^ka$/i )
                        {
                                print "KA Message received, sending KA message.\n" if $self->{_GLOBAL}{'DEBUG'}>0;
                                my ( $cops_message ) = $self->encode_cops_message_no_payload(
                                        1,0,9,$self->{_GLOBAL}{'message_client_id'} );
                                $self->send_message($cops_message);
                        }
	}

        }

return 1;
}

sub encode_handle_object
{
my ( $self ) = shift;
my ( $data ) = shift;

my $handle_object = $self->encode_cops_object( 1,1,$data );

return $handle_object;
}

sub encode_context_object
{
my ( $self ) = shift;
my ( $rtype ) = shift;
my ( $mtype ) = shift;

my ( $enc_rtype ) = pack("n",$rtype);
my ( $enc_mtype ) = pack("n",$mtype);

my $context_object = $self->encode_cops_object( 2,1, $enc_rtype.$enc_mtype);

return $context_object;
}

sub encode_decision_object
{
my ( $self ) = shift;
my ( $sub_command ) = shift;
my ( $data ) = shift;

my ( $pad ) = 0;

my ($stub_pri, $sub_sec) = (split(/\./,sprintf("%f",length($data)/4)))[0,1];
if ( $stub_pri ==0 && $sub_sec>0 )
	{
	$pad = 4 - length($data);
	}

if ( $stub_pri > 0 && $sub_sec<1 )
	{
	my $temp = $stub_pri*4;
	$pad = $temp - length($data);
	}

for ( $a=0; $a<$pad; $a++)
	{
	$data.=pack("C",0);
	}

print "Length of data is '".length($data)."'\n\n\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;

my $decision_object = $self->encode_cops_object( 6, $sub_command , $data);

return $decision_object;
}

sub encode_sub_classifier
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $packed ) = "";

my ( $classifier_array );

if ( ${$data}{'Classifier_Type'}=~/^classifier$/i )
	{ 
	$packed .= pack("CC",6,1);
	$classifier_array = $self->classifier_arrays(1); 
	}

if ( ${$data}{'Classifier_Type'}=~/^extended$/i )
	{
	$packed .= pack("CC",6,2);
	$classifier_array = $self->classifier_arrays(2); 
	}

$packed.=$self->general_pack( $data, $classifier_array );

if ( $self->{_GLOBAL}{'DEBUG'}>4 )
        {
        print "Classifier ENCODER \n\n\n\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
        for($a=0;$a<length($packed);$a++)
                {
                printf("%02x-", ord(substr($packed,$a,2)));
                }
        print "\n";
        }


my ( $length ) = pack("n",(length($packed)+2));

return $length.$packed;
}

sub align_string
{
my ( $self ) = shift;
my ( $string ) = shift;

$string.=pack("C",0);

my $align = length($string) % 4;
$align = 4 - $align;
if ( $align > 0 && $align <4 )
        {
        print "Align is '$align'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
        for ( my $tmp=0; $tmp<$align; $tmp ++ )
                {
                print "Adding '$tmp'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
                $string.=pack("C",0);
                }
        print "Finished alignment\n\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
        }
print "Length of output is '".length($string)."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
my ( $length ) = pack("n",(length($string)+2));
return $string;
}

sub encode_synch_id
{
my ( $self ) = shift;
my ( $packed ) = "";
$packed = pack("CC",18,1);
$packed.= pack("CCCC",1,0,1,0);
my ( $length ) = pack("n",(length($packed)+2));
return $length.$packed;
}

sub encode_gate_id
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $packed ) = "";
$packed = pack("CC",4,1);
$packed .= pack("N", $self->get_gate_id() );
my ( $length ) = pack("n",(length($packed)+2));
return $length.$packed;
}

sub encode_time_limit
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $packed ) = "";
if ( $self->{_GLOBAL}{'DEBUG'}> 4 )
        {
	print "Encoder time set to '".$data."'\n";
	}

$packed = pack("CC",10,1);
$packed .= pack("N",$data);
if ( $self->{_GLOBAL}{'DEBUG'}> 4 )
	{
	print "Encoder Time packing \n";
	for($a=0;$a<length($packed);$a++)
		{
		printf("%02x-", ord(substr($packed,$a,2)));
		}
	print "\n";
	}

my ( $length ) = pack("n",(length($packed)+2));
return $length.$packed;
}

sub encode_byte_limit
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $packed ) = "";
$packed = pack("CC",9,1);
if ( !$data )
	{ $data=0; }
$packed .= $self->encode_64bit_number($data);
my ( $length ) = pack("n",(length($packed)+2));
return $length.$packed;
}

sub encode_sub_traffic
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $packed ) = "";

my $type = $self->envelope_type ( ${$data}{'Service_Type'} );
my @parts = (split(/,/,$type))[0,1,2];
$packed = pack("CC", $parts[1], $parts[2]);
${$data}{'Type'} = $self->Envelope_Type_remap(${$data}{'Envelope_Type'});
${$data}{'Envelope'} = ${$data}{'Type'};
my $envelope_header = $self->envelope_header( $parts[2] );
$packed.=$self->general_pack( $data, $envelope_header );

my $auth = ${$data}{'Type'} & 0x01;
my $reserved = ${$data}{'Type'} & 0x02;
my $commit = ${$data}{'Type'} & 0x04;

# For you code part I think for the DOCSIS Service Class Name, if stype is 2 [snum/stype/len 7/2/16],
# you need to ignore auth, reserve and commit
# In this context $parts[1] = snum $parts[2] = stype
# we set auth, reserved and commit to 0 as we dont need them
if ( $parts[2]==2 )
	{
	$auth=0; $reserved=0; $commit=0;
	}

print "Auth is '$auth'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
print "Reserved is '$reserved'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
print "Commit is '$commit'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

if ( $auth > 0 )
	{ 
	print "\n\nENTERING AUTH PHASE\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	$packed.=$self->encode_envelope( $parts[2], "Envelope_authorize_", $data ); }
if ( $reserved > 0 )
	{ 
	print "\n\nENTERING RESERVED PHASE\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	$packed.=$self->encode_envelope( $parts[2], "Envelope_reserve_", $data ); }
if ( $commit > 0 )
	{ 
	print "\n\nENTERING COMMIT PHASE\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	$packed.=$self->encode_envelope( $parts[2], "Envelope_commit_", $data ); }

if ( $self->{_GLOBAL}{'DEBUG'}>4 )
        {
	print "Envelope ENCODER \n\n\n\n\n";
        for($a=0;$a<length($packed);$a++)
                {
                printf("%02x-", ord(substr($packed,$a,2)));
                }
        print "\n";
        }

if ( $self->{_GLOBAL}{'DEBUG'}>4 )
	{
	print "Length of complete envelope is '".length($packed)."'\n";
	}

my ( $length ) = pack("n",(length($packed)+2));

if ( $self->{_GLOBAL}{'DEBUG'}>4 )
	{
	print "Header attached to envelope is '".length($length)."'\n";
	}

return $length.$packed;
}

sub encode_envelope
{
my ( $self ) = shift;
my ( $number ) = shift;
my ( $type ) = shift;
my ( $data ) = shift;
my ( $result ) = "";
if ( $self->{_GLOBAL}{'DEBUG'}>4 )
	{
	print "Envelope encoding information Number '$number' type '$type'\n";
	}
my $envelope_main = $self->envelope_array( $number );
$result.=$self->general_pack( $data, $envelope_main, $type );
return $result;
}

sub encode_sub_amid
{
my ( $self ) = shift;
my ( $app_type ) = shift;
my ( $man_tag ) = shift;
my ( $packed ) = pack("CCnn", 2,1,$app_type, $man_tag);
my ( $length ) = pack("n",(length($packed)+2));
return $length.$packed;
}

sub encode_sub_subscriber_id
{
my ( $self ) = shift;
my ( $type ) = shift;
my ( $ip ) = shift;

my ( $convert_ip ) = $self->_IpQuadToInt($ip);
my ( $packed ) = pack("CCN", 3,$type,$convert_ip);
my ( $length ) = pack("n",(length($packed)+2));
return $length.$packed;
}

sub encode_sub_transaction_id
{
my ( $self ) = shift;
my ( $gate_command ) = shift;
my ( $trans_id ) = shift;
my ( $packed ) = pack("CCnn", 1,1,$trans_id,$gate_command);
my ( $length ) = pack("n",(length($packed)+2));
return $length.$packed;
}

sub encode_sub_decision
{
my ( $self ) = shift;
my ( $snum ) = shift;
my ( $stype ) = shift;
my ( $data ) = shift;

my ( $pad ) = 0;

my ($stub_pri, $sub_sec) = (split(/\./,sprintf("%f",length($data)/4)))[0,1];
if ( $stub_pri ==0 && $sub_sec>0 )
        {
        $pad = 4 - length($data);
        }

if ( $stub_pri > 0 && $sub_sec<1 )
        {
        my $temp = $stub_pri*4;
        $pad = $temp - length($data);
        }

for ( $a=0; $a<$pad; $a++)
        {
        $data.=pack("C",0);
        }

my ( $length ) = length ($data)+2;

my $sub_decision = pack("nCCN",$length, $snum, $stype, $data);

return $sub_decision;
}

sub send_message
{
my ( $self ) = shift;
my ( $message ) = shift;
if ( !$self->{_GLOBAL}{'Handle'} ) { return 0; }
my ( $length_sent );
eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 1;
        $length_sent = syswrite ( $self->{_GLOBAL}{'Handle'}, $message );
        alarm 0;
        };

print "length sent is '$length_sent'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

if ( $@=~/alarm/i )
        { return 0; }

print "Sending message of size '".length($message)."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

if ( $self->{_GLOBAL}{'DEBUG'}>4 )
        {
        for($a=0;$a<length($message);$a++)
                {
                printf("%02x-", ord(substr($message,$a,2)));
                }
        print "\n";
        }

if ( $length_sent==length($message) )
        { return 1; }
return 0;
}

sub set_gate_id
{
my ( $self ) = shift;
my ( $gate_id ) = shift;
$self->{_GLOBAL}{'current_gate_id'} = $gate_id;
return 1;
}

sub get_gate_id
{
my ( $self ) = shift;
if ( !$self->{_GLOBAL}{'current_gate_id'} )
	{
	return "";
	}
return $self->{_GLOBAL}{'current_gate_id'};
}

sub set_command
{
my ( $self ) = shift;
my ( $command ) = shift;
$self->{_GLOBAL}{'current_command'} = $command;
return 1;
}

sub get_command
{
my ( $self ) = shift;
return $self->{_GLOBAL}{'current_command'};
}

sub clear_command
{
my ( $self ) = shift;
$self->{_GLOBAL}{'current_command'}="";
return 1;
}

sub envelope_add
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( %test ) ;
while (my($field, $val) = splice(@{$data}, 0, 2))
	{
	my $temp = "current_Envelope_".$field;
	$self->{_GLOBAL}{$temp} = $val;
	$test{$field}= $val;
	 }

my $encode_envelope = $self->encode_sub_traffic(\%test);
$self->{_GLOBAL}{'Envelope_Encoded'} = $encode_envelope;
return 1;
}

sub envelope_get
{
my ( $self ) = shift;
if ( $self->{_GLOBAL}{'Envelope_Encoded'} )
        {
        return $self->{_GLOBAL}{'Envelope_Encoded'};
        }
return "";
}

sub classifier_add
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( %test );
while (my($field, $val) = splice(@{$data}, 0, 2))
                { $test{$field}= $val; }
my $encode_classifier = $self->encode_sub_classifier ( \%test );
$self->{_GLOBAL}{'Classifier_Encoded'} .= $encode_classifier;
return 1;
}

sub classifier_clear
{
my ( $self ) = shift;
$self->{_GLOBAL}{'Classifier_Encoded'} = "";
}

sub classifier_get
{
my ( $self ) = shift;
if ( $self->{_GLOBAL}{'Classifier_Encoded'} )
	{
	return $self->{_GLOBAL}{'Classifier_Encoded'};
	}
return "";
}


sub subscriber_set
{
my ( $self ) = shift;
my ( $subscriber_type ) = shift;
my ( $ip ) = shift;
if ( $subscriber_type=~/^ipv4$/i )
	{
	print "Entry IP is '$ip'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	my ( $test ) = $self->_IpQuadToInt($ip);
	$ip = $self->_IpIntToQuad($test);
	print "Exit IP is '$ip'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	$self->{_GLOBAL}{'cpe_device_type'}=$subscriber_type;
	$self->{_GLOBAL}{'cpe_device_ip'}=$ip;
	}

if ( $subscriber_type=~/^ipv6$/i )
	{
	my @ipv6 = split(/:/,$ip);
	my $test = "";
	if ( scalar(@ipv6)!=8 )
		{
		print "IPv6 entry invalid, full address required.\n" if $self->{_GLOBAL}{'DEBUG'}>0;
		return 1;
		}
	foreach my $ipv6_seg ( @ipv6 )
		{
		my $testa = hex($ipv6_seg);
		$test .= pack("n",$testa);
		}
	$self->{_GLOBAL}{'cpe_device_type'}=$subscriber_type;
	$self->{_GLOBAL}{'cpe_device_ip'}=$test;
	}
return 1;
}

sub subscriber_type
{
my ( $self ) = shift;
if ( !$self->{_GLOBAL}{'cpe_device_type'} )
	{ return 0; }
if ( $self->{_GLOBAL}{'cpe_device_type'}=~/^ipv4$/ )
	{ return 1; }
if ( $self->{_GLOBAL}{'cpe_device_type'}=~/^ipv6$/ )
	{ return 2; }
return 0;
}

sub subscriber_clear
{
my ( $self ) = shift;
$self->{_GLOBAL}{'cpe_device_ip'}="";
$self->{_GLOBAL}{'cpe_device_type'}=0;
return 1;
}

sub subscriber_get
{
my ( $self ) = shift;
if ( !$self->{_GLOBAL}{'cpe_device_ip'} )
	{
	return $self->_IpIntToQuad(0);
	}
return $self->{_GLOBAL}{'cpe_device_ip'};
}

sub get_error
{
my ( $self ) = shift;
return $self->{_GLOBAL}{'ERROR'};
}

sub decode_message_type
{
my ( $self ) = shift;
my ( $decode_data ) = $self->{_GLOBAL}{'data_received'};

$self->{_GLOBAL}{'message_count'}=0;

if ( !$decode_data ) 
	{
	$self->{_GLOBAL}{'message_opcode'} = "NULL"; 
	return 1; }

my ( $vflags, $v2, $client_id, $total_length ) = unpack("CCnN",$decode_data);
my ( $version )  = $vflags;

$version >>= 4; $version = $version & 0x0F; $vflags = $vflags & 0x0F;
my ( $opcode ) = $self->decode_cops_operations( $v2 );

print "Version is '$version' flags is '$vflags'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
print "Opcode is '$opcode'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
print "client id is '$client_id'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

print "New total length is '$total_length'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
print "Length of dd '".length($decode_data)."\n" if $self->{_GLOBAL}{'DEBUG'}>0;

$decode_data = substr ( $decode_data, 8, $total_length-8 );


if ( $self->{_GLOBAL}{'DEBUG'}>0 )
	{
for($a=0;$a<length($decode_data);$a++)
{
printf("%02x-", ord(substr($decode_data,$a,1)));
}
print "\n";
	}


print "Remaing data set length is '".length($decode_data)."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

while ( length($decode_data)> 0 )
	{
	$decode_data = $self-> decode_cops_message ( $decode_data );
	}


print "all cops messages decoded.\n" if $self->{_GLOBAL}{'DEBUG'}>0;

$self->{_GLOBAL}{'message_client_id'} = $client_id;
$self->{_GLOBAL}{'message_opcode'} = $opcode;

$self->{_GLOBAL}{'data_received'} = substr( $self->{_GLOBAL}{'data_received'}, $total_length, length($self->{_GLOBAL}{'data_received'})-$total_length);

return 1;
}

sub decode_cops_message
{
my ( $self ) = shift;
my ( $data ) = shift;

my ( $total_length, $cnum, $ctype ) = unpack("nCC",$data);

print "Cops message length is '$total_length'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

$cnum = $self->decode_c_num_type ( $cnum );
$ctype = $self->decode_c_num_type ( $ctype );

print "Cnum is '$cnum'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
print "CType is '$ctype'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

print "Total length is '$total_length'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

my $message = substr($data,4, $total_length-4 );

print "Pre length data is '".length($message)."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

$self->{_GLOBAL}{'message'}{ $cnum }{$ctype } = $message;

print "Length of message is '".length($self->{_GLOBAL}{'message'}{ $cnum }{$ctype })."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	
$data = substr($data,$total_length, length($data)-$total_length );

return $data;
}


sub decode_cops_operations
{
my ( $self ) = shift;
my ( $opcode ) = shift;

my %opcodes = (
		'1'	=> 'REQ',
		'2'	=> 'DEC',
		'3'	=> 'RPT',
		'4'	=> 'DRQ',
		'5'	=> 'SSQ',
		'6'	=> 'OPN',
		'7'	=> 'CAT',
		'8'	=> 'CC',
		'9'	=> 'KA',
		'10'	=> 'SSC'
		);

return $opcodes{$opcode};
}

sub decode_c_num_type
{
my ( $self ) = shift;
my ( $opcode ) = shift;

my %cnumtypes = (
		'1'	=> 'Handle',
		'2'	=> 'Context',
		'3'	=> 'In Interface',
		'4'	=> 'Out Interface',
		'5'	=> 'Reason Code',
		'6'	=> 'Decision',
		'7'	=> 'LPDP Decision',
		'8'	=> 'Error',
		'9'	=> 'Client Specific Info',
		'10'	=> 'Keep-Alive Timer',
		'11'	=> 'PEP Identification',
		'12'	=> 'Report Type',
		'13'	=> 'PDP Redirect Address',
		'14'	=> 'Last PDP Address',
		'15'	=> 'Accounting Timer',
		'16'	=> 'Message Integrity'
		);

return $cnumtypes{$opcode};
}

sub decode_gate_actions
{
my ( $self ) = shift;
my ( $transcode ) = shift;
my ( %transaction_ids ) = (
		'1'	=> 'GATE-ALLOC',
		'2'	=> 'GATE-ALLOC-ACK',
		'3'	=> 'GATE-ALLOC-ERR',
		'4'	=> 'GATE-SET',
		'5'	=> 'GATE-SET-ACK',
		'6'	=> 'GATE-SET-ERR',
		'7'	=> 'GATE-INFO',
		'8'	=> 'GATE-INFO-ACK',
		'9'	=> 'GATE-INFO-ERR',
		'10'	=> 'GATE-DELETE',
		'11'	=> 'GATE-DELETE-ACK',
		'12'	=> 'GATE-DELETE-ERR',
		'13'	=> 'GATE-OPEN',
		'14'	=> 'GATE-CLOSE'
		);
return $transaction_ids{$transcode} if $transaction_ids{$transcode};
}

sub encode_gate_ids
{
my ( $self ) = shift;
my ( $transcode ) = shift;
my ( %transaction_ids ) = (
                'GATE-ALLOC'	=>	'1',
                'GATE-ALLOC-ACK' =>	'2',
                'GATE-ALLOC-ERR' =>	'3',
                'GATE-SET'	 =>	'4',
                'GATE-SET-ACK'	 =>	'5',
                'GATE-SET-ERR'	 =>	'6',
                'GATE-INFO'	 =>	'7',
                'GATE-INFO-ACK'	 =>	'8',
                'GATE-INFO-ERR'	 =>	'9',
                'GATE-DELETE'	 =>	'10',
                'GATE-DELETE-ACK' =>	'11',
                'GATE-DELETE-ERR' =>	'12',
                'GATE-OPEN'	 =>	'13',
                'GATE-CLOSE'	 =>	'14'
                );
return $transaction_ids{$transcode} if $transaction_ids{$transcode};
}

sub classifier_arrays
{
my ( $self ) = shift;
my ( $type ) = shift;
my ( @classifiers ) =
		(
			[],
			[
			"Classifier_IPProtocolId",
			"Classifier_TOSField",
			"Classifier_TOSMask",
			"Classifier_SourceIP",
			"Classifier_DestinationIP",
			"Classifier_SourcePort",
			"Classifier_DestinationPort",
			"Classifier_Priority",
			"Reserved1Byte",
			"Reserved1Byte",
			"Reserved1Byte"
			],
			[
			"EClassifier_IPProtocolId",
			"EClassifier_TOSField",
			"EClassifier_TOSMask",
			"EClassifier_SourceIP",
			"EClassifier_SourceMask",
			"EClassifier_DestinationIP",
			"EClassifier_DestinationMask",
			"EClassifier_SourcePortStart",
			"EClassifier_SourcePortEnd",
			"EClassifier_DestinationPortStart",
			"EClassifier_DestinationPortEnd",
			"EClassifier_ClassifierID",
			"EClassifier_Priority",
			"EClassifier_State",
			"EClassifier_Action",
			"Reserved1Byte",
			"Reserved1Byte",
			"Reserved1Byte"
			]
		);
return \$classifiers[$type];
}

sub packetcable_errors
{
my ( $self ) = shift;
my ( $error ) = shift;
my ( @errors ) =
		(
		"",
		"Insufficient resources",
		"Unknown Gate ID",
		"Unknown",
		"Unknown",
		"Unknown",
		"Missing Required Object",
		"Invalid Object",
		"Volume based usage limit exceeded",
		"Time based usage limit exceeded", 
		"Session Class Limit Exceeded",
		"Undefined Service Class Name",
		"Incompatible Envelope",
		"Invalid subscriber identifier",
		"Unauthorized AMID",
		"Number of Classifiers not supported",
		"Policy Exception",
		"Invalid field value in object",
		"Transport Error",
		"Unknown gate command",
		"DOCSIS 1.0 CM",
		"Number of SIDs exceeded in CM",
		"Number of SIDs exceeded in CMTS",
		"Unauthorized PSID",
		"No state for PDPD",
		"Unsupport Sync Type",
		"State data incomplete",
		);

if (!$errors[$error])
	{ return "Other, unspecified error"; }
return $errors[$error];
}

sub gate_states
{
my ( $self ) = shift;
my ( $state_no ) = shift;
my ( @states ) =
		(
		"",
		"Idle/Closed",
		"Auhorized",
		"Reserved",
		"Committed",
		"Committed Recovery"
		);
if ( !$states[$state_no] )
	{ return "Unknown"; }
return $states[$state_no];
}

sub gate_reasons
{
my ( $self ) = shift;
my ( $reason ) = shift;
my ( @reasons ) = 
		(
		"",
		"Close Initiated by CMTS because of reservation reassignment",
		"Close Initiated by CMTS because of lack of DOCSIS responses",
		"Close Initiated by CMTS because of timer T1 expiry",
		"Close Initiated by CMTS because of timer T2 expiry",
		"Inactivity timer (T3) expired",
		"Close Initiated by CMTS because of a lack of reservation maintenance",
		"Gate state unchanged, but volume limit reached",
		"Close Initiated by CMTS because of timer T4 expiry",
		"Gate State unchanged, but timer T2 expiry caused reservation reduction",
		"Gate State unchanged, but time limit reached",
		"Close Initiated by PS or CMTS, volume limit reached",
		"Close Initiated by PS or CMTS, time limit reached",
		"Close Initiated by CMTS, other"
		);

if ( !$reasons[$reason] )
	{
	return "Other";
	}
return $reasons[$reason];
}

sub gate_array
{
my ( $self ) = shift;
my ( @gate_headers ) =
		(
		[
		"Gate_Flags",
		"Gate_TOSField",
		"Gate_TOSMask",
		"Gate_Class",
		"Gate_T1",
		"Gate_T2",
		"Gate_T3",
		"Gate_T4"
		]
		);
return \$gate_headers[0];
}

sub rks_array
{
my ( $self ) = shift;
my ( @rks_headers ) = 
		(
		[
		"PRKS_IPAddress",
		"PRKS_Port",
		"Reserved",
		"Reserved",
		"SRKS_IPAddress",
		"SRKS_Port",
		"Reserved",
		"Reserved",
		"BCID_TimeStamp",
		"BCID_ElementID",
		"BCID_TimeZone",
		"BCID_EventCounter"
		]
		);
return \$rks_headers[0];
}

sub rks_set
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( %test );
while (my($field, $val) = splice(@{$data}, 0, 2))
                {
                $test{$field}= $val;
                }
my $rks_encoded = $self->rks_encode(\%test);
$self->{_GLOBAL}{'RKS_Encoded'} = $rks_encoded;
return 1;
}

sub rks_clear
{
my ( $self ) = shift;
$self->{_GLOBAL}{'RKS_Encoded'} = "";
return 1;
}

sub rks_encode
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $packed ) = "";
my ( $done_pack ) =0;

$packed = pack("CC",8,1);
my ( $rks_headers ) = $self->rks_array();
$packed .= $self->general_pack ( $data, $rks_headers );
my ( $length ) = pack("n",(length($packed)+2));
return $length.$packed;
}

sub rks_get
{
my ( $self ) = shift;
if ( $self->{_GLOBAL}{'RKS_Encoded'} )
        {
        return $self->{_GLOBAL}{'RKS_Encoded'};
        }
return "";
}


sub opaque_clear
{
my ( $self ) = shift;
$self->{_GLOBAL}{'OpaqueData'}="";
return 1;
}

sub opaque_set
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( %test );
my ( $encoded ) = "";
while (my($field, $val) = splice(@{$data}, 0, 2))
	{ $test{$field}= $val }
if ( $test{'OpaqueData'} )
	{
	$encoded = pack("CC",11,1);
	$encoded.= $self->align_string( $test{'OpaqueData'} );
	my ( $length ) = pack("n",(length($encoded)+2));
	$encoded= $length.$encoded;
	}
$self->{_GLOBAL}{'OpaqueData'} = $encoded;
return 1;
}

sub timebase_set
{
my ( $self ) = shift;
my ( $data ) = shift;
if ( $self->{_GLOBAL}{'DEBUG'}> 4 )
	{
	print "Time set to '".$data."'\n";
	}
if ( $data > 0 )
	{
	my $timer_encode = $self->encode_time_limit( $data );
	$self->{_GLOBAL}{'TimeLimit'} = $timer_encode;
	}
return 1;
}

sub timebase_clear
{
my ( $self ) = shift;
$self->{_GLOBAL}{'TimeLimit'} = "";
return 1;
}

sub volume_set
{
my ( $self ) = shift;
my ( $data ) = shift;
if ( $data>0 )
	{ 
	my $timer_encode = $self->encode_byte_limit( $data ); 
	$self->{_GLOBAL}{'VolumeLimit'} = $timer_encode;
	}
return 1;
}

sub volume_clear
{
my ( $self ) = shift;
$self->{_GLOBAL}{'VolumeLimit'} = "";
return 1;
}

sub opaque_get
{
my ( $self ) = shift;
if ( $self->{_GLOBAL}{'OpaqueData'} )
	{
	return $self->{_GLOBAL}{'OpaqueData'};
	}
return "";
}

sub volume_get
{
my ( $self ) = shift;
if ( length($self->{_GLOBAL}{'VolumeLimit'})>0 )
	{
	return $self->{_GLOBAL}{'VolumeLimit'};
	}
return "";
}

sub timebase_get
{
my ( $self ) = shift;
if ( length($self->{_GLOBAL}{'TimeLimit'})>0 )
	{
	return $self->{_GLOBAL}{'TimeLimit'};
	}
return "";
}

sub gate_specification_add
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( %test );
while (my($field, $val) = splice(@{$data}, 0, 2))
                { 
		$test{$field}= $val;
		}
my ( $priority ) =0;
my ( $preemption ) =0;
foreach my $field ( keys %test )
		{
		my $val = $test{$field};
		print "Gate key is '$field' value is '$val'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
		if ( $field=~/^direction$/i )
			{
			if (!$test{'Gate_Flags'}) { $test{'Gate_Flags'}=0; }
			$test{'Gate_Flags'}=$test{'Gate_Flags'} & 0xFE;
			if ( $val=~/^downstream$/i )
				{
				$test{'Gate_Flags'}=$test{'Gate_Flags'} & 0xFE;
				}
			if ( $val=~/^upstream$/i )
				{
				$test{'Gate_Flags'}=$test{'Gate_Flags'} & 0xFE;
				$test{'Gate_Flags'}=$test{'Gate_Flags'} + 0x01;
				}
			}

		if ( $field=~/^dscptosmark$/i )
			{
			if ( !$test{'Gate_Flags'} ) { $test{'Gate_Flags'}=0; }
			$test{'Gate_Flags'} = $test{'Gate_Flags'} & 0xFD;
			$val = $val & 0x01; $val = $val << 1; $val = $val & 0x02;
			$test{'Gate_Flags'} = $test{'Gate_Flags'} + $val;
			}

		if ( $field=~/^priority$/i )
			{
			if ( !$test{'Gate_Class'} ) { $test{'Gate_Class'}=0; }
			$val = $val & 0x07;
			$priority = $val;
			}
		if ( $field=~/^preemption$/i )
			{
			if ( $test{'Gate_Class'} ) { $test{'Gate_Class'}=0; }
			$val = $val & 0x01; $val = $val << 3; 
			$val = $val & 0x08;
			$preemption = $val;
			}
		if ( $priority || $preemption )
			{
			$test{'Gate_Class'} = $test{'Gate_Class'} & 0xF0;
			$test{'Gate_Class'} = $test{'Gate_Class'} + $priority;
			$test{'Gate_Class'} = $test{'Gate_Class'} + $preemption;
			}
		}
my $encode_gate_spec = $self->encode_sub_gate_spec ( \%test );
$self->{_GLOBAL}{'Gate_Specification_Encoded'} = $encode_gate_spec;
return 1;
}

sub gate_specification_clear
{
my ( $self ) = shift;
$self->{_GLOBAL}{'Gate_Specification_Encoded'} = "";
}

sub gate_specification_get
{
my ( $self ) = shift;
if ( $self->{_GLOBAL}{'Gate_Specification_Encoded'} )
	{
	return $self->{_GLOBAL}{'Gate_Specification_Encoded'};
	}
return "";
}


sub encode_sub_gate_spec
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $packed ) = "";

$packed = pack("CC",5,1);
my ( $gate_headers ) = $self->gate_array();
$packed.= $self->general_pack( $data, $gate_headers );
my ( $length ) = pack("n",(length($packed)+2));
return $length.$packed;
}

sub envelope_type
{
my ( $self ) = shift;
my ( $part ) = shift;
my ( %types ) =
		(
		"None" => "None,0,0",
		"Flow Spec"=> "Flow Spec,7,1",
		"DOCSIS Service Class Name"=> "DOCSIS Service Class Name,7,2",
		"Best Effort Service" => "Best Effort Service,7,3",
		"Non-Real-Time Polling Service" => "Non-Real-Time Polling Service,7,4",
		"Real-Time Polling Service" => "Real-Time Polling Service,7,5",
		"Unsolicited Grant Service" => "Unsolicited Grant Service,7,6",
		"Unsolicited Grant Service with Activity Detection" => "Unsolicited Grant Service with Activity Detection,7,7",
		"Downstream" => "Downstream,7,8"
		);
return $types{$part};
}

sub envelope_header
{
my ( $self ) = shift;
my ( $part ) = shift;
my ( @headers ) = 
		(
			# There is no 7-0
			[
			],
			# 7-1
			# Flow Spec
			[
				"Envelope",
				"Service Number",
				"Reserved1Byte",
				"Reserved1Byte"
			],
			# 7-2
			# DOCSIS Service Class Name
			[
				"Envelope",
				"Reserved1Byte",
				"Reserved1Byte",
				"Reserved1Byte",
				"ServiceClassName"
			],
			# 7-3
			# Best Effort Service
			[
				"Envelope",
				"Reserved1Byte",
				"Reserved1Byte",
				"Reserved1Byte"
			],
			# 7-4
			# Non-Real_time Polling Service
			[
				"Envelope",
				"Reserved1Byte",
				"Reserved1Byte",
				"Reserved1Byte"
			],
			# 7-5
			# Real_time Polling Service
			[
				"Envelope",
				"Reserved1Byte",
				"Reserved1Byte",
				"Reserved1Byte"
			],
			# 7-6
			# Unsolicited Grant Sevice
			[
				"Envelope",
				"Reserved1Byte",
				"Reserved1Byte",
				"Reserved1Byte"
			],
			# 7-7
			# Unsolicited Grant Service with Activity Detection
			[
				"Envelope",
				"Reserved1Byte",
				"Reserved1Byte",
				"Reserved1Byte"
			],
			# 7-8
			# Downstream Service
			[
				"Envelope",
				"Reserved1Byte",
				"Reserved1Byte",
				"Reserved1Byte"
			]
		);
return \$headers[$part];
}

sub envelope_array
{
my ( $self ) = shift;
my ( $part ) = shift;
my ( @envelopes ) = 
		(
			# There is no 7-0
			[
			],
			# 7-1
			[	
				"Token Bucket Rate",
				"Token Bucket Size",
				"Peak Data Rate",
				"Minimum Policed Unit",
				"Maximum Packet Size",
				"Rate",
				"Slack Term"
			],
			# 7-2
			# A little unsure here.
			[
				"ServiceClassName"
			],
			# 7-3
			[
				"Traffic Priority",
				"Reserved1Byte",
				"Reserved1Byte",
				"Reserved1Byte",
				"Request Transmission Policy",
				"Maximum Sustained Traffic Rate",
				"Maximum Traffic Burst",
				"Minimum Reserved Traffic Rate",
				"Assumed Minimum Reserved Traffic Rate Packet Size",
				"Maximum Concatenated Burst",
				"Required Attribute Mask",
				"Forbidden Attribute Mask",
				"Attribute Aggregation Rule Mask"
			],
			# 7-4
			[
				"Traffic Priority",
				"Reserved1Byte",
				"Reserved1Byte",
				"Reserved1Byte",
				"Request Transmission Policy",
				"Maximum Sustained Traffic Rate",
				"Maximum Traffic Burst",
				"Minimum Reserved Traffic Rate",
				"Assumed Minimum Reserved Traffic Rate Packet Size",
				"Maximum Concatenated Burst",
				"Nominal Polling Interval",
				"Required Attribute Mask",
				"Forbidden Attribute Mask",
				"Attribute Aggregation Rule Mask"
			],
			# 7-5
			[
				"Request Transmission Policy",
				"Maximum Sustained Traffic Rate",
				"Maximum Traffic Burst",
				"Minimum Reserved Traffic Rate",
				"Assumed Minimum Reserved Traffic Rate Packet Size",
				"Maximum Concatenated Burst",
				"Nominal Polling Interval",
				"Tolerated Poll Jitter",
				"Required Attribute Mask",
				"Forbidden Attribute Mask",
				"Attribute Aggregation Rule Mask"
			],
			# 7-6
			[
				"Request Transmission Policy",
				"Unsolicited Grant Size",
				"Grants Per Interval",
				"Reserved1Byte",
				"Nominal Grant Interval",
				"Tolerated Grant Jitter",
				"Required Attribute Mask",
				"Forbidden Attribute Mask",
				"Attribute Aggregation Rule Mask"
			],
			# 7-7
			[
				"Request Transmission Policy",
				"Unsolicited Grant Size",
				"Grants Per Interval",
				"Reserved1Byte",
				"Nominal Grant Interval",
				"Tolerated Grant Jitter",
				"Nominal Polling Interval",
				"Tolerated Poll Jitter",
				"Required Attribute Mask",
				"Forbidden Attribute Mask",
				"Attribute Aggregation Rule Mask"
			],
			# 7-8
			[
				"Traffic Priority",
				"Reserved1Byte",
				"Reserved1Byte",
				"Reserved1Byte",
				"Maximum Sustained Traffic Rate",
				"Maximum Traffic Burst",
				"Minimum Reserved Traffic Rate",
				"Assumed Minimum Reserved Traffic Rate Packet Size",
				"Maximum Downstream Latency",
				"Downstream Peak Traffic Rate",
				"Required Attribute Mask",
				"Forbidden Attribute Mask",
				"Attribute Aggregation Rule Mask"
			]

		);
if ($self->{_GLOBAL}{'DEBUG'}> 4 )
	{
	print "Returning envelope array number '$part'\n";
	}
return \$envelopes[$part];
}

sub attribute_pack
{
my ( $self ) = shift;
my ( $attribute ) = shift;

my ( %attributes ) =
		(
		"Assumed Minimum Reserved Traffic Rate Packet Size" 	=> 'n',
		"Downstream Peak Traffic Rate"				=> 'N',
		"Attribute Aggregation Rule Mask"			=> 'N',
		"Forbidden Attribute Mask"				=> 'N',
		"Grants Per Interval"					=> 'C',
		"Maximum Concatenated Burst"				=> 'n',
		"Maximum Downstream Latency"				=> 'N',
		"Maximum Packet Size"					=> 'N',
		"Maximum Sustained Traffic Rate"			=> 'N',
		"Maximum Traffic Burst"					=> 'N',
		"Minimum Policed Unit"					=> 'N',
		"Minimum Reserved Traffic Rate"				=> 'N',
		"Nominal Grant Interval"				=> 'N',
		"Nominal Polling Interval"				=> 'N',
		"Peak Data Rate"					=> 'N',
		"Rate"							=> 'N',
		"Request Transmission Policy"				=> 'N',
		"Required Attribute Mask"				=> 'N',
		"Reserved1Byte"						=> 'C',
		"Reserved2Bytes"					=> 'n',
		"Reserved3Bytes"					=> 'Cn',
		"Slack Term"						=> 'N',
		"Token Bucket Rate"					=> 'N',
		"Token Bucket Size"					=> 'N',
		"Tolerated Grant Jitter"				=> 'N',
		"Tolerated Poll Jitter"					=> 'N',
		"Traffic Priority"					=> 'C',
		"Unsolicited Grant Size"				=> 'n',
		"Envelope"						=> 'C',
		"Service Number"					=> 'C',
		"String"						=> 'String',
		"ServiceClassName"					=> 'String',
                "Gate_Flags"						=> 'C',
                "Gate_TOSField"						=> 'C',
                "Gate_TOSMask"						=> 'C',
                "Gate_Class"						=> 'C',
                "Gate_T1"						=> 'n',
                "Gate_T2"						=> 'n',
                "Gate_T3"						=> 'n',
                "Gate_T4"						=> 'n',
		"Classifier_IPProtocolId"				=> 'n',
		"Classifier_TOSField"					=> 'C',
		"Classifier_TOSMask"					=> 'C',
		"Classifier_SourceIP"					=> 'N',
		"Classifier_DestinationIP"				=> 'N',
		"Classifier_SourcePort"					=> 'n',
		"Classifier_DestinationPort"				=> 'n',
		"Classifier_Priority"					=> 'C',
		"EClassifier_IPProtocolId"				=> 'n',
		"EClassifier_TOSField"					=> 'C',
		"EClassifier_TOSMask"					=> 'C',
		"EClassifier_SourceIP"					=> 'N',
		"EClassifier_SourceMask"				=> 'N',
		"EClassifier_DestinationIP"				=> 'N',
		"EClassifier_DestinationMask"				=> 'N',
		"EClassifier_SourcePortStart"				=> 'n',
		"EClassifier_SourcePortEnd"				=> 'n',
		"EClassifier_DestinationPortStart"			=> 'n',
		"EClassifier_DestinationPortEnd"			=> 'n',
		"EClassifier_ClassifierID"				=> 'n',
		"EClassifier_Priority"					=> 'C',
		"EClassifier_State"					=> 'C',
		"EClassifier_Action"					=> 'C',
                "PRKS_IPAddress"					=> 'N',
                "PRKS_Port"						=> 'n',
                "PRKS_Flags"						=> 'C',
                "Reserved"						=> 'C',
                "SRKS_IPAddress"					=> 'N',
                "SRKS_Port"						=> 'n',
                "SRKS_Flags"						=> 'C',
                "Reserved"						=> 'C',
                "BCID_TimeStamp"					=> 'N',
                "BCID_ElementID"					=> 'String-8',
                "BCID_TimeZone"						=> 'String-8',
                "BCID_EventCounter"					=> 'N',
		"RADIUS_EventMessageVersionID"				=> 'n',
		"RADIUS_BCID_Timestamp"					=> 'N',
		"RADIUS_BCID_ElementID"					=> 'String-8',
		"RADIUS_BCID_TimeZone"					=> 'String-8',
		"RADIUS_BCID_EventCounter"				=> 'N',
		"RADIUS_EventMessageType"				=> 'n',
		"RADIUS_ElementType"					=> 'n',
		"RADIUS_ElementID"					=> 'String-8',
		"RADIUS_TimeZone"					=> 'String-8',
		"RADIUS_SequenceNumber"					=> 'N',
		"RADIUS_EventTime"					=> 'String-18',
		"RADIUS_Status"						=> 'N',
		"RADIUS_Priority"					=> 'C',
		"RADIUS_AttributeCount"					=> 'n',
		"RADIUS_EventObject"					=> 'C',
		"RADIUS_QosStatus"					=> 'N',
		"RADIUS_ServiceClassName"				=> 'String-16'

		);

return $attributes{$attribute};
}

sub decode_transaction_identifier
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $mmtid, $gate_command ) = unpack("nn",$data);
return ($mmtid,$gate_command);
}

sub decode_application_manager_identifier
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $amidat, $amidam ) = $self->decode_transaction_identifier($data);
return ($amidat, $amidam);
}

sub decode_subscriber_id
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $sub_id ) = unpack("N",$data);
my ( $sub_ip ) = $self->_IpIntToQuad($sub_id);
return ( $sub_id, $sub_ip );
}

sub decode_gate_id
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $gate_id ) = unpack("N",$data);
return $gate_id;
}

sub object_type_decode
{
my ( $self ) = shift;
my ( $major ) = shift;
my ( $minor ) = shift;
my ( @object_types ) = 
		(
			# Nothing at 0
			[],
			# Transaction Identifier 1
			[
				"",
				"Transaction Identifier"
			],
			# Application Manager Identifier 2
			[
				"",
				"Application Manager Identifier"
			],
			# Subscriber Identifier 3
			[
				"",
				"Subscriber Identifier"
			],
			# Gate Identifier 4
			[
				"",
				"Gate Identifier"
			],
			# Sub routines for decode done up to here.
			# Gate Specification 5
			[
				"",
				"Gate Specification"
			],
			# Classifier 6
			[
				"",
				"Classifier",
				"Extended Classifier"
			],
			# Traffic Profile 6
			[
				"",
				"Flow Spec",
				"DOCSIS Service Class Name",
				"Best Effort Service",
				"Non-Real-Time Polling Service",
				"Real-Time Polling Service",
				"Unsolicited Grant Service",
				"Unsolicited Grant Service with Activity Detection",
				"Downstream"
			],
			# Event-Generation-Info 7
			[
				"",
				"Event-Generation-Info",
			],
			# Volume Based Usage Limit
			[
				"",
				"Volume Based Usage Limit"
			],
			# Time Based Usage Limit
			[
				"",	
				"Time Based Usage Limit"
			],
			# Opaque Data
			[
				"",
				"Opaque Data"
			],
			# Gate Time Info
			[
				"",
				"Gate Time Info"
			],
			# Gate Usage Info
			[
				"",
				"Gate Usage Info"
			],
			# Packet Cable Error
			[
				"",
				"Packet Cable Error"
			],
			# Gate State
			[
				"",
				"Gate State"
			],
			# Version Info
			[
				"",
				"Version Info"
			],
			# Policy Server Identifier
			[
				"",
				"Policy Server Identifier"
			],
			# Synch Options
			[
				"",
				"Synch Options"
			],
			# Msg Receipt Key
			[
				"",
				"Msg Receipt Key"
			]
		);
return $object_types[$major][$minor];
}

sub Envelope_Type_remap
{
my ( $self ) = shift;
my ( $envelope_setting ) = shift;
my ( $envelope_type ) = 0;
my ( @types ) = qw [ authorize:1 reserve:2 commit:4 ];
foreach my $find_type ( @types )
	{
	my ( $name, $number ) = (split(/:/,$find_type))[0,1];
	if ( $envelope_setting=~/$name/ig )
		{
		print "Debug envelope number is '$number'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
		$envelope_type+=$number;
		}
	}
return $envelope_type;
}

sub encode_cops_message_no_payload
{
my ( $self ) = shift;
my ( $version ) = shift;
my ( $flags ) = shift;
my ( $opcode ) = shift;
my ( $clienttype ) = shift;
my ( $data ) = "";
my ( $header_v ) = ( ($version<<4) | $flags );
my ( $data_block ) = pack("CCn",$header_v,$opcode,$clienttype);
my ( $length ) = pack("N",length($data)+8);
$data_block.=$length.$data;
return $data_block;
}

sub encode_cops_message
{
my ( $self ) = shift;
my ( $version ) = shift;
my ( $flags ) = shift;
my ( $opcode ) = shift;
my ( $clienttype ) = shift;
my ( $data ) = shift;

my ( $header_v ) = ( ($version<<4) | $flags );
my ( $data_block ) = pack("CCn",$header_v,$opcode,$clienttype);
my ( $length ) = pack("N",length($data)+8);
$data_block.=$length.$data;
return $data_block;
}

sub encode_cops_object
{
my ( $self ) = shift;
my ( $cnum ) = shift;
my ( $ctype ) = shift;
my ( $data ) = shift;

my ( $align ) = 0;

if ( !$data) { $data=""; }

$align = length($data) % 4;

print "Length of data is '".length($data)."' alignment requried is '$align'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

$align = 4 - $align;

if ( $align > 0 && $align <4 ) 
	{ 
	print "Align is '$align'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	for ( my $tmp=0; $tmp<$align; $tmp ++ )
		{
		print "Adding '$tmp'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
		$data.=pack("C",0);
		}
	print "Finished alignment\n\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	}

my ( $length ) = length($data)+4;

my ( $data_block ) = pack("nCC",$length,$cnum,$ctype);
$data_block.=$data;

return $data_block;
}

sub generate_subscriber_id
{
my ( $self ) = shift;
my ( $ip ) = shift;
my ( $cops_object ) = "";
$cops_object = $self->encode_cops_object( 2,1, $self->_IpQuadToInt($ip) );
return $cops_object;
}

sub generate_gate_id
{
my ( $self ) = shift;
my ( $id ) = shift;
my ( $cops_object ) = "";
$cops_object = $self->encode_cops_object( 2,1, pack("N",$id) );
return $cops_object;
}

sub generate_transaction_id
{
my ( $self ) = shift;
my ( $command ) = shift;
print "\n\ntransaction id is '".$self->encode_gate_ids($command)."'\n\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
$command = pack("nn",$self->{_GLOBAL}{'TRANSACTION_COUNT'} , $self->encode_gate_ids($command) );
$self->{_GLOBAL}{'TRANSACTION_COUNT'}++;
my ( $cops_object ) = $self->encode_cops_object( 1,1, $command );
return $cops_object;
}

sub generate_decision
{
my ( $self ) = shift;
my ( $type ) = shift;
my ( $command ) = shift;
my ( $flags ) = shift;
my ( $payload ) = pack("nn", $command, $flags );
my ( $cops_object ) = $self->encode_cops_object( 6,$type, $payload );
return $cops_object;
}

sub decode_radius_attribute
{
# This has only been tested with the output of
# FreeRadius 2.1.9
# The required perl code is included.
#
my ( $self ) = shift;
my ( $radius_name ) = shift;
my ( $radius_value ) = shift;
my ( $data_return ) = shift;

my ( $rad_position ) = $self->_decode_radius_attributes($radius_name);

my ( $radius_array ) = $self->_decode_radius_attribute_layout( $rad_position );

if ( !$radius_array ) { return 0; }

$radius_value = (split(/x/,$radius_value))[1];
if ( !$radius_value) { return 0; }
my ( $radius_value_packed ) = "";
# This a bit of a hack.
for (my $a=0;$a<length($radius_value); $a+=2 )
	{
	my $char = "0x".substr($radius_value,$a,2);
	my $pack = pack("C",oct($char));
	$radius_value_packed.=$pack;
	}

my ( $done_pack ) = 0;

foreach my $rad_a ( @{${$radius_array}} )
	{
	my $type_a = $self->attribute_pack($rad_a);
        my $type_v = 0;
        my $name = "";
        my $data = "";
	my $true_length = 0;
	if ( $type_a=~/^string/i )
                {
		my ( $name_s, $length_s ) = (split(/-/,$type_a))[0,1];
		$data = substr($radius_value_packed,0,$length_s);
		$radius_value_packed = substr( $radius_value_packed, $length_s, length($radius_value_packed)-$length_s);
                }
                else
                {
		$data = unpack( $type_a, $radius_value_packed);
		if ( $type_a=~/^n$/ ) { $true_length=2; }
		if ( $type_a=~/^N$/ ) { $true_length=4; }
		if ( $type_a=~/^C$/ ) { $true_length=1; }
		$radius_value_packed = substr( $radius_value_packed, $true_length, length($radius_value_packed)-$true_length);
		}
	$rad_a=~s/^RADIUS_//g;
	${$data_return}{$rad_a}=$data;
	if ( $rad_a=~/^EventMessageType$/i )
		{ ${$data_return}{'EventMessageTypeName'}=$self->_decode_radius_message_type($data); }
	$data="";
	$true_length=0;
	}
return 1;
}


sub _decode_radius_attributes
{
my ( $self ) = shift;
my ( $radius_name ) = shift;
my ( %types ) =
                (
		'CableLabs-Event-Message' => 0,
		'CableLabs-QoS-Descriptor' => 1
                );
return $types{$radius_name};
}

sub _decode_radius_attribute_layout
{
my ( $self ) = shift;
my ( $part ) = shift;
my ( @headers ) =
                (
                        # CableLabs-Event-Message
                        [
				"RADIUS_EventMessageVersionID",
				"RADIUS_BCID_Timestamp",
				"RADIUS_BCID_ElementID",
				"RADIUS_BCID_TimeZone",
				"RADIUS_BCID_EventCounter",
				"RADIUS_EventMessageType",
				"RADIUS_ElementType",
				"RADIUS_ElementID",
				"RADIUS_TimeZone",
				"RADIUS_SequenceNumber",
				"RADIUS_EventTime",
				"RADIUS_Status",
				"RADIUS_Priority",
				"RADIUS_AttributeCount",
				"RADIUS_EventObject"
                        ],
                        # CableLabs-QoS-Descriptor
                        [
                                "RADIUS_QosStatus",
                                "RADIUS_ServiceClassName"
                        ]
		);
return \$headers[$part];
}

sub _decode_radius_message_type
{
my ( $self ) = shift;
my ( $message ) = shift;
my ( @message_types ) =
		(
			"Reserved",
			"Signaling_Start",
			"Signaling_Stop",
			"Database_Query",
			"Intelligent_Peripheral_Usage_Start",
			"Intelligent_Peripheral_Usage_Stop",
			"Service_Instance",
			"QoS_Reserve",
			"QoS_Release",
			"Service_Activation",
			"Service_Deactivation",
			"Media_Report",
			"Signal_Instance",
			"Interconnect_(Signaling)_Start",
			"Interconnect_(Signaling)_Stop",
			"Call_Answer",
			"Call_Disconnect",
			"Time_Change",
			"18_Missed",
			"QoS_Commit",
			"Media_Alive",
			"Conference_Party_Change"
		);

if ( $message_types[$message] )
	{
	return $message_types[$message];
	}
return "Unknown";
}

sub _IpQuadToInt
{
my ($self)= shift;
my($Quad) = shift;
if ( !$Quad ) { return 0; }
my($Ip1, $Ip2, $Ip3, $Ip4) = split(/\./, $Quad);
my($IpInt) = (($Ip1 << 24) | ($Ip2 << 16) | ($Ip3 << 8) | $Ip4);
return($IpInt);
}

sub _IpIntToQuad 
{
my ( $self ) = shift;
my($Int) = shift;
my($Ip1) = $Int & 0xFF; $Int >>= 8;
my($Ip2) = $Int & 0xFF; $Int >>= 8;
my($Ip3) = $Int & 0xFF; $Int >>= 8;
my($Ip4) = $Int & 0xFF; return("$Ip4.$Ip3.$Ip2.$Ip1");
}

sub decode_64bit_number
{
# see comments on 64bit stuff.
my ( $self ) = shift;
my ( $message ) = shift;
my ($part1,$part2) = unpack("NN",$message);
$part1 = $part1<<32;
$part1+=$part2;
return $part1;
}

sub encode_64bit_number
{
# It seems Q does not work, well not for me
# and this is the quickest way to fix it.
# You STILL NEED 64 BIT SUPPORT!!
my ( $self ) = shift;
my ( $number ) = shift;
# any bit to 64bit number in.
my($test1) = $number & 0xFFFFFFFF; $number >>= 32;
my($test2) = $number & 0xFFFFFFFF;
my $message = pack("NN",$test2,$test1);
return $message;
}

sub general_pack
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $array_pointer ) = shift;
my ( $prefix ) = shift;
my ( $packed ) = "";
if ( !$prefix ) { $prefix=""; }
foreach my $env_c ( @{${$array_pointer}} )
        {
        my $type_c = $self->attribute_pack($env_c);
        my $type_v = 0;
	my $type_push = $prefix.$env_c;
        if ( $env_c=~/^reserved/i )
                {
                print "Reserved type found.\n" if $self->{_GLOBAL}{'DEBUG'}>0;
		$packed.=pack("C",0);
                }
	if ( $type_c=~/^string/i )
                {
		my ( $type, $numlen ) = (split(/-/,$type_c))[0,1];
		if ( !$numlen )
			{
			$packed.=$self->align_string(${$data}{$type_push});
			}
			else
			{
			$packed.=pack("A[$numlen]",${$data}{$type_push});
			}
		}
	if ( $type_c!~/^string/i && $env_c!~/^reserved/i )
		{
		if ( !${$data}{$type_push} )
			{
			$type_v=0;
			}
			else
			{
			if ( ($env_c=~/IP/ ) && ( $env_c!~/IPProtocolId/))
				{
				$type_v = $self->_IpQuadToInt(${$data}{$type_push});
				}
				else
				{
				$type_v = ${$data}{$type_push};
				}
			}
		$packed.=pack( $type_c , $type_v );
		}
        print "General  Encoder Name us '$env_c' value is '$type_v' type is '$type_c'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
        }
return $packed;
}

=cut

sub function2 {
}

=head1 AUTHOR

shamrock@cpan.org, C<< <shamrock at cpan.org> >>

=head1 BUGS

- Sync messages to Cisco CMTS do not seem to work. I have tried alternative
  formats, headers, etc but to no avail. They do work to Motorola and Aris. 
  I have raised this with Cisco but do not expect a response any time soon. 
  If anyone has a packet trace with a working Synch using a Cisco CMTS that
  would be useful.

- The different traffic profiles need work, see examples/profiles.
  The following examples produce an 'Unspecified error' and may be down to
  the values being used. If any one can help with the values that should be
  used, packet trace, then I can look at improving their use.

      Flow Spec                       
      Non-Real-Time Polling Service  
      Real-Time Polling Service  
      Unsolicited Grant Service  


Please report any bugs or feature requests to C<bug-cops-cmts at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=COPS-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

Please do email me if you have any issues so they can be looked at as soon
as possible.

You can find documentation for this module with the perldoc command.

    perldoc COPS::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=COPS-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/COPS-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/COPS-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/COPS-Client/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2012 shamrock@cpan.org, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of COPS::Client
