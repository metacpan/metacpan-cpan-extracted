package BigIP::iControl;

use strict;
use warnings;

use Carp qw(confess croak);
use Exporter;
use SOAP::Lite;
use MIME::Base64;
use Math::BigInt;

our $VERSION    = '0.098';

=head1 NAME

BigIP::iControl - A Perl interface to the F5 iControl API

=head1 SYNOPSIS

        use BigIP::iControl;

        my $ic = BigIP::iControl->new(
                                server		=> 'bigip.company.com',
                                username	=> 'api_user',
                                password	=> 'my_password',
                                port		=> 443,
                                proto		=> 'https'
                        );

	my $virtual	= ($ic->get_vs_list())[0];

	my %stats	= $ic->get_vs_statistics_stringified($virtual);;

	print '*'x50,"\nVirtual: $virtual\n",'*'x50,"\nTimestamp: $stats{timestamp}\n";

	foreach my $s (sort keys %{$stats{stats}}) {
		print "$s\t$stats{stats}{$s}\n"
	}

=head1 DESCRIPTION

This package provides a Perl interface to the F5 BigIP iControl API.

The F5 BigIP iControl API is an open SOAP/XML for communicating with supported F5 BigIP products.

The primary aim of this package is to provide a simplified interface to an already simple and
intutive API and to allow the user to do more with less code.  By reducing the API invocations
to methods returning simple types, it is hoped that this module will provide a simple alternative
for common tasks.

The secondary aim for this package is to provide a simple interface for accessing statistical
data from the iControl API for monitoring, recording, archival and display in other systems.
This objective has largely been obsoleted in v11 with the introduction of new statistical
monitoring and display features in the web UI.

This package generally provides two methods for each each task; a raw method typically returning
the response as received from iControl, and a "stringified" method returning a parsed response.

In general, the stringified methods will typically fufill most requirements and should usually
be easier to use.

=cut

our $urn_map;

# Our implementation of the iControl API
# Refer to http://devcentral.f5.com/wiki/iControl.APIReference.ashx for complete detail.

our $modules    = {
	ARX		=>	{},
	ASM		=>	{},
	Common		=>	{},
	GlobalLB	=>	{
				Pool		=>	{
							get_description		=> 'pool_names',
							get_list		=> 0,
							get_member		=> 'pool_names'
							},
				VirtualServer	=>	{
							get_all_statistics	=> 0,
							get_enabled_state	=> 'virtual_servers',
							get_list		=> 0
							}
				},
	LTConfig	=>	{},
	LocalLB		=>	{
				VirtualServer	=>	{
							get_list		=> 0,
							get_default_pool_name	=> 'virtual_servers',
							get_destination		=> 'virtual_servers',
							get_enabled_state	=> 'virtual_servers',
							get_protocol		=> 'virtual_servers',
							get_statistics		=> 'virtual_servers',
							get_all_statistics	=> 0,
							get_rule		=> 'virtual_servers',
							get_snat_pool		=> 'virtual_servers',
							get_snat_type		=> 'virtual_servers'
							},
				Pool		=>	{
							get_list		=> 0,
							get_member		=> 'pool_names',
							get_object_status	=> 'pool_names',
							get_statistics		=> 'pool_names',
							get_all_statistics	=> 'pool_names',
							get_member_object_status=> {pool_names => 1, members => 1}
							},
				PoolMember	=>	{
							get_object_status	=> 'pool_names',
							get_statistics		=> {pool_names => 1, members => 1},
							get_all_statistics	=> 'pool_names',
							},
				NodeAddress	=>	{
							get_list		=> 0,
							get_screen_name		=> 'node_addresses',
							get_object_status	=> 'node_addresses',
							get_monitor_status	=> 'node_addresses',
							get_statistics		=> 'node_addresses'
							},
				Class		=>	{
							get_address_class_list	=> 0,
							get_string_class_list	=> 0,
							get_string_class	=> 'class_names',
							get_string_class_member_data_value	=> 'class_members',
							set_string_class_member_data_value	=> {class_members => 1, values => 1},
							add_string_class_member	=> 'class_members',
							delete_string_class_member=> 'class_members',
							}
				},
	Management	=>	{
				DBVariable	=>	{
							query			=> 'variables'
							},
				EventSubscription=>	{
							create			=> 'sub_detail_list',
							get_list		=> 0,
							get_authentication	=> 'id_list',
							get_state		=> 'id_list',
							get_url			=> 'id_list',
							get_proxy_url		=> 'id_list',
							remove			=> 'id_list',
							query			=> 'id_list'
							}
				},
	Networking	=>	{
				Interfaces	=>	{
							get_list		=> 0,
							get_enabled_state	=> {interfaces => 1},
							get_media_speed		=> {interfaces => 1},
							get_media_status	=> {interfaces => 1},
							get_statistics		=> {interfaces => 1}
							},
				SelfIP		=>	{
							get_list		=> 0,
							get_vlan		=> {self_ips	=> 1}
							},
				Trunk		=>	{
							get_interface		=> {trunks => 1},
							get_lacp_enabled_state	=> {trunks => 1},
							get_active_lacp_state	=> {trunks => 1},
							get_list		=> 0,
							get_configured_member_count=> {trunks => 1},
							get_operational_member_count=> {trunks => 1},
							get_media_speed		=> {trunks => 1},
							get_media_status	=> {trunks => 1},
							get_statistics		=> {trunks => 1}
							}
				},
	System		=>	{
				ConfigSync	=>	{
							get_configuration_list	=> 0,
							delete_configuration	=> {filename => 1},
							save_configuration	=> {filename => 1, save_flag => 1},
							download_file		=> {file_name => 1, chunk_size => 1, file_offset => 1},
							download_configuration	=> {config_name => 1, chunk_size => 1, file_offset => 1}
							},
				SystemInfo	=>	{
							get_system_information	=> 0,
							get_system_id		=> 0,
							get_cpu_metrics		=> 0,
							get_cpu_usage_extended_information=> 'host_ids'
							},
				Cluster		=>	{
							get_cluster_enabled_state=> 'cluster_names',
							get_list		=> 0
							},
				Failover	=>	{
							get_failover_mode	=> 0,
							get_failover_state	=> 0,
							is_redundant		=> 0
							},
				Connections	=>	{
							get_list		=> 0,
							get_all_active_connections=>0
							},
				Services        =>      {
							get_list                => 0,
							get_service_status      => {services => 1},
							get_all_service_statuses=> 0
							}
				},
	WebAccelerator	=>	{}
	};

our $event_types= {
        EVENTTYPE_NONE                  =>      1,
        EVENTTYPE_TEST                  =>      1,
        EVENTTYPE_ALL                   =>      1,
        EVENTTYPE_SYSTEM_STARTUP        =>      1,
        EVENTTYPE_SYSTEM_SHUTDOWN       =>      1,
        EVENTTYPE_SYSTEM_CONFIG_LOAD    =>      1,
        EVENTTYPE_CREATE                =>      1,
        EVENTTYPE_MODIFY                =>      1,
        EVENTTYPE_DELETE                =>      1,
        EVENTTYPE_ADMIN_IP              =>      1,
        EVENTTYPE_ARP_ENTRY             =>      1,
        EVENTTYPE_DAEMON_HA             =>      1,
        EVENTTYPE_DB_VARIABLE           =>      1,
        EVENTTYPE_FEATURE_FLAGS         =>      1,
        EVENTTYPE_FILTER_PROFILE        =>      1,
        EVENTTYPE_GTMD                  =>      1,
        EVENTTYPE_INTERFACE             =>      1,
        EVENTTYPE_LCDWARN               =>      1,
        EVENTTYPE_L2_FORWARD            =>      1,
        EVENTTYPE_MIRROR_PORT_MEMBER    =>      1,
        EVENTTYPE_MIRROR_PORT           =>      1,
        EVENTTYPE_MIRROR_VLAN           =>      1,
        EVENTTYPE_MONITOR               =>      1,
        EVENTTYPE_NAT                   =>      1,
        EVENTTYPE_NODE_ADDRESS          =>      1,
        EVENTTYPE_PACKET_FILTER         =>      1,
        EVENTTYPE_PCI_DEVICE            =>      1,
        EVENTTYPE_POOL                  =>      1,
        EVENTTYPE_POOL_MEMBER           =>      1,
        EVENTTYPE_RATE_FILTER           =>      1,
        EVENTTYPE_ROUTE_MGMT            =>      1,
        EVENTTYPE_ROUTE_UPDATE          =>      1,
        EVENTTYPE_RULE                  =>      1,
        EVENTTYPE_SELF_IP               =>      1,
        EVENTTYPE_SENSOR                =>      1,
        EVENTTYPE_SNAT_ADDRESS          =>      1,
        EVENTTYPE_SNAT_POOL             =>      1,
        EVENTTYPE_SNAT_POOL_MEMBER      =>      1,
        EVENTTYPE_STP                   =>      1,
        EVENTTYPE_SWITCH_DOMAIN         =>      1,
        EVENTTYPE_SWITCH_EDGE           =>      1,
        EVENTTYPE_TAMD_AUTH             =>      1,
        EVENTTYPE_TRUNK                 =>      1,
        EVENTTYPE_TRUNK_CONFIG_MEMBER   =>      1,
        EVENTTYPE_TRUNK_WORKING_MEMBER  =>      1,
        EVENTTYPE_VALUE_LIST            =>      1,
        EVENTTYPE_VIRTUAL_ADDRESS       =>      1,
        EVENTTYPE_VIRTUAL_SERVER        =>      1,
        EVENTTYPE_VIRTUAL_SERVER_PROFILE=>      1,
        EVENTTYPE_VLAN                  =>      1,
        EVENTTYPE_VLAN_MEMBER           =>      1,
        EVENTTYPE_VLANGROUP             =>      1
};


sub BEGIN {

	$urn_map= {
                '{urn:iControl}ASM.ApplyLearningType'					=> 1,
                '{urn:iControl}ASM.DynamicSessionsInUrlType'				=> 1,
                '{urn:iControl}ASM.FlagState'						=> 1,
                '{urn:iControl}ASM.PolicyTemplate'					=> 1,
                '{urn:iControl}ASM.ProtocolType'					=> 1,
                '{urn:iControl}ASM.SeverityName'					=> 1,
                '{urn:iControl}ASM.ViolationName'					=> 1,
                '{urn:iControl}ASM.WebApplicationLanguage'				=> 1,
                '{urn:iControl}Common.ArmedState'					=> 1,
                '{urn:iControl}Common.AuthenticationMethod'				=> 1,
                '{urn:iControl}Common.AvailabilityStatus'				=> 1,
                '{urn:iControl}Common.DaemonStatus'					=> 1,
                '{urn:iControl}Common.EnabledState'					=> 1,
                '{urn:iControl}Common.EnabledStatus'					=> 1,
                '{urn:iControl}Common.FileChainType'					=> 1,
                '{urn:iControl}Common.HAAction'						=> 1,
                '{urn:iControl}Common.HAState'						=> 1,
                '{urn:iControl}Common.IPHostType'					=> 1,
                '{urn:iControl}Common.ProtocolType'					=> 1,
                '{urn:iControl}Common.SourcePortBehavior'				=> 1,
                '{urn:iControl}Common.StatisticType'					=> 1,
                '{urn:iControl}Common.TMOSModule'					=> 1,
                '{urn:iControl}GlobalLB.AddressType'					=> 1,
                '{urn:iControl}GlobalLB.AutoConfigurationState'				=> 1,
                '{urn:iControl}GlobalLB.AvailabilityDependency'				=> 1,
                '{urn:iControl}GlobalLB.LBMethod'					=> 1,
                '{urn:iControl}GlobalLB.LDNSProbeProtocol'				=> 1,
                '{urn:iControl}GlobalLB.LinkWeightType'					=> 1,
                '{urn:iControl}GlobalLB.MetricLimitType'				=> 1,
                '{urn:iControl}GlobalLB.MonitorAssociationRemovalRule'			=> 1,
                '{urn:iControl}GlobalLB.MonitorInstanceStateType'			=> 1,
                '{urn:iControl}GlobalLB.MonitorRuleType'				=> 1,
                '{urn:iControl}GlobalLB.RegionDBType'					=> 1,
                '{urn:iControl}GlobalLB.RegionType'					=> 1,
                '{urn:iControl}GlobalLB.ServerType'					=> 1,
                '{urn:iControl}GlobalLB.Application.ApplicationObjectType'		=> 1,
                '{urn:iControl}GlobalLB.DNSSECKey.KeyAlgorithm'				=> 1,
                '{urn:iControl}GlobalLB.DNSSECKey.KeyType'				=> 1,
                '{urn:iControl}GlobalLB.Monitor.IntPropertyType'			=> 1,
                '{urn:iControl}GlobalLB.Monitor.StrPropertyType'			=> 1,
                '{urn:iControl}GlobalLB.Monitor.TemplateType'				=> 1,
                '{urn:iControl}LocalLB.AddressType'					=> 1,
                '{urn:iControl}LocalLB.AuthenticationMethod'				=> 1,
                '{urn:iControl}LocalLB.AvailabilityStatus'				=> 1,
                '{urn:iControl}LocalLB.ClientSSLCertificateMode'			=> 1,
                '{urn:iControl}LocalLB.ClonePoolType'					=> 1,
                '{urn:iControl}LocalLB.CompressionMethod'				=> 1,
                '{urn:iControl}LocalLB.CookiePersistenceMethod'				=> 1,
                '{urn:iControl}LocalLB.CredentialSource'				=> 1,
                '{urn:iControl}LocalLB.EnabledStatus'					=> 1,
                '{urn:iControl}LocalLB.HardwareAccelerationMode'			=> 1,
                '{urn:iControl}LocalLB.HttpChunkMode'					=> 1,
                '{urn:iControl}LocalLB.HttpCompressionMode'				=> 1,
                '{urn:iControl}LocalLB.HttpRedirectRewriteMode'				=> 1,
                '{urn:iControl}LocalLB.LBMethod'					=> 1,
                '{urn:iControl}LocalLB.MonitorAssociationRemovalRule'			=> 1,
                '{urn:iControl}LocalLB.MonitorInstanceStateType'			=> 1,
                '{urn:iControl}LocalLB.MonitorRuleType'					=> 1,
                '{urn:iControl}LocalLB.MonitorStatus'					=> 1,
                '{urn:iControl}LocalLB.PersistenceMode'					=> 1,
                '{urn:iControl}LocalLB.ProfileContextType'				=> 1,
                '{urn:iControl}LocalLB.ProfileMode'					=> 1,
                '{urn:iControl}LocalLB.ProfileType'					=> 1,
                '{urn:iControl}LocalLB.RamCacheCacheControlMode'			=> 1,
                '{urn:iControl}LocalLB.RtspProxyType'					=> 1,
                '{urn:iControl}LocalLB.SSLOption'					=> 1,
                '{urn:iControl}LocalLB.ServerSSLCertificateMode'			=> 1,
                '{urn:iControl}LocalLB.ServiceDownAction'				=> 1,
                '{urn:iControl}LocalLB.SessionStatus'					=> 1,
                '{urn:iControl}LocalLB.SnatType'					=> 1,
                '{urn:iControl}LocalLB.TCPCongestionControlMode'			=> 1,
                '{urn:iControl}LocalLB.TCPOptionMode'					=> 1,
                '{urn:iControl}LocalLB.UncleanShutdownMode'				=> 1,
                '{urn:iControl}LocalLB.VirtualAddressStatusDependency'			=> 1,
                '{urn:iControl}LocalLB.Class.ClassType'					=> 1,
                '{urn:iControl}LocalLB.Class.FileFormatType'				=> 1,
                '{urn:iControl}LocalLB.Class.FileModeType'				=> 1,
                '{urn:iControl}LocalLB.Monitor.IntPropertyType'				=> 1,
                '{urn:iControl}LocalLB.Monitor.StrPropertyType'				=> 1,
                '{urn:iControl}LocalLB.Monitor.TemplateType'				=> 1,
                '{urn:iControl}LocalLB.ProfilePersistence.PersistenceHashMethod'	=> 1,
                '{urn:iControl}LocalLB.ProfileUserStatistic.UserStatisticKey'		=> 1,
                '{urn:iControl}LocalLB.RAMCacheInformation.RAMCacheVaryType'		=> 1,
                '{urn:iControl}LocalLB.RateClass.DirectionType'				=> 1,
                '{urn:iControl}LocalLB.RateClass.DropPolicyType'			=> 1,
                '{urn:iControl}LocalLB.RateClass.QueueType'				=> 1,
                '{urn:iControl}LocalLB.RateClass.UnitType'				=> 1,
                '{urn:iControl}LocalLB.VirtualServer.VirtualServerCMPEnableMode'	=> 1,
                '{urn:iControl}LocalLB.VirtualServer.VirtualServerType'			=> 1,
                '{urn:iControl}Management.DebugLevel'					=> 1,
                '{urn:iControl}Management.LDAPPasswordEncodingOption'			=> 1,
                '{urn:iControl}Management.LDAPSSLOption'				=> 1,
                '{urn:iControl}Management.LDAPSearchMethod'				=> 1,
                '{urn:iControl}Management.LDAPSearchScope'				=> 1,
                '{urn:iControl}Management.OCSPDigestMethod'				=> 1,
                '{urn:iControl}Management.ZoneType'					=> 1,
                '{urn:iControl}Management.EventNotification.EventDataType'		=> 1,
                '{urn:iControl}Management.EventSubscription.AuthenticationMode'		=> 1,
                '{urn:iControl}Management.EventSubscription.EventType'			=> 1,
                '{urn:iControl}Management.EventSubscription.ObjectType'			=> 1,
                '{urn:iControl}Management.EventSubscription.SubscriptionStatusCode'	=> 1,
                '{urn:iControl}Management.KeyCertificate.CertificateType'		=> 1,
                '{urn:iControl}Management.KeyCertificate.KeyType'			=> 1,
                '{urn:iControl}Management.KeyCertificate.ManagementModeType'		=> 1,
                '{urn:iControl}Management.KeyCertificate.SecurityType'			=> 1,
                '{urn:iControl}Management.KeyCertificate.ValidityType'			=> 1,
                '{urn:iControl}Management.Provision.ProvisionLevel'			=> 1,
                '{urn:iControl}Management.SNMPConfiguration.AuthType'			=> 1,
                '{urn:iControl}Management.SNMPConfiguration.DiskCheckType'		=> 1,
                '{urn:iControl}Management.SNMPConfiguration.LevelType'			=> 1,
                '{urn:iControl}Management.SNMPConfiguration.ModelType'			=> 1,
                '{urn:iControl}Management.SNMPConfiguration.PrefixType'			=> 1,
                '{urn:iControl}Management.SNMPConfiguration.PrivacyProtocolType'	=> 1,
                '{urn:iControl}Management.SNMPConfiguration.SinkType'			=> 1,
                '{urn:iControl}Management.SNMPConfiguration.TransportType'		=> 1,
                '{urn:iControl}Management.SNMPConfiguration.ViewType'			=> 1,
                '{urn:iControl}Management.UserManagement.UserRole'			=> 1,
                '{urn:iControl}Networking.FilterAction'					=> 1,
                '{urn:iControl}Networking.FlowControlType'				=> 1,
                '{urn:iControl}Networking.LearningMode'					=> 1,
                '{urn:iControl}Networking.MediaStatus'					=> 1,
                '{urn:iControl}Networking.MemberTagType'				=> 1,
                '{urn:iControl}Networking.MemberType'					=> 1,
                '{urn:iControl}Networking.PhyMasterSlaveMode'				=> 1,
                '{urn:iControl}Networking.RouteEntryType'				=> 1,
                '{urn:iControl}Networking.STPLinkType'					=> 1,
                '{urn:iControl}Networking.STPModeType'					=> 1,
                '{urn:iControl}Networking.STPRoleType'					=> 1,
                '{urn:iControl}Networking.STPStateType'					=> 1,
                '{urn:iControl}Networking.ARP.NDPState'					=> 1,
                '{urn:iControl}Networking.Interfaces.MediaType'				=> 1,
                '{urn:iControl}Networking.ProfileWCCPGRE.WCCPGREForwarding'		=> 1,
                '{urn:iControl}Networking.STPInstance.PathCostType'			=> 1,
                '{urn:iControl}Networking.SelfIPPortLockdown.AllowMode'			=> 1,
                '{urn:iControl}Networking.Trunk.DistributionHashOption'			=> 1,
                '{urn:iControl}Networking.Trunk.LACPTimeoutOption'			=> 1,
                '{urn:iControl}Networking.Trunk.LinkSelectionPolicy'			=> 1,
                '{urn:iControl}Networking.Tunnel.TunnelDirection'			=> 1,
                '{urn:iControl}Networking.VLANGroup.VLANGroupTransparency'		=> 1,
                '{urn:iControl}Networking.iSessionLocalInterface.NatSourceAddress'	=> 1,
                '{urn:iControl}Networking.iSessionPeerDiscovery.DiscoveryMode'		=> 1,
                '{urn:iControl}Networking.iSessionPeerDiscovery.FilterMode'		=> 1,
                '{urn:iControl}Networking.iSessionRemoteInterface.NatSourceAddress'	=> 1,
                '{urn:iControl}Networking.iSessionRemoteInterface.OriginState'		=> 1,
                '{urn:iControl}System.CPUMetricType'					=> 1,
                '{urn:iControl}System.FanMetricType'					=> 1,
                '{urn:iControl}System.HardwareType'					=> 1,
                '{urn:iControl}System.PSMetricType'					=> 1,
                '{urn:iControl}System.TemperatureMetricType'				=> 1,
                '{urn:iControl}System.ConfigSync.ConfigExcludeComponent'		=> 1,
                '{urn:iControl}System.ConfigSync.ConfigIncludeComponent'		=> 1,
                '{urn:iControl}System.ConfigSync.LoadMode'				=> 1,
                '{urn:iControl}System.ConfigSync.SaveMode'				=> 1,
                '{urn:iControl}System.ConfigSync.SyncMode'				=> 1,
                '{urn:iControl}System.Disk.RAIDStatus'					=> 1,
                '{urn:iControl}System.Failover.FailoverMode'				=> 1,
                '{urn:iControl}System.Failover.FailoverState'				=> 1,
                '{urn:iControl}System.Services.ServiceAction'				=> 1,
                '{urn:iControl}System.Services.ServiceStatusType'			=> 1,
                '{urn:iControl}System.Services.ServiceType'				=> 1,
                '{urn:iControl}System.Statistics.GtmIQueryState'			=> 1,
                '{urn:iControl}System.Statistics.GtmPathStatisticObjectType'		=> 1,
	};

	package BigIP::iControlDeserializer;
	@BigIP::iControlDeserializer::ISA = 'SOAP::Deserializer';

	sub typecast {
		my ($self, $value, $name, $attrs, $children, $type) = @_;
		my $retval = undef;
		if (not defined $type or not defined $urn_map->{$type}) {return $retval}
		if ($urn_map->{$type} == 1) {$retval = $value}
		return $retval;
	}
}

=head2 METHODS

=head3 new (%args)

	my $ic = BigIP::iControl->new(
				server		=> 'bigip.company.com',
				username	=> 'api_user',
				password	=> 'my_password',
				port		=> 443,
				proto		=> 'https',
				verify_hostname	=> 0
			);

Constructor method.  Creates a new BigIP::iControl object representing a single interface into the iControl 
API of the target system.

Required parameters are:

=over 3

=item server

The target F5 BIGIP device.  The supplied value may be either an IP address, FQDN or resolvable hostname.

=item username

The username with which to connect to the iControl API.

=item password

The password with which to connect to the iControl API.

=item port

The port on which to connect to the iControl API.  If not specified this value will default to 443.

=item proto

The protocol with to use for communications with the iControl API (should be either http or https).  If not specified
this value will default to https.

=item verify_hostname

If TRUE when used with a secure connection then the client will ensure that the target server has a valid certificate 
matching the expected hostname.

=back

=cut

sub new {
	my ($class, %args)	= @_;
	my $self		= bless {}, $class;
        defined $args{server}	? $self->{server}	= $args{server}		: croak 'Constructor failed: server not defined';
	defined $args{username}	? $self->{username}	= $args{username}	: croak 'Constructor failed: username not defined';
	defined $args{password}	? $self->{password}	= $args{password}	: croak 'Constructor failed: password not defined';
	$self->{proto}		= ($args{proto} or 'https');
	$self->{port}		= ($args{port} or '443');
	$self->{_client}	= SOAP::Lite	->proxy($self->{proto}.'://'.$self->{server}.':'.$self->{port}.'/iControl/iControlPortal.cgi')
						->deserializer(BigIP::iControlDeserializer->new());
	$self->{_client}->transport->http_request->header('Authorization' => 'Basic ' . MIME::Base64::encode("$self->{username}:$self->{password}") );
	eval { $self->{_client}->transport->ssl_opts( verify_hostname => $args{verify_hostname} ) };
	return $self;
}

sub _set_uri {
	my ($self, $module, $interface)	= @_;
	$self->{_client}->uri("urn:iControl:$module/$interface");
	return 1
}

sub _unset_uri {
        undef $_[0]->{_client}->{uri};
}

sub _get_username {
	return $_[0]->{username};
}

# We do most of our request validation in this method so it is unnessecarily complex, not entirely intuitive, uglier
# than a hat full of assholes and slightly less elegant than Lindsay Lohan exiting a limo.
#
# By pushing complexity from our public methods into here, we can implement some basic checks against known bad
# invocations rather than just passing them through to iControl to handle.
# 
# It also allows us to limit the over-riding or abuse of the internal _request method by limiting
# invocations to the parameter format specified in global $modules struct.
#
# We can then implement accessor methods by essentially copying the API invocation from the reference.  For example,
# to implement the System::SystemInfo::get_system_id API call, the reference gives the prototype as;
#
#  String get_system_id();
#
# Note also that the API uses the namespace convention of Module::Interface::Method, so that our get_system_id method
# is implemented in the SystemInfo interface, which is under the System module.
#
# Implementing this, we would first add the method to our $modules struct maintaining the API heirarchy;
#
#  $modules => {
#	       System => {
#			 SystemInfo => {
#				       get_system_id => 0
#
# Analogous to:
#
#  $modules => {
#	       Module => {
#			 Interface => {
#				      Method => parameters
#
# A value of 0 is used for get_system_id as the method prototype takes no parameters.  For methods taking a single
# parameter, we would use the value of the required parameter name, for methods taking numerous parameters, we would
# use a hash containing a key for each parameter. 
#
# Our method is then created as an invocation to the private _request method setting the value of the module,
# interface and method arguments as per the API reference. i.e.
#
#  module	=> 'System'
#  interface	=> 'SystemInfo'
#  method	=> 'get_system_id'
#
# Which is intuitively translated into the implementation below;
# 
#  sub get_cluster_enabled_state {
#	my $self	= shift;
#	return $self->_request(module => 'System', interface => 'Cluster', method => 'get_cluster_enabled_state');
#  }
#

sub _request {
	my ($self, %args)= @_;
	$args{module}   and exists $modules->{$args{module}} 
                        or return 'Request error: unknown module name: "'.$args{module}.'"';
	$args{interface}and exists $modules->{$args{module}}->{$args{interface}}
                        or return "Request error: unknown interface name for module $args{module}: \"$args{interface}\"";
        $args{method}   and exists $modules->{$args{module}}->{$args{interface}}->{$args{method}} 
                        or return "Request error: unknown method name for module $args{module} and interface $args{interface}: \"$args{method}\"";

        my @params = ();

        if ($modules->{$args{module}}->{$args{interface}}->{$args{method}}) {

                foreach my $arg (keys %{$args{data}}) {

                        if (ref $modules->{$args{module}}->{$args{interface}}->{$args{method}} eq 'HASH') {
                                exists $modules->{$args{module}}->{$args{interface}}->{$args{method}}->{$arg}
                                        or croak "Request error: method $args{method} for interface $args{interface} in module $args{module} requires " .
                                                 "mandatory data parameter \"$modules->{$args{module}}->{$args{interface}}->{$args{method}}->{$arg}\"";
                                        push @params, SOAP::Data->name($arg => $args{data}{$arg});
                        }
                        else {
                                $arg eq $modules->{$args{module}}->{$args{interface}}->{$args{method}}
                                        or croak "Request error: method $args{method} for interface $args{interface} in module $args{module} requires " .
                                                 "mandatory data parameter \"$modules->{$args{module}}->{$args{interface}}->{$args{method}}\"";
                                push @params, SOAP::Data->name(%{$args{data}});
                        }
                }
	}

        $self->_set_uri($args{module}, $args{interface});
        my $method      = $args{method};
        my $query       = $self->{_client}->$method(@params);
        $query->fault and confess('SOAP call failed: ', $query->faultstring());
        $self->_unset_uri();
        return $query->result;
}

sub __get_timestamp {
	my $time;
	my %ts;
	@ts{qw(year month day hour minute second)} = ((localtime(time))[5,4,3,2,1,0]);
	$ts{year}+=1900;
	$ts{month}++;

	foreach (keys %ts) {
		$time->{$_} = $ts{$_};
	}
	
	return __process_timestamp($time);
}

sub __process_timestamp {
	my $time_stamp	= shift;
	return (__zero_fill($time_stamp->{year})	. '-' .
		__zero_fill($time_stamp->{month})	. '-' .
		__zero_fill($time_stamp->{day})		. '-' .
		__zero_fill($time_stamp->{hour})	. '-' .
		__zero_fill($time_stamp->{minute})	. '-' .
		__zero_fill($time_stamp->{second}))
}

sub __process_statistics {
	my $statistics	= shift;

	my %stat_obj	= (timestamp => __process_timestamp($statistics->{time_stamp}));

	foreach (@{@{$statistics->{statistics}}[0]->{statistics}}) {
		my $type		= $_->{type};
		$stat_obj{stats}{$type}	= Math::BigInt->new("0x" . unpack("H*", pack("N2",$_->{value}{high}, $_->{value}{low})))->bstr;
	}
	
	return %stat_obj
}

sub __process_pool_member_statistics {
	my $statistics	= shift;
	my $timestamp	= @{$statistics}[0]->{time_stamp};
	my %stat_obj;

	foreach (@{@{$statistics}[0]->{statistics}}) {
		my $node	= $_->{member}->{address}.':'.$_->{member}->{port};
		$stat_obj{$node}= {__process_statistics( { time_stamp => $timestamp, statistics => [ $_ ] } )};
	}
	
	return %stat_obj
}

sub __process_cpu_statistics {
	my $statistics	= shift;
	my $cpu_cnt	= 0;
	my %stat_obj	= (timestamp => __get_timestamp);

	foreach my $cpu (@{$statistics}) {

		foreach (@{$cpu}) {
			$stat_obj{stats}{$cpu_cnt}{$_->{type}} = (($_->{value}{high})<<32)|(abs $_->{value}{low});
		}
		
		$cpu_cnt++;
	}

	return %stat_obj
}

sub __zero_fill {
	return ($_[0] < 10 ? '0' . $_[0] : $_[0])
}

=head3 get_system_information

Return a SystemInformation struct containing the identifying attributes of the operating system.
The struct information is described below;

	Member					Type		Description
	----------				----------	----------
	system_name				String		The name of the operating system implementation.
	host_name				String		The host name of the system.
	os_release				String		The release level of the operating system.
	os_machine				String		The hardware platform CPU type.
	os_version				String		The version string for the release of the operating system.
	platform				String		The platform of the device.
	product_category			String		The product category of the device.
	chassis_serial				String		The chassis serial number.
	switch_board_serial			String		The serial number of the switch board.
	switch_board_part_revision		String		The part revision number of the switch board.
	host_board_serial			String		The serial number of the host motherboard.
	host_board_part_revision		String		The part revision number of the host board.
	annunciator_board_serial		String		The serial number of the annuciator board.
	annunciator_board_part_revision		String		The part revision number of the annunciator board. 

=cut

sub get_system_information {
	return $_[0]->_request(module => 'System', interface => 'SystemInfo', method => 'get_system_information')
}

=head3 get_system_id ()

Gets the unique identifier for the system. 

=cut

sub get_system_id {
	return $_[0]->_request(module => 'System', interface => 'SystemInfo', method => 'get_system_id')
}

=head3 get_cpu_metrics ()

Gets the CPU metrics for the CPU(s) on the platform.

=cut

sub get_cpu_metrics {
	return $_[0]->_request(module => 'System', interface => 'SystemInfo', method => 'get_cpu_metrics');
}

=head3 get_cpu_metrics_stringified ()

Gets the CPU metrics for the CPU(s) on the platform.

=cut

sub get_cpu_metrics_stringified {
	my $self	= shift;
	my $res;

	my $metrics	= $self->get_cpu_metrics;
	$res->{timestamp}= __get_timestamp;

	foreach (@{$metrics->{cpus}}) {
		$res->{@{$_}[0]->{value}}->{temp}	= @{$_}[1]->{value};
		$res->{@{$_}[0]->{value}}->{fan}	= @{$_}[2]->{value};
	}

	return $res
}

sub __get_cpu_metric {
	my($self,$cpu,$metric)=@_;
	my $metrics	= $self->get_cpu_metrics_stringified();
	exists $metrics->{$cpu} and return $metrics->{$cpu}->{$metric};
}

=head3 get_cpu_fan_speed ($cpu) 

Returns the current CPU fan speed in RPM for the specified CPU.

=cut

sub get_cpu_fan_speed { 
	return $_[0]->__get_cpu_metric($_[1],'fan') 
}

=head3 get_cpu_temp ($cpu) 

Returns the current CPU temperature degrees celcius for the specified CPU.

=cut

sub get_cpu_temp { 
	return $_[0]->__get_cpu_metric($_[1],'temp') 
}

=head3 get_cpu_usage_extended_information ()

=cut

sub get_cpu_usage_extended_information {
	my($self,$id)	= @_;
	$id		||= $self->{server};
	return $self->_request(module => 'System', interface => 'SystemInfo', method => 'get_cpu_usage_extended_information', data => {host_ids => [$id]});
}

=head3 get_cpu_usage_extended_information_stringified ()

=cut

sub get_cpu_usage_extended_information_stringified {
	my($self,$id)	= shift;
	__process_cpu_statistics(@{$self->get_cpu_usage_extended_information($id)->{hosts}}[0]->{statistics});
}

=head3 get_cluster_list ()

Gets a list of the cluster names.

=cut

sub get_cluster_list {
	return $_[0]->_request(module => 'System', interface => 'Cluster', method => 'get_list');
}

=head3 get_failover_mode ()

Gets the current fail-over mode that the device is running in. 

=cut

sub get_failover_mode {
	return $_[0]->_request(module => 'System', interface => 'Failover', method => 'get_failover_mode');
}

=head3 get_failover_state ()

Gets the current fail-over state that the device is running in. 

=cut

sub get_failover_state {
	return $_[0]->_request(module => 'System', interface => 'Failover', method => 'get_failover_state');
}

=head3 is_redundant ()

Returns a boolean indicating the redundancy state of the device.

=cut

sub is_redundant {
	return $_[0]->_request(module => 'System', interface => 'Failover', method => 'is_redundant');
}

=head3 get_cluster_enabled_state ()

Gets the cluster enabled states. 

=cut

sub get_cluster_enabled_state {
	return $_[0]->_request(module => 'System', interface => 'Cluster', method => 'get_cluster_enabled_state');
}

=head3 get_service_list () 

Returns a list of all supported services on this host.

=cut

sub get_service_list {
	return @{$_[0]->_request(module => 'System', interface => 'Services', method => 'get_list')}
}

=head3 get_service_status () 

Returns the status of the specified service.

=cut

sub get_service_status {
	my($self,$service)= shift;
	return $self->_request(module => 'System', interface => 'Services', method => 'get_service_status', data => { services => $service });
}

=head3 get_all_service_statuses () 

Returns the status of all services.

=cut

sub get_all_service_statuses {
	my $self	= shift;
	my %res;

	foreach my $service (@{$self->_request(module => 'System', interface => 'Services', method => 'get_all_service_statuses')}) {
		$res{$service->{service}}	= $service->{status}
	}

	return %res
}

=head3 save_configuration ($filename)

	$ic->save_configuration('backup.ucs');

	# is equivalent to

	$ic->save_configuration('backup');
	
	# Not specifying a filename will use today's date in the
	# format YYYYMMDD as the filename.

	$ic->save_configuration();

	# is equivalent to

	$ic->save_configuration('today');
	

Saves the current configurations on the target device.  

This method takes a single optional parameter; the filename to which the configuration should be saved.  The file
extension B<.ucs> will be suffixed to the filename if missing from the supplied filename.

Specifying no optional filename parameter or using the filename B<today> will use the current date as the filename
of the saved configuration file in the format B<YYYYMMDD>.

=cut

sub __save_configuration {
	my ($self,$filename,$flag)	= @_;

	if (($filename eq 'today') or ($filename eq '')) {
		$filename = __get_timestamp();
	}
	
	$flag or $flag = 'SAVE_FULL';

	$self->_request(module => 'System', interface => 'ConfigSync', method => 'save_configuration', data => { filename => $filename, save_flag => $flag});

	return 1	
}

sub save_configuration {
	my ($self,$filename)	= @_;
	return ($self->__save_configuration($filename,'SAVE_FULL'));
}

=head3 save_base_configuration ()

        $ic->save_base_configuration();

Saves only the base configuration (VLANs, self IPs...). The filename specified when used with this mode will 
be ignored, since configuration will be saved to /config/bigip_base.conf by default. 

=cut

sub save_base_configuration {
	return ($_[0]->__save_configuration('ignore','SAVE_BASE_LEVEL_CONFIG'))
}

=head3 save_high_level_configuration ()

        $ic->save_high_level_configuration();

Saves only the high-level configuration (virtual servers, pools, members, monitors...). The filename specified 
when used with this mode will be ignored, since configuration will be saved to /config/bigip.conf by default. 

=cut

sub save_high_level_configuration {
	return ($_[0]->__save_configuration('ignore','SAVE_HIGH_LEVEL_CONFIG'))
}


=head3 download_configuration ($filename)

This method downloads a saved UCS configuration from the target device.

=cut

sub download_configuration {
	my ($self,$config_name,$local_file)	= @_;
	my $chunk	= 65536;
	my $offset	= 0;
	my $data;

	$config_name or croak 'No configuration file specified';

	open my $fh, '+>', $local_file or croak "Unable to open local file: $local_file";
	binmode($fh);

	while (1) {
		$data	= $self->_request(module => 'System', interface => 'ConfigSync', method => 'download_configuration', data => {config_name => $config_name, chunk_size => $chunk, file_offset => $offset});
		print $fh $data->{file_data};
		last if (($data->{chain_type} eq 'FILE_LAST') or ($data->{chain_type} eq 'FILE_FIRST_AND_LAST'));
		$offset+=(length($data->{file_data}));		
	}

	close $fh;
	return 1
}

=head3 get_configuration_list ()

	my %config_list = $ic->get_configuration_list();

Returns a list of the configuration archives present on the system.  the list is returned as a hash
with the name of the configuration archive as the key, and the creation date of the configuration 
archive as the value.

The creation date uses the native date format of:

	Day Mon D HH:MM:SS YYYY

Where B<Day> is the three-letter common abbreviation of the day name, B<Mon> is the three letter common
abbreviation of the month name and B<D> has the value range 1-31 with no leading zeros.

=cut

sub get_configuration_list {
	my $self	= shift;
	my %res;

	foreach (@{$self->_request(module => 'System', interface => 'ConfigSync', method => 'get_configuration_list')}) {
		$res{$_->{file_name}}	= $_->{file_datetime}
	}

	return %res;
}

=head3 delete_configuration ()

	$ic->delete_configuration('file.ucs');

Deletes the specified configuration archive from the system.

=cut

sub delete_configuration {
	my ($self,$filename)	= @_;
	$filename or croak 'No filename specified';
	return $self->_request(module => 'System', interface => 'ConfigSync', method => 'delete_configuration', data => { filename => $filename });
}

sub _download_file {
	my ($self,$config_name,$local_file)	= @_;
	my $chunk	= 65536;
	my $offset	= 0;
	my $data;

	$config_name or croak 'No configuration file specified';

	open my $fh, '+>', $local_file or croak "Unable to open local file: $local_file";
	binmode($fh);

	while (1) {
		$data	= $self->_request(module => 'System', interface => 'ConfigSync', method => 'download_configuration', data => {config_name => $config_name, chunk_size => $chunk, file_offset => $offset});
		print $fh $data->{file_data};
		last if (($data->{chain_type} eq 'FILE_LAST') or ($data->{chain_type} eq 'FILE_FIRST_AND_LAST'));
		$offset+=(length($data->{file_data}));		
	}

	close $fh;
	return 1	
}

=head3 download_file ( $FILE )

	# Print the bigip.conf file to the terminal
	print $ic->download_file('/config/bigip.conf');

This method provides direct access to files on the target system. The method returns a scalar containing
the contents of the file.

This method may be useful for downloading configuration files for versioning or backups.

=cut

sub download_file {
	my ($self,$file_name)	= @_;
	my $chunk	= 65536;
	my $offset	= 0;
	my ($data, $output);

	$file_name or croak 'No file name specified';

	while (1) {
		$data	= $self->_request(module => 'System', interface => 'ConfigSync', method => 'download_file', data => {file_name => $file_name, chunk_size => $chunk, file_offset => $offset});
		$output .=$data->{file_data};
		last if (($data->{chain_type} eq 'FILE_LAST') or ($data->{chain_type} eq 'FILE_FIRST_AND_LAST'));
		$offset+=(length($data->{file_data}));		
	}

	return $output	
}

=head3 get_interface_list ()

	my @interfaces = $ic->get_interface_list();

Retuns an ordered list of all interfaces on the target device.

=cut

sub get_interface_list {
	return sort @{$_[0]->_request(module => 'Networking', interface => 'Interfaces', method => 'get_list')};
}

=head3 get_interface_enabled_state ($interface)

Returns the enabled state of the specific interface.

=cut

sub get_interface_enabled_state {
	my ($self, $inet)=@_;
	return @{$self->_request(module => 'Networking', interface => 'Interfaces', method => 'get_enabled_state', data => { interfaces => [$inet] })}[0]
}

=head3 get_interface_media_status ($interface)

Returns the media status of the specific interface.

=cut

sub get_interface_media_status {
	my ($self, $inet)=@_;
	return @{$self->_request(module => 'Networking', interface => 'Interfaces', method => 'get_media_status', data => { interfaces => [$inet] })}[0]
}

=head3 get_interface_media_speed ($interface)

Returns the media speed of the specific interface in Mbps.

=cut

sub get_interface_media_speed {
	my ($self, $inet)=@_;
	return @{$self->_request(module => 'Networking', interface => 'Interfaces', method => 'get_media_speed', data => { interfaces => [$inet] })}[0]
}

=head3 get_interface_statistics ($interface)

Returns all statistics for the specified interface as a InterfaceStatistics object.  Unless you specifically
require access to the raw object, consider using B<get_interface_statistics_stringified> for a pre-parsed hash 
in an easy-to-digest format.

=cut

sub get_interface_statistics {
	my ($self, $inet)=@_;
	return $self->_request(module => 'Networking', interface => 'Interfaces', method => 'get_statistics', data => { interfaces => [$inet] })
}

=head3 get_interface_statistics_stringified ($interface)

	my $inet	= ($ic->get_interface_list())[0];
	my %stats       = $ic->get_interface_statistics_stringified($inet);

	print "Interface: $inet - Bytes in: $stats{stats}{STATISTIC_BYTES_IN} - Bytes out: STATISTIC_BYTES_OUT";

Returns all statistics for the specified interface as a hash having the following structure;

	{
	timestamp	=> 'YYYY-MM-DD-hh-mm-ss',
	stats		=>	{
				statistic_1	=> value
				...
				statistic_n	=> value
				}
	}

Where the keys of the stats hash are the names of the statistic types defined in a InterfaceStatistics object.
Refer to the official API documentation for the exact structure of the InterfaceStatistics object.

=cut

sub get_interface_statistics_stringified {
	my ($self, $inet)=@_;
	return __process_statistics($self->get_interface_statistics($inet))
}

=head3 get_trunk_list ()

	my @trunks = $ic->get_trunk_list();

Returns an array of the configured trunks present on the device.

=cut

sub get_trunk_list {
	return @{$_[0]->_request(module => 'Networking', interface => 'Trunk', method => 'get_list')};
}

=head3 get_active_trunk_members ()

	print "Trunk $t has " . $ic->get_active_trunk_members() . " active members.\n";

Returns the number of the active members for the specified trunk.

=cut

sub get_active_trunk_members {
	my ($self, $trunk) = @_;
	return @{$_[0]->_request(module => 'Networking', interface => 'Trunk', method => 'get_operational_member_count', data => { trunks => [ $trunk ] })}[0]
}

=head3 get_configured_trunk_members ()

	print "Trunk $t has " . $ic->get_configured_trunk_members() . " configured members.\n";

Returns the number of configured members for the specified trunk.

=cut

sub get_configured_trunk_members {
	my ($self, $trunk) = @_;
	return @{$_[0]->_request(module => 'Networking', interface => 'Trunk', method => 'get_configured_member_count', data => { trunks => [ $trunk ] })}[0]
}

=head3 get_trunk_interfaces ()

	my @t_inets = $ic->get_trunk_interfaces();

Returns an array containing the interfaces of the members of the specified trunk.

=cut

sub get_trunk_interfaces {
	my ($self, $trunk) = @_;
	return @{@{$_[0]->_request(module => 'Networking', interface => 'Trunk', method => 'get_interface', data => { trunks => [ $trunk ] })}[0]}
}

=head3 get_trunk_media_speed ()

	print "Trunk $t operating at " . $ic->get_trunk_media_speed($t) . "Mbps\n";

Returns the current operational media speed (in Mbps) of the specified trunk.

=cut

sub get_trunk_media_speed {
	my ($self, $trunk) = @_;
	return @{$_[0]->_request(module => 'Networking', interface => 'Trunk', method => 'get_media_speed', data => { trunks => [ $trunk ] })}[0]
}

=head3 get_trunk_media_status ()

	print "Trunk $t media status is " . $ic->get_trunk_media_status($t) . "\n";

Returns the current operational media status of the specified trunk.

=cut

sub get_trunk_media_status {
	my ($self, $trunk) = @_;
	return @{$_[0]->_request(module => 'Networking', interface => 'Trunk', method => 'get_media_status', data => { trunks => [ $trunk ] })}[0]
}

=head3 get_trunk_lacp_enabled_state ()

Returns the enabled state of LACP for the specified trunk.

=cut

sub get_trunk_lacp_enabled_state {
	my ($self, $trunk) = @_;
	return @{$_[0]->_request(module => 'Networking', interface => 'Trunk', method => 'get_lacp_enabled_state', data => { trunks => [ $trunk ] })}[0]
}

=head3 get_trunk_lacp_active_state ()

Returns the active state of LACP for the specified trunk.

=cut

sub get_trunk_lacp_active_state {
	my ($self, $trunk) = @_;
	return @{$_[0]->_request(module => 'Networking', interface => 'Trunk', method => 'get_active_lacp_state', data => { trunks => [ $trunk ] })}[0]
}

=head3 get_trunk_statistics ()

Returns the traffic statistics for the specified trunk.  The statistics are returned as a TrunkStatistics object
hence this method is useful where access to raw statistical data is required.

For parsed statistic data, see B<get_trunk_statistics_stringified>.

For specific information regarding data and units of measurement for statistics methods, please see the B<Notes> section.

=cut

sub get_trunk_statistics {
	my ($self, $trunk) = @_;
	return $self->_request(module => 'Networking', interface => 'Trunk', method => 'get_statistics', data => { trunks => [ $trunk ] })
}

=head3 get_trunk_statistics_stringified ()

Returns all statistics for the specified trunk as a hash of hases with the following structure:

	{	
		timestamp	=> 'yyyy-mm-dd-hh-mm-ss',
		stats		=> {
					stats_1	=> value,
					stats_3	=> value,
					...
					stats_n	=> value
				}
	}
					
This function accepts a single parameter; the trunk for which the statistics are to be returned.

For specific information regarding data and units of measurement for statistics methods, please see the B<Notes> section.

=cut

sub get_trunk_statistics_stringified {
	my ($self, $trunk) = @_;
	return __process_statistics($self->get_trunk_statistics($trunk))
}

=head3 get_self_ip_list

Returns a list of all self IP addresses on the target device.

=cut

sub get_self_ip_list {
	return @{$_[0]->_request(module => 'Networking', interface => 'SelfIP', method => 'get_list')}
}

=head3 get_self_ip_vlan ( $SELF_IP )

Returns the VLAN associated with the specified self IP address on the target device.

=cut

sub get_self_ip_vlan {
	my ($self, $ip) = @_;
	return @{$self->_request(module => 'Networking', interface => 'SelfIP', method => 'get_vlan', data => { self_ips => [ $ip ] })}[0]
}

=head3 get_vs_list ()

	my @virtuals	= $ic->get_vs_list();

B<Please note>: this method has been deprecated in future releases.  Please use get_ltm_vs_list instead.

Returns an array of all defined LTM virtual servers.

=cut

sub get_vs_list {
	return $_[0]->get_ltm_vs_list()
}

=head3 get_ltm_vs_list ()

	my @ltm_virtuals = $ic->get_ltm_vs_list();

Returns an array of all defined LTM virtual servers.

=cut

sub get_ltm_vs_list {
	return @{$_[0]->_request(module => 'LocalLB', interface => 'VirtualServer', method => 'get_list')};
}

=head3 get_gtm_vs_list ()

	my @gtm_virtuals = $ic->get_gtm_vs_list();

Returns an array of the names of all defined GTM virtual servers.

=cut

sub get_gtm_vs_list {
	my @members;
	foreach (@{$_[0]->_request(module => 'GlobalLB', interface => 'VirtualServer', method => 'get_list')}) {
		push @members, $_->{name}
	}
	return @members
}


=head3 get_vs_destination ($virtual_server)

	my $destination	= $ic->get_vs_destination($vs);

Returns the destination of the specified virtual server in the form ipv4_address%route_domain:port.

=cut

sub get_vs_destination {
	my ($self, $vs)	= @_;
	my $destination	= @{$self->_request(module => 'LocalLB', interface => 'VirtualServer', method => 'get_destination', data => {virtual_servers => [$vs]})}[0];
	return $destination->{address}.':'.$destination->{port}
}

=head3 get_vs_enabled_state ($virtual_server)

	print "LTM Virtual server $vs is in state ",$ic->get_vs_enabled_state($vs),"\n";

B<Please note>: this method has been deprecated in future releases.  Please use the B<get_ltm_vs_enabled_state()> instead.

Return the enabled state of the specified LTM virtual server.

=cut

sub get_vs_enabled_state {
	my ($self, $vs)	= @_;
	return $self->get_ltm_vs_enabled_state($vs)
}

=head3 get_ltm_vs_enabled_state ($virtual_server)

	print "LTM Virtual server $vs is in state ",$ic->get_ltm_vs_enabled_state($vs),"\n";

Return the enabled state of the specified LTM virtual server.

=cut

sub get_ltm_vs_enabled_state {
	my ($self, $vs)	= @_;
	return @{$self->_request(module => 'LocalLB', interface => 'VirtualServer', method => 'get_enabled_state', data => {virtual_servers => [$vs]})}[0];
}

=head3 get_gtm_vs_enabled_state ($virtual_server)

	print "GTM Virtual server $vs is in state ",$ic->get_gtm_vs_enabled_state($vs),"\n";

Return the enabled state of the specified GTM virtual server.  The GTM server should be provided as a name only such as that
returned from the B<get_gtm_vs_list> method.

=cut

sub get_gtm_vs_enabled_state {
	my ($self, $vs)	= @_;
	my %def	= $self->__get_gtm_vs_definition($vs);
	return @{$self->_request(module => 'GlobalLB', interface => 'VirtualServer', method => 'get_enabled_state', data => {virtual_servers => [{%def}]})}[0];
}

=head3 get_vs_all_statistics ()

B<Please Note>: This method has been deprecated in future releases.  Please use B<get_ltm_vs_all_statistics>.

Returns the traffic statistics for all configured LTM virtual servers.  The statistics are returned as 
VirtualServerStatistics struct hence this method is useful where access to raw statistical data is required.

For parsed statistic data, see B<get_ltm_vs_statistics_stringified>.

For specific information regarding data and units of measurement for statistics methods, please see the B<Notes> section.

=cut

sub get_vs_all_statistics {
	return $_[0]->get_ltm_vs_all_statistics()
	#return $self->_request(module => 'LocalLB', interface => 'VirtualServer', method => 'get_all_statistics');
}

=head3 get_ltm_vs_all_statistics ()

Returns the traffic statistics for all configured LTM virtual servers.  The statistics are returned as 
VirtualServerStatistics struct hence this method is useful where access to raw statistical data is required.

For parsed statistic data, see B<get_ltm_vs_statistics_stringified>.

For specific information regarding data and units of measurement for statistics methods, please see the B<Notes> section.

=cut

sub get_ltm_vs_all_statistics {
	return $_[0]->_request(module => 'LocalLB', interface => 'VirtualServer', method => 'get_all_statistics');
}

=head3 get_vs_statistics ($virtual_server)

	my $statistics = $ic->get_vs_statistics($vs);

Returns all statistics for the specified virtual server as a VirtualServerStatistics object.  Consider using get_vs_statistics_stringified
for accessing virtual server statistics in a pre-parsed hash structure.	

For specific information regarding data and units of measurement for statistics methods, please see the B<Notes> section.

=cut

sub get_vs_statistics {
	my ($self, $vs)	= @_;
	return $self->_request(module => 'LocalLB', interface => 'VirtualServer', method => 'get_statistics', data => {virtual_servers => [$vs]});
}

=head3 get_vs_statistics_stringified ($virtual_server)

	my $statistics = $ic->get_vs_statistics_stringified($vs);

	foreach (sort keys %{$stats{stats}}) {
		print "$_: $stats{stats}{$_}\n";
	}

Returns all statistics for the specified virtual server as a multidimensional hash (hash of hashes).  The hash has the following structure:

	{
		timestamp	=> 'yyyy-mm-dd-hh-mm-ss',
		stats		=> {
					statistic_1	=> value,
					statistic_2	=> value,
					...
					statistic_n	=> value
				}
	}

This function accepts a single parameter; the virtual server for which the statistics are to be returned.

For specific information regarding data and units of measurement for statistics methods, please see the B<Notes> section.

=cut

sub get_vs_statistics_stringified {
	my ($self, $vs)	= @_;
	return __process_statistics($self->get_vs_statistics($vs));
}

=head3 get_ltm_vs_rules ($virtual_server)

=cut

sub get_ltm_vs_rules {
	my ($self, $vs) = @_;
	return	map	{ $_->[1] } 
		sort	{ $a->[0] <=> $b->[0] } 
		map	{ [ $_->{priority}, $_->{rule_name} ] }
		@{@{$self->_request(module => 'LocalLB', interface => 'VirtualServer', method => 'get_rule', data => {virtual_servers => [$vs]})}[0]}
}

=head3 get_ltm_snat_pool ($virtual_server)

=cut

sub get_ltm_snat_pool {
	my($self, $vs) = @_;
	return @{$self->_request(module => 'LocalLB', interface => 'VirtualServer', method => 'get_snat_pool', data => {virtual_servers => [$vs]})}[0]
}

=head3 get_ltm_snat_type ($virtual_server)

=cut

sub get_ltm_snat_type {
	my($self, $vs) = @_;
	return @{$self->_request(module => 'LocalLB', interface => 'VirtualServer', method => 'get_snat_type', data => {virtual_servers => [$vs]})}[0]
}

=head3 get_default_pool_name ($virtual_server)

	print "Virtual Server: $virtual_server\nDefault Pool: ", 
		$ic->get_default_pool_name($virtual_server), "\n";

Returns the default pool names for the specified virtual server.

=cut

sub get_default_pool_name {
	my ($self, $vs)=@_;
	return @{$self->_request(module => 'LocalLB', interface => 'VirtualServer', method => 'get_default_pool_name', data => {virtual_servers => [$vs]})}[0]
}

=head3 get_pool_list ()

	print join " ", ($ic->get_pool_list());

Returns a list of all LTM pools in the target system.

Note that this method has been deprecated in future releases - please use B<get_ltm_vs_list> instead.

=cut

sub get_pool_list {
	return $_[0]->get_ltm_pool_list()
	#return @{$_[0]->_request(module => 'LocalLB', interface => 'Pool', method => 'get_list')};
}

=head3 get_ltm_pool_list ()

	print join " ", ($ic->get_ltm_pool_list());

Returns a list of all LTM pools in the target system.

=cut

sub get_ltm_pool_list {
	return @{$_[0]->_request(module => 'LocalLB', interface => 'Pool', method => 'get_list')};
}


=head3 get_pool_members ($pool)

	foreach my $pool ($ic->get_pool_list()) {
		print "\n\n$pool:\n";

		foreach my $member ($ic->get_pool_members($pool)) {
			print "\t$member\n";
		}
	}

B<Please note>: this method has been deprecated in future releases.  Please use the B<get_ltm_pool_members> method instead.

Returns a list of the pool members for the specified LTM pool.  This method takes one mandatory parameter; the name of the pool.

Pool member are returned in the format B<IP_address:service_port>.

=cut 

sub get_pool_members {
	my ($self, $pool)=@_;
	return $self->get_ltm_pool_members($pool)
	#my ($self, $pool)= @_;
	#my @members;
	#foreach (@{@{$self->__get_pool_members($pool,$module)}[0]}) {push @members, ($_->{address}.':'.$_->{port})}
	#return @members;
}

=head3 get_ltm_pool_members ($pool)

	foreach my $pool ($ic->get_ltm_pool_list()) {
		print "\n\n$pool:\n";

		foreach my $member ($ic->get_ltm_pool_members($pool)) {
			print "\t$member\n";
		}
	}

Returns a list of the pool members for the specified LTM pool.  This method takes one mandatory parameter; the name of the pool.

Pool member are returned in the format B<IP_address:service_port>.

=cut 

sub get_ltm_pool_members {
	my ($self, $pool)= @_;
	my @members;
	foreach (@{@{$self->__get_pool_members($pool,'LocalLB')}[0]}) {push @members, ($_->{address}.':'.$_->{port})}
	return @members;
}

=head3 get_gtm_pool_members ($pool)

Returns a list of the pool members for the specified GTM pool.  This method takes one mandatory parameter; the name of the pool.

Pool member are returned in the format B<IP_address:service_port>.

=cut 

sub get_gtm_pool_members {
	my ($self,$pool)=@_;
	my @members;
	foreach (@{@{$self->__get_pool_members($pool,'GlobalLB')}[0]}) {push @members, $_->{member}->{address}.':'.$_->{member}->{port}}
	return @members
}

sub __get_pool_members {
	my ($self, $pool, $module)= @_;
	return $self->_request(module => $module, interface => 'Pool', method => 'get_member', data => {pool_names => [$pool]});
}

=head3 get_pool_statistics ($pool)

	my %stats = $ic->get_pool_statistics($pool);

Returns the statistics for the specified pool as a PoolStatistics object.  For pre-parsed pool statistics consider using
the B<get_pool_statistics_stringified> method.

=cut

sub get_pool_statistics {
	my ($self, $pool)= @_;
	return $self->_request(module => 'LocalLB', interface => 'Pool', method => 'get_statistics', data => {pool_names => [$pool]});
}

=head3 get_pool_statistics_stringified ($pool)

	my %stats = $ic->get_pool_statistics_stringified($pool);
	print "Pool $pool bytes in: $stats{stat}{STATISTIC_SERVER_SIDE_BYTES_OUT}";

Returns a hash containing all pool statistics for the specified pool in a delicious, easily digestable and improved formula.

=cut

sub get_pool_statistics_stringified {
	my ($self, $pool)= @_;
	return __process_statistics($self->get_pool_statistics($pool));
}

=head3 get_pool_member_statistics ($pool)

Returns all pool member statistics for the specified pool as an array of MemberStatistics objects.  Unless you feel like 
playing with Data::Dumper on a rainy Sunday afternoon, consider using B<get_pool_member_statistics_stringified> method.

=cut

sub get_pool_member_statistics {
	my ($self, $pool)= @_;
	
	return $self->_request(module => 'LocalLB', interface => 'PoolMember', method => 'get_statistics', data => {
		pool_names	=> [$pool],
		members		=> $self->__get_pool_members($pool,'LocalLB') });
}

=head3 get_pool_member_object_status ($pool)

Returns all pool member stati for the specified pool as an array of MemberObjectStatus objects.

=cut

sub get_pool_member_object_status {
    my ($self, $pool) = @_; 

    return $self->_request(module => 'LocalLB', interface => 'PoolMember', method => 'get_object_status', data => {
        pool_names  => [$pool],
    }); 
}


=head3 get_pool_member_statistics_stringified ($pool)

	my %stats = $ic->get_pool_member_statistics_stringified($pool);

	print "Member\t\t\t\tRequests\n",'-'x5,"\t\t\t\t",'-'x5,"\n";
	
	foreach my $member (sort keys %stats) {
		print "$member\t\t$stats{$member}{stats}{STATISTIC_TOTAL_REQUESTS}\n";
	}

	# Prints a list of requests per pool member

Returns a hash containing all pool member statistics for the specified pool.  The hash has the following
structure;

	member_1 =>	{
			timestamp	=> 'YYYY-MM-DD-hh-mm-ss',
			stats		=>	{
						statistics_1	=> value
						...
						statistic_n	=> value
						}
			}
	member_2 =>	{
			...
			}
	member_n =>	{
			...
			}

Each pool member is specified in the form ipv4_address%route_domain:port.

=cut

sub get_pool_member_statistics_stringified {
	my ($self, $pool)= @_;
	return __process_pool_member_statistics($self->get_pool_member_statistics($pool))
}

=head3 get_all_pool_member_statistics ($pool)

Returns all pool member statistics for the specified pool.  This method is analogous to the B<get_pool_member_statistics()>
method and the two will likely be merged in a future release.

=cut

sub get_all_pool_member_statistics {
	my ($self, $pool)= @_;
	return $self->_request(module => 'LocalLB', interface => 'PoolMember', method => 'get_all_statistics', data => {pool_names => [$pool]});
}

=head3 get_ltm_pool_status ($pool)

Returns the status of the specified pool as a ObjectStatus object.

For formatted pool status information, see the B<get_ltm_pool_status_as_string()> method.

=cut 

sub get_ltm_pool_status {
	my ($self, $pool)= @_;
	return @{$self->_request(module => 'LocalLB', interface => 'Pool', method => 'get_object_status', data => {pool_names => [$pool]})}[0]
}

=head3 get_ltm_pool_member_status ($pool, $member)

Returns the status of the specified member in the specified pool as a ObjectStatus object.

=cut

sub get_ltm_pool_member_status {
    my ($self, $pool, $member) = @_; 
    return @{$self->_request(module => 'LocalLB', interface => 'Pool', method => 'get_member_object_status', data => {
        pool_names => [$pool],
        members => [$member],
    })}[0];
}

=head3 get_ltm_pool_availability_status ($pool)

Retuns the availability status of the specified pool.

=cut 

sub get_ltm_pool_availability_status {
	my ($self, $pool)= @_;
	return $self->get_ltm_pool_status_as_string($pool,'availability_status');
}

=head3 get_ltm_pool_enabled_status ($pool)

Retuns the enabled status of the specified pool.

=cut 

sub get_ltm_pool_enabled_status {
	my ($self, $pool)= @_;
	return $self->get_ltm_pool_status_as_string($pool,'enabled_status');
}

=head3 get_ltm_pool_status_description ($pool)

Returns a descriptive status of the specified pool.

=cut 

sub get_ltm_pool_status_description {
	my ($self, $pool)= @_;
	return $self->get_ltm_pool_status_as_string($pool,'status_description');
}

=head3 get_ltm_pool_status_as_string ($pool)

Returns the pool status as a descriptive string.

=cut 

sub get_ltm_pool_status_as_string {
	my ($self, $pool, $status_key)= @_;
	
	$status_key or ($status_key = 'status_description');
	
	return $self->get_ltm_pool_status($pool)->{$status_key};
}

sub _get_ltm_pool_member_oject_status {
	my ($self, $pool)
}

=head3 get_connection_list ()

Returns a list of active connections as a list of ConnectionID objects.

=cut

sub get_connection_list {
	return $_[0]->_request(module => 'System', interface => 'Connections', method => 'get_list');
}

=head3 get_all_active_connections ()

Gets all active connections in details on the device.

=cut

sub get_all_active_connections {
	return $_[0]->_request(module => 'System', interface => 'Connections', method => 'get_all_active_connections');
}

=head3 get_active_connections_count()

Returns the number of all active connections on the device.

=cut

sub get_active_connections_count {
	return scalar @{$_[0]->get_all_active_connections()}
}

=head3 get_node_list ()

	print join "\n", ($ic->get_node_list());

Returns a list of all configured nodes in the target system.

Nodes are returned as ipv4 addresses.

=cut 

sub get_node_list {
	return @{$_[0]->_request(module => 'LocalLB', interface => 'NodeAddress', method => 'get_list')}
}

=head3 get_screen_name ($node)

	foreach ($ic->get_node_list()) {
		print "Node: $_ (" . $ic->get_screen_name($_) . ")\n";
	}

Retuns the screen name of the specified node.

=cut 

sub get_screen_name {
	my ($self, $node)= @_;
	return @{$self->_request(module => 'LocalLB', interface => 'NodeAddress', method => 'get_screen_name', data => {node_addresses => [$node]})}[0]
}

=head3 get_node_status ($node)

	$ic->get_node_status(

Returns the status of the specified node as a ObjectStatus object.

For formatted node status information, see the B<get_node_status_as_string()> method.

=cut 

sub get_node_status {
	my ($self, $node)= @_;
	return @{$self->_request(module => 'LocalLB', interface => 'NodeAddress', method => 'get_object_status', data => {node_addresses => [$node]})}[0]
}

=head3 get_node_availability_status ($node)

Retuns the availability status of the node.

=cut 

sub get_node_availability_status {
	my ($self, $node)= @_;
	return $self->get_node_status_as_string($node,'availability_status');
}

=head3 get_node_enabled_status ($node)

Retuns the enabled status of the node.

=cut 

sub get_node_enabled_status {
	my ($self, $node)= @_;
	return $self->get_node_status_as_string($node,'enabled_status');
}

=head3 get_node_status_description ($node)

Returns a descriptive status of the specified node.

=cut 

sub get_node_status_description {
	my ($self, $node)= @_;
	return $self->get_node_status_as_string($node,'status_description');
}

=head3 get_node_status_as_string ($node)

Returns the node status as a descriptive string.

=cut 

sub get_node_status_as_string {
	my ($self, $node, $status_key)= @_;
	
	$status_key or ($status_key = 'status_description');
	
	return $self->get_node_status($node)->{$status_key};
}

=head3 get_node_monitor_status ($node)

Gets the current availability status of the specified node addresses. 

=cut 

sub get_node_monitor_status {
	my ($self, $node)= @_;
	return @{$self->_request(module => 'LocalLB', interface => 'NodeAddress', method => 'get_monitor_status', data => {node_addresses => [$node]})}[0];
}

=head3 get_node_statistics ($node)

Returns all statistics for the specified node.

=cut 

sub get_node_statistics {
	my ($self, $node)= @_;
	return $self->_request(module =>'LocalLB', interface => 'NodeAddress', method => 'get_statistics', data => {node_addresses => [$node]})
}

=head3 get_node_statistics_stringified

	my %stats = $ltm->get_node_statistics_stringified($node);

	foreach (sort keys %{stats{stats}}) {
		print "$_:\t$stats{stats}{$_}{high}\t$stats{stats}{$_}{low}\n";
	}

Returns a multidimensional hash containing all current statistics for the specified node.  The hash has the following structure:

	{
		timestamp	=> 'yyyy-mm-dd-hh-mm-ss',
		stats		=> {
					statistic_1	=> value,
					statistic_2	=> value,
					...
					statistic_n	=> value
				}
	}

This function accepts a single parameter; the node for which the statistics are to be returned.

For specific information regarding data and units of measurement for statistics methods, please see the B<Notes> section.

=cut

sub get_node_statistics_stringified {
	my ($self, $node)= @_;
	return __process_statistics($self->get_node_statistics($node));
}

=head3 get_gtm_pool_list ()

Returns a list of GTM pools.

=cut

sub get_gtm_pool_list {
	return @{$_[0]->_request(module => 'GlobalLB', interface => 'Pool', method => 'get_list')}
}

=head3 get_gtm_pool_description ()

Returns a description of the specified GTM pool.

=cut

sub get_gtm_pool_description {
	my ($self, $pool)=@_;
	return @{$self->_request(module => 'GlobalLB', interface => 'Pool', method => 'get_description', data => {pool_names => [$pool]})}[0];
}

=head3 get_gtm_vs_all_statistics ()

Returns the traffic statistics for all configured GTM virtual servers.  The statistics are returned as 
VirtualServerStatistics struct hence this method is useful where access to raw statistical data is required.

For parsed statistic data, see B<get_gtm_vs_statistics_stringified>.

For specific information regarding data and units of measurement for statistics methods, please see the B<Notes> section.

=cut

sub get_gtm_vs_all_statistics {
	return $_[0]->_request(module => 'GlobalLB', interface => 'VirtualServer', method => 'get_all_statistics');
}

sub __get_gtm_vs_definition {
	my ($self, $vs)=@_;
	foreach (@{$self->_request(module => 'GlobalLB', interface => 'VirtualServer', method => 'get_list')}) {
		return %{$_} if ($_->{name} eq $vs)
	}
}

=head3 get_ltm_address_class_list ()

Returns a list of all existing address classes.

=cut

sub get_ltm_address_class_list {
        return @{ $_[0]->_request(module => 'LocalLB', interface => 'Class', method => 'get_address_class_list') }
}

=head3 get_ltm_string_class_list ()

Returns a list of all existing string classes.

=cut

sub get_ltm_string_class_list {
        return @{ $_[0]->_request(module => 'LocalLB', interface => 'Class', method => 'get_string_class_list') }
}

=head3 get_ltm_string_class ( $class_name )

Return the specified LTM string class.

=cut

sub get_ltm_string_class {
	my ( $self, $class ) = @_;
        return @{ $self->_request(module => 'LocalLB', interface => 'Class', method => 'get_string_class', data => { class_names => [ $class ] } ) }[0]->{members}
}

=head3 get_ltm_string_class_members ( $class )

Returns the specified LTM string class members.

=cut

sub get_ltm_string_class_members {
	my ( $self, $class ) = @_;
	return $self->_request( module => 'LocalLB', interface => 'Class', method => 'get_string_class_member_data_value', data => { class_members => 
        			[ @{ $self->_request(module => 'LocalLB', interface => 'Class', method => 'get_string_class', data => { class_names => [ $class ] } ) }[0] ] } )
}

=head3 add_ltm_string_class_member ( $class, $member )

Add the provided member to the specified class.

=cut

sub add_ltm_string_class_member {
	my ( $self, $class, $member ) = @_;
	$self->_request(	module		=> 'LocalLB',
				interface	=> 'Class',
				method		=> 'add_string_class_member',
				data		=> {
						class_members	=> [
								     {
								   	name	=> $class,
									members => [ $member ]
								     }
								]
						}
			)
}

=head3 delete_ltm_string_class_member ( $class, $member )

Deletes the provided member from the specified class.

=cut

sub delete_ltm_string_class_member {
	my ( $self, $class, $member ) = @_;
	$self->_request(	module		=> 'LocalLB',
				interface	=> 'Class',
				method		=> 'delete_string_class_member',
				data		=> {
						class_members	=> [
								     {
								   	name	=> $class,
									members => [ $member ]
								     }
								]
						}
			)
}

=head3 set_ltm_string_class_member ( $class, $member, value )

Sets the value of the member to the provided value in the specified class.

=cut

sub set_ltm_string_class_member {
	my ( $self, $class, $member, $value ) =	@_;
	$self->_request(	module 		=> 'LocalLB', 
				interface	=> 'Class', 
				method		=> 'set_string_class_member_data_value', 
				data 		=> {
						class_members	=> [ 
								     { 
									name	=> $class, 
									members => [ $member ] 
								     } 
								   ], 
						values		=> [ 
									[ $value ] 
								   ] 
						} 
			)
}

=head3 get_db_variable ( $VARIABLE )

	# Prints the value of the configsync.state database variable.
	print "Config state is " . $ic->get_db_variable('configsync.state') . "\n";

Returns the value of the specified db variable.

=cut

sub get_db_variable {
	my ($self,$var)	= @_;
	return @{$self->_request(module => 'Management', interface => 'DBVariable', method => 'query', data => { variables => [$var] })}[0]->{value}
}

=head3 get_event_subscription_list

Returns an array of event subscription IDs for all registered event subscriptions.

=cut 

sub get_event_subscription_list {
	my ($self, %args)=@_;
	return $self->_request(module => 'Management', interface => 'EventSubscription', method => 'get_list');
}

=head3 get_event_subscription

=cut

sub get_event_subscription {
	my ($self, $id)=@_;
	return $self->_request(module => 'Management', interface => 'EventSubscription', method => 'query', data => { id_list => [$id] })
}

=head3 remove_event_subscription

=cut

sub remove_event_subscription {
	my ($self, $id)=@_;
	return $self->_request(module => 'Management', interface => 'EventSubscription', method => 'remove', data => { id_list => [$id] })
}

=head3 get_event_subscription_state

=cut

sub _get_event_subscription_state {
	my ($self,$id)	= @_;
	return @{$self->_request(module => 'Management', interface => 'EventSubscription', method => 'get_state', data => { id_list => [$id] })}[0]
}

=head3 get_event_subscription_url

=cut

sub get_event_subscription_url {
	my ($self,$id)	= @_;
	return @{$self->_request(module => 'Management', interface => 'EventSubscription', method => 'get_url', data => { id_list => [$id] })}[0]
}

sub _get_event_subscription_proxy_url {
	my ($self,$id)	= @_;
	return @{$self->_request(module => 'Management', interface => 'EventSubscription', method => 'get_proxy_url', data => { id_list => [$id] })}[0]
}

sub _get_event_subscription_authentication {
	my ($self,$id)	= @_;
	return @{$self->_request(module => 'Management', interface => 'EventSubscription', method => 'get_proxy_url', data => { id_list => [$id] })}[0]
}

sub get_subscription_list {
	my $self	= shift;
	my @subs;
	foreach (@{$self->_request(module => 'Management', interface => 'EventSubscription', method => 'get_list')}){push @subs, $_}
	return @subs
}

=head3 get_subscription_list

This method is an analog of B<get_event_subscription>

=cut 

=head3 create_subscription_list (%args)

        my $subscription = $ic->create_subscription_list (
                                                name                            => 'my_subscription_name',
                                                url                             => 'http://company.com/my/eventnotification/endpoint,
                                                username                        => 'username',
                                                password                        => 'password',
                                                ttl                             => -1,
                                                min_events_per_timeslice        => 10,
                                                max_timeslice                   => 10
                                        );   

Creates an event subscription with the target system.  This method requires the following parameters:

=over 3

=item name 

A user-friendly name for the subscription.

=item url

The target URL endpoint for the event notification interface to send event notifications.

=item username

The basic authentication username required to access the URL endpoint.

=item password

The basic authentication password required to access the URL endpoint.

=item ttl

The time to live (in seconds) for this subscription. After the ttl is reached, the subscription
will be removed from the system. A value of -1 indicates an infinite life time.

=item min_events_per_timeslice

The minimum number of events needed to trigger a notification. If this value is 50, then this
means that when 50 events are queued up they will be sent to the notification endpoint no matter
what the max_timeslice is set to.

=item max_timeslice

This maximum time to wait (in seconds) before event notifications are sent to the notification
endpoint. If this value is 30, then after 30 seconds a notification will be sent with the events
in the subscription queue.

=back

=cut

sub create_subscription_list {
	my ($self, %args)=@_;
	$args{name}					or return 'Request error: missing "name" parameter';
	$args{url}					or return 'Request error: missing "url" parameter';	
	#$args{username}					or return 'Request error: missing "username" parameter';	
	#$args{password}					or return 'Request error: missing "password" parameter';	
	$args{ttl} =~ /^(-)?\d+$/			or return 'Request error: missing or incorrect "ttl" parameter';	
	$args{min_events_per_timeslice} =~ /^(-)?\d+$/	or return 'Request error: missing or incorrect "min_events_per_timeslice" parameter';	
	$args{max_timeslice} =~ /^(-)?\d+$/		or return 'Request error: missing or incorrect "max_timeslice" parameter';	
	@{$args{event_type}} > 0			or return 'Request error: missing "event_type" parameter';

	foreach my $event (@{$args{event_type}}) {
		exists $event_types->{$event}		or return "Request error: unknown \"event_type\" parameter \"$event\"";
	}

	my $sub_detail_list= {
				name				=> $args{name},
				event_type_list			=> [@{$args{event_type}}],
				url				=> $args{url},
				url_credentials			=> {
									auth_mode	=> 'AUTHMODE_NONE',
									#username	=> $args{username},
									#password	=> $args{password}
								},
				ttl				=> $args{ttl},
				min_events_per_timeslice	=> $args{min_events_per_timeslice},
				max_timeslice			=> $args{max_timeslice},
				enabled_state			=> 'STATE_ENABLED'
			};
	return $self->_request(module => 'Management', interface => 'EventSubscription', method => 'create', data => {sub_detail_list => [$sub_detail_list]});
}

=head1 NOTES

=head3 Statistic Methods

Within iControl, statistical values are a 64-bit unsigned integer represented as a B<Common::ULong64> object.
The ULong64 object is a stuct of two 32-bit values.  This representation is used as there is no native 
support for the encoding of 64-bit numbers in SOAP.

The ULong object has the following structure;

	({
		STATISTIC_NAME	=> {
				high	=> long
				low	=> long
			}
	}, bless Common::ULong64)

Where high is the unsigned 32-bit integer value of the high-order portion of the measured value and low is 
the unsigned 32-bit integer value of the low-order portion of the measured value.

In non-stringified statistic methods, these return values are ULong64 objects as returned by the iControl API.
In stringified statistic method calls, the values are processed on the client side into a local 64-bit representation
of the value using the following form.

	$value = ($high<<32)|$low;

Stringified method calls are guaranteed to return a correct localised 64-bit representation of the value.

It is the callers responsibility to convert the ULong struct for all other non-stringified statistic method calls.

=head1 AUTHOR

Luke Poskitt, E<lt>ltp@cpan.orgE<gt>

Thanks to Eric Welch, E<lt>erik.welch@gmail.comE<gt>, for input and feedback.

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
