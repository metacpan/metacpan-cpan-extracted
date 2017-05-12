package Apache::WebSNMP;

#################################################################
# WebSNMP							#
#    Allows for snmp commands to be directly embedded in	#
#	html code						#
#  								#
#  currently supports the following syntax:			#
#  	<snmp> COMMANDS </snmp>					#
#  where COMMANDS can be any of the following:			#
#	host=value		# set snmp host			#
#	community=value		# set snmp community		#
#	variable={oid descriptor}				#
#		# set a variable name to a snmp oid 		#
#		# e.g.    myvar=ifDescr				#
#		# interface, system, ip, tcp, udp, at and	#
#		#   icmp oids are currently supported		#
#	connect			# start snmp connection		#
#	query			# get all current variables	#
#	extension(variable)=value				#
#		# set the extension for a variable's oid	#
#		# eg.  	 extension(myvar)=2			#
#	print(variable)		# print returned value		#
#################################################################

use strict;
use Apache::Constants qw(:common);

@Apache::WebSNMP::ISA = qw(DynaLoader);
$Apache::WebSNMP::VERSION = '0.11';

sub handler
{

	use SNMP;
	
	my $r=shift;

	# snmp oid map
	my %oidmap = (
		# system
		'sysDescr'	=> "1.3.6.1.2.1.1.1",
		'sysObjectID'	=> "1.3.6.1.2.1.1.2",
		'sysUpTime'	=> "1.3.6.1.2.1.1.3",
		'sysContact'	=> "1.3.6.1.2.1.1.4",
		'sysName'	=> "1.3.6.1.2.1.1.5",
		'sysLocation'	=> "1.3.6.1.2.1.1.6",
		'sysServices'	=> "1.3.6.1.2.1.1.7",
		# interface
		'ifIndex'	=> "1.3.6.1.2.1.2.2.1.1",
		'ifDescr'	=> "1.3.6.1.2.1.2.2.1.2",
        	'ifType'        => "1.3.6.1.2.1.2.2.1.3",
        	'ifMtu'         => "1.3.6.1.2.1.2.2.1.4",
        	'ifSpeed'       => "1.3.6.1.2.1.2.2.1.5",
        	'ifPhysAddress' => "1.3.6.1.2.1.2.2.1.6",
        	'ifAdminStatus' => "1.3.6.1.2.1.2.2.1.7",
        	'ifOperStatus'  => "1.3.6.1.2.1.2.2.1.8",
        	'ifLastChange'  => "1.3.6.1.2.1.2.2.1.9",
        	'ifInOctets'    => "1.3.6.1.2.1.2.2.1.10",
        	'ifInUcastPkts' => "1.3.6.1.2.1.2.2.1.11",
        	'ifInNUcastPkts'=> "1.3.6.1.2.1.2.2.1.12",
        	'ifInDiscards'  => "1.3.6.1.2.1.2.2.1.13",
        	'ifInErrors'    => "1.3.6.1.2.1.2.2.1.14",
        	'ifInUnknownProtos' => "1.3.6.1.2.1.2.2.1.15",
        	'ifOutOctets'   => "1.3.6.1.2.1.2.2.1.16",
        	'ifOutUcastPkts' => "1.3.6.1.2.1.2.2.1.17",
        	'ifOutNUcastPkts' => "1.3.6.1.2.1.2.2.1.18",
        	'ifOutDiscards' => "1.3.6.1.2.1.2.2.1.19",
        	'ifOutErrors'   => "1.3.6.1.2.1.2.2.1.20",
        	'ifOutQLen'     => "1.3.6.1.2.1.2.2.1.21",
        	'ifSpecific'    => "1.3.6.1.2.1.2.2.1.22",
		# ip
		'ipForwarding'	=> "1.3.6.1.2.4.1",
        	'ipDefaultTTL'  => "1.3.6.1.2.4.2",
        	'ipInReceives'  => "1.3.6.1.2.4.3",
        	'ipInHdrErrors' => "1.3.6.1.2.4.4",
        	'ipInAddrErrors' => "1.3.6.1.2.4.5",
        	'ipForwDatagrams' => "1.3.6.1.2.4.6",
        	'ipInUnknownProtos' => "1.3.6.1.2.4.7",
        	'ipInDiscards'  => "1.3.6.1.2.4.8",
        	'ipInDelivers'  => "1.3.6.1.2.4.9",
        	'ipOutRequests' => "1.3.6.1.2.4.10",
        	'ipOutDiscards' => "1.3.6.1.2.4.11",
        	'ipOutNoRoutes' => "1.3.6.1.2.4.12",
        	'ipReasmTimeout' => "1.3.6.1.2.4.13",
        	'ipReasmReqds'  => "1.3.6.1.2.4.14",
        	'ipReasmOKs'    => "1.3.6.1.2.4.15",
        	'ipReasmFails'  => "1.3.6.1.2.4.16",
        	'ipFragOKs'     => "1.3.6.1.2.4.17",
        	'ipFragFails'   => "1.3.6.1.2.4.18",
        	'ipFragCreates' => "1.3.6.1.2.4.19",
        	'ipAdEntAddr'   => "1.3.6.1.2.4.20.1.1",
        	'ipAdEntIfIndex' => "1.3.6.1.2.4.20.1.2",
        	'ipAdEntNetMask' => "1.3.6.1.2.4.20.1.3",
        	'ipAdEntBcastAddr' => "1.3.6.1.2.4.20.1.4",
        	'ipAdEntEntReasmMaxSize' => "1.3.6.1.2.4.20.1.5",
        	'ipRouteDest'   => "1.3.6.1.2.4.21.1.1",
		'ipRouteIfIndex' => "1.3.6.1.2.4.21.1.2",
		'ipRouteMetric1' => "1.3.6.1.2.4.21.1.3",
        	'ipRouteMetric2' => "1.3.6.1.2.4.21.1.4",
		'ipRouteMetric3' => "1.3.6.1.2.4.21.1.5",
        	'ipRouteMetric4' => "1.3.6.1.2.4.21.1.6",
		'ipRouteNextHop' => "1.3.6.1.2.4.21.1.7",
        	'ipRouteType'   => "1.3.6.1.2.4.21.1.8",
		'ipRouteProto'  => "1.3.6.1.2.4.21.1.9",
        	'ipRouteAge'    => "1.3.6.1.2.4.21.1.10",
		'ipRouteMask'   => "1.3.6.1.2.4.21.1.11",
        	'ipRouteMetric5' => "1.3.6.1.2.4.21.1.12",
		'ipRouteInfo'   => "1.3.6.1.2.4.21.1.13",
		'ipNetToMediaIfIndex' => "1.3.6.1.2.1.4.22.1.1",
        	'ipNetToMediaPhysAddress' => "1.3.6.1.2.1.4.22.1.2",
        	'ipNetToMediaNetAddress' => "1.3.6.1.2.1.4.22.1.3",
        	'ipNetToMediaType' => "1.3.6.1.2.1.4.22.1.4",
        	'ipRoutingDiscards' => "1.3.6.1.2.4.23",
		# tcp
		'tcpRtoAlgorithm' => '1.3.6.1.2.1.6.1',
        	'tcpRtoMin' 	=> '1.3.6.1.2.1.6.2',
        	'tcpRtoMax' 	=> '1.3.6.1.2.1.6.3',
        	'tcpMaxConn'	=> '1.3.6.1.2.1.6.4',
        	'tcpActiveOpens' => '1.3.6.1.2.1.6.5',
        	'tcpPassiveOpens' => '1.3.6.1.2.1.6.6',
        	'tcpAttemptFails' => '1.3.6.1.2.1.6.7',
        	'tcpEstabResets' => '1.3.6.1.2.1.6.8',
        	'tcpCurrEstab' 	=> '1.3.6.1.2.1.6.9',
        	'tcpInSegs' 	=> '1.3.6.1.2.1.6.10',
        	'tcpOutSegs' 	=> '1.3.6.1.2.1.6.11',
        	'tcpRetransSets' => '1.3.6.1.2.1.6.12',
        	'tcpConnState' 	=> '1.3.6.1.2.1.6.13.1.1',
        	'tcpConnLocalAddress' => '1.3.6.1.2.1.6.13.1.2',
        	'tcpConnLocalPort' => '1.3.6.1.2.1.6.13.1.3',
        	'tcpConnRemAddress' => '1.3.6.1.2.1.6.13.1.4',
        	'tcpConnRemPort' => '1.3.6.1.2.1.6.13.1.5',
        	'tcpInErrs' 	=> '1.3.6.1.2.1.6.14',
        	'tcpOutRsts' 	=> '1.3.6.1.2.1.6.15',
		# udp
		'udpInDatagrams' => '1.3.6.1.2.1.7.1',
        	'udpNoPorts' 	=> '1.3.6.1.2.1.7.2',
        	'udpInErrors' 	=> '1.3.6.1.2.1.7.3',
        	'udpOutDatagrams' => '1.3.6.1.2.1.7.4',
        	'udpLocalAddress' => '1.3.6.1.2.1.7.5.1.1',
        	'udpLocalPort'  => '1.3.6.1.2.1.7.5.1.2',
		# at
		'atIfIndex'	=> '1.3.6.1.2.1.3.1.1.1',
        	'atPhysAddressIfIndex' => '1.3.6.1.2.1.3.1.1.2',
        	'atNetAddress'  => '1.3.6.1.2.1.3.1.1.3',
		# icmp
		'icmpInMsgs'	=> '1.3.6.1.2.1.5.1',	
        	'icmpInErrors' 	=> '1.3.6.1.2.1.5.2',
       	 	'icmpInDestUnreachs' => '1.3.6.1.2.1.5.3',
        	'icmpInTimeExcds' => '1.3.6.1.2.1.5.4',
        	'icmpInParmProbs' => '1.3.6.1.2.1.5.5',
        	'icmpInSrcQuenchs' => '1.3.6.1.2.1.5.6',
        	'icmpInRedirects' => '1.3.6.1.2.1.5.7',
       		'icmpInEchos' 	=> '1.3.6.1.2.1.5.8',
        	'icmpInEchoReps' => '1.3.6.1.2.1.5.9',
        	'icmpInTimestamps' => '1.3.6.1.2.1.5.10',
        	'icmpInTimestampsReps' => '1.3.6.1.2.1.5.11',
        	'icmpInAddrMasks' => '1.3.6.1.2.1.5.12',
        	'icmpInAddrMaskReps' => '1.3.6.1.2.1.5.13',
        	'icmpOutMsgs' 	=> '1.3.6.1.2.1.5.14',
        	'icmpOutErrors' => '1.3.6.1.2.1.5.15',
        	'icmpOutDestUnreachs' => '1.3.6.1.2.1.5.16',
        	'icmpOutTimeExcds' => '1.3.6.1.2.1.5.17',
        	'icmpOutParmProbs' => '1.3.6.1.2.1.5.18',
        	'icmpOutSrcQuenchs' => '1.3.6.1.2.1.5.19',
        	'icmpOutRedirects' => '1.3.6.1.2.1.5.20',
        	'icmpOutEchos' 	=> '1.3.6.1.2.1.5.21',
        	'icmpOutEchoReps' => '1.3.6.1.2.1.5.22',
        	'icmpOutTimestampsReps' => '1.3.6.1.2.1.5.23',
        	'icmpOutTimestampsReps' => '1.3.6.1.2.1.5.24',
        	'icmpOutAddrMasks' => '1.3.6.1.2.1.5.25',
       	 	'icmpOutAddrMaskReps' => '1.3.6.1.2.1.5.26',
	);

	# find out which html file was requested!
	my $htmlfile = $r->uri;
	my $htmlbase = "/home/httpd/html";
	my $html = $htmlbase . $htmlfile;

	# defaults!
	my $host = "localhost";
	my $community = "public";
	my $oid = "sysDescr";

	# arrays form variable retension
	my @current_vars = ();
	my %var_to_oid_map = ();
	my %var_to_value_map = ();

	open(HTML, $html);
	my @html_buffer = <HTML>;
	close(HTML);

	my $the_buffer = join("",@html_buffer);

	# local variables so no confusion with the other modules.
	my $sess = "";
	my $sval = "";
	my $x = 0;
	my $val = "";
	my @snmpvals = ();
	my @tag = ();
	my $whichvar = "";
	my $nextvalue = "";
	my $a_mac = "";
	my $split_mac = "";
	my $tempoid = "";
	my $vb = "";
	my @values = ();
	my @varlist = ();
	my @split_tag = ();

	# split the input buffer to find the snmp tags!
	my @incidents = split(/(<snmp>[a-zA-z0-9=\s\.\(\)]*<\/snmp>)/, $the_buffer);

	# process each tag.
	foreach $val (@incidents)
	{	
		if($val =~ "<snmp>")
		{
			# get rid of <snmp> tags
			$val = substr($val, 6,);
			$val = substr($val, 0, -7);
			# now parse snmp tag values
			@snmpvals = split(/\s+/, $val);
			foreach $sval (@snmpvals)
			{
				@tag = split(/(=)/, $sval);

				if($tag[0] eq "host")
				{
					$host = $tag[2];
					next;
				}

                        	if($tag[0] eq "community")
	                        {
        	                        $community = $tag[2];
					next;
                        	}

				# depricated
	                        #if($tag[0] =~ /extension\(/)
        	                #{
                	        #        # parse extension(var)=val
				#	$whichvar = substr($tag[0], 10,);
				#	$whichvar = substr($whichvar, 0, -1);
	                        #        $var_to_oid_map{$whichvar} = $var_to_oid_map{$whichvar}.".".$tag[2];
				#	next;
                        	#}

	                        if($tag[0] =~ /print\(/)
        	                {
                	                # parse extension(var)=val
                        	        $whichvar = substr($tag[0], 6,);
                                	$whichvar = substr($whichvar, 0, -1);
					$nextvalue = $var_to_value_map{$whichvar};
					#check for special handling of packed binary MAC address
                	                if ($var_to_oid_map{$whichvar} =~ /1\.3\.6\.1\.2\.1\.2\.2\.1\.6/ )
                        	        {
                                	        $a_mac = unpack "H12", $nextvalue;
                                        	$split_mac=substr($a_mac,0,2).":".substr($a_mac,2,2).":".substr($a_mac,4,2).":".substr($a_mac,6,2).":".substr($a_mac,8,2).":".substr($a_mac,10,2);
						print $split_mac;
        	                        }
					else
					{
						print $nextvalue;
						# $var_to_value_map{$whichvar};
					}
                	                next;
                        	}

				if($tag[1] eq "=")
				{
					@split_tag=split(/\./, $tag[2]);
					$_ = $tag[2];
					s/$split_tag[0]/$oidmap{$split_tag[0]}/;
					$tempoid = $_;
					$var_to_oid_map{$tag[0]} = $tempoid;
					push(@current_vars, $tag[0]);
				}	
				
				if($tag[0] eq "connect")
				{
					# create snmp session.
					( $sess = new SNMP::Session(DestHost => $host, Community => $community) ) or print "cannot connect\n";
				}

				if($tag[0] eq "query")
				{
					# construct varlist sequence
					@varlist = ();
					for($x = 0; $x <= $#current_vars; ++$x)
					{
						$varlist[$x] = [$var_to_oid_map{$current_vars[$x]}] ;
					}
					$vb = new SNMP::VarList(@varlist);
					@values = $sess->get($vb);
					for($x = 0; $x <= $#current_vars; ++$x)
					{
						$var_to_value_map{$current_vars[$x]} = $values[$x];
					}
					
					# now flush current array
					@current_vars = ();
				}
			}
		}
		else
		{
			# all else if HTML and only needs to be printed!
			print $val;
		}
	}

	close(HTML);
	return (OK);

} # end handler

bootstrap Apache::WebSNMP $Apache::WebSNMP::VERSION;

1;

__END__

=head1 NAME

Apache::WebSNMP - Allows for SNMP calls to be embedded in HTML

=head1 SYNOPSIS

 <html>
 <body>
 <snmp>
	host=zoom.google.org
	community=public
	connect
	interface=ifDescr.2
	mac=ifPhysAddress.2
	query
 </snmp>
 The interface <b>descriptor</b> for the ethernet card is <snmp> print(interface) </snmp> 
  	and its <b>mac address</b> is <snmp> print(mac) </snmp>
 </body>
 </html>

=head1 DESCRIPTION

The WebSNMP module allows one to embed SNMP commands directly into HTML code. 

=head1 REQUIRES

This module requires the perl SNMP module, available at the CPAN site.

=head1 USAGE

The module allows for three different kinds of statements, surrounded by <snmp> and </snmp> html tags.  The three types of statements consist of configurations, variable assignments, and commands.  A brief description of each type of statement follows:

=head1 Configuration

The configuration statements allow the user the set which host to poll for SNMP information, as well as the SNMP community that the get statements will draw from.  This essentially takes the form of assigning values to the reserved variables B<host> and B<community>.  All variables are assigned with the following syntax:
	varible_name=value

Note: there must not be any intervening whitespace between the '=' and the name and value.  Thus to set the SNMP host to machine.domain.net, we would issue the configuration statement:

	<snmp>host=machine.domain.net</snmp>

If not specified, the default host is localhost, and the default community is public.

=head1 Variable Assignments

Variables are used as temporary holding locations for information returned from SNMP calls.  The decision to use variables was made to obviate the necessity of making a different SNMP get call for each separate piece of information.  Variable assignments follow the simple format listed above, where the variable and the value, this time the symbolic name of a SNMP object identifier, are separated only by an equals sign (no whitespace).  In this case, the user may also append an optional extension to the value.  Most OIDs require some form of extension (for example, the 'system' OIDs usually require an extension of 0, while interface OIDs require the interface number as an extension).  The extension is merely appended to the OID value contained in the named variable.  For example:
	description=ifDescr[.extension]
The OIDs currently implemented are a subset of the IETF Management MIB.  Support is available for the system, interface, ip, tcp, udp, icmp, and at modules.  A list of the currently supported OIDs, and their symbolic equivalents, is given below:

		# system
		'sysDescr'	=> "1.3.6.1.2.1.1.1",
		'sysObjectID'	=> "1.3.6.1.2.1.1.2",
		'sysUpTime'	=> "1.3.6.1.2.1.1.3",
		'sysContact'	=> "1.3.6.1.2.1.1.4",
		'sysName'	=> "1.3.6.1.2.1.1.5",
		'sysLocation'	=> "1.3.6.1.2.1.1.6",
		'sysServices'	=> "1.3.6.1.2.1.1.7",
		# interface
		'ifIndex'	=> "1.3.6.1.2.1.2.2.1.1",
		'ifDescr'	=> "1.3.6.1.2.1.2.2.1.2",
        	'ifType'        => "1.3.6.1.2.1.2.2.1.3",
        	'ifMtu'         => "1.3.6.1.2.1.2.2.1.4",
        	'ifSpeed'       => "1.3.6.1.2.1.2.2.1.5",
        	'ifPhysAddress' => "1.3.6.1.2.1.2.2.1.6",
        	'ifAdminStatus' => "1.3.6.1.2.1.2.2.1.7",
        	'ifOperStatus'  => "1.3.6.1.2.1.2.2.1.8",
        	'ifLastChange'  => "1.3.6.1.2.1.2.2.1.9",
        	'ifInOctets'    => "1.3.6.1.2.1.2.2.1.10",
        	'ifInUcastPkts' => "1.3.6.1.2.1.2.2.1.11",
        	'ifInNUcastPkts'=> "1.3.6.1.2.1.2.2.1.12",
        	'ifInDiscards'  => "1.3.6.1.2.1.2.2.1.13",
        	'ifInErrors'    => "1.3.6.1.2.1.2.2.1.14",
        	'ifInUnknownProtos' => "1.3.6.1.2.1.2.2.1.15",
        	'ifOutOctets'   => "1.3.6.1.2.1.2.2.1.16",
        	'ifOutUcastPkts' => "1.3.6.1.2.1.2.2.1.17",
        	'ifOutNUcastPkts' => "1.3.6.1.2.1.2.2.1.18",
        	'ifOutDiscards' => "1.3.6.1.2.1.2.2.1.19",
        	'ifOutErrors'   => "1.3.6.1.2.1.2.2.1.20",
        	'ifOutQLen'     => "1.3.6.1.2.1.2.2.1.21",
        	'ifSpecific'    => "1.3.6.1.2.1.2.2.1.22",
		# ip
		'ipForwarding'	=> "1.3.6.1.2.4.1",
        	'ipDefaultTTL'  => "1.3.6.1.2.4.2",
        	'ipInReceives'  => "1.3.6.1.2.4.3",
        	'ipInHdrErrors' => "1.3.6.1.2.4.4",
        	'ipInAddrErrors' => "1.3.6.1.2.4.5",
        	'ipForwDatagrams' => "1.3.6.1.2.4.6",
        	'ipInUnknownProtos' => "1.3.6.1.2.4.7",
        	'ipInDiscards'  => "1.3.6.1.2.4.8",
        	'ipInDelivers'  => "1.3.6.1.2.4.9",
        	'ipOutRequests' => "1.3.6.1.2.4.10",
        	'ipOutDiscards' => "1.3.6.1.2.4.11",
        	'ipOutNoRoutes' => "1.3.6.1.2.4.12",
        	'ipReasmTimeout' => "1.3.6.1.2.4.13",
        	'ipReasmReqds'  => "1.3.6.1.2.4.14",
        	'ipReasmOKs'    => "1.3.6.1.2.4.15",
        	'ipReasmFails'  => "1.3.6.1.2.4.16",
        	'ipFragOKs'     => "1.3.6.1.2.4.17",
        	'ipFragFails'   => "1.3.6.1.2.4.18",
        	'ipFragCreates' => "1.3.6.1.2.4.19",
        	'ipAdEntAddr'   => "1.3.6.1.2.4.20.1.1",
        	'ipAdEntIfIndex' => "1.3.6.1.2.4.20.1.2",
        	'ipAdEntNetMask' => "1.3.6.1.2.4.20.1.3",
        	'ipAdEntBcastAddr' => "1.3.6.1.2.4.20.1.4",
        	'ipAdEntEntReasmMaxSize' => "1.3.6.1.2.4.20.1.5",
        	'ipRouteDest'   => "1.3.6.1.2.4.21.1.1",
		'ipRouteIfIndex' => "1.3.6.1.2.4.21.1.2",
		'ipRouteMetric1' => "1.3.6.1.2.4.21.1.3",
        	'ipRouteMetric2' => "1.3.6.1.2.4.21.1.4",
		'ipRouteMetric3' => "1.3.6.1.2.4.21.1.5",
        	'ipRouteMetric4' => "1.3.6.1.2.4.21.1.6",
		'ipRouteNextHop' => "1.3.6.1.2.4.21.1.7",
        	'ipRouteType'   => "1.3.6.1.2.4.21.1.8",
		'ipRouteProto'  => "1.3.6.1.2.4.21.1.9",
        	'ipRouteAge'    => "1.3.6.1.2.4.21.1.10",
		'ipRouteMask'   => "1.3.6.1.2.4.21.1.11",
        	'ipRouteMetric5' => "1.3.6.1.2.4.21.1.12",
		'ipRouteInfo'   => "1.3.6.1.2.4.21.1.13",
		'ipNetToMediaIfIndex' => "1.3.6.1.2.1.4.22.1.1",
        	'ipNetToMediaPhysAddress' => "1.3.6.1.2.1.4.22.1.2",
        	'ipNetToMediaNetAddress' => "1.3.6.1.2.1.4.22.1.3",
        	'ipNetToMediaType' => "1.3.6.1.2.1.4.22.1.4",
        	'ipRoutingDiscards' => "1.3.6.1.2.4.23",
		# tcp
		'tcpRtoAlgorithm' => '1.3.6.1.2.1.6.1',
        	'tcpRtoMin' 	=> '1.3.6.1.2.1.6.2',
        	'tcpRtoMax' 	=> '1.3.6.1.2.1.6.3',
        	'tcpMaxConn'	=> '1.3.6.1.2.1.6.4',
        	'tcpActiveOpens' => '1.3.6.1.2.1.6.5',
        	'tcpPassiveOpens' => '1.3.6.1.2.1.6.6',
        	'tcpAttemptFails' => '1.3.6.1.2.1.6.7',
        	'tcpEstabResets' => '1.3.6.1.2.1.6.8',
        	'tcpCurrEstab' 	=> '1.3.6.1.2.1.6.9',
        	'tcpInSegs' 	=> '1.3.6.1.2.1.6.10',
        	'tcpOutSegs' 	=> '1.3.6.1.2.1.6.11',
        	'tcpRetransSets' => '1.3.6.1.2.1.6.12',
        	'tcpConnState' 	=> '1.3.6.1.2.1.6.13.1.1',
        	'tcpConnLocalAddress' => '1.3.6.1.2.1.6.13.1.2',
        	'tcpConnLocalPort' => '1.3.6.1.2.1.6.13.1.3',
        	'tcpConnRemAddress' => '1.3.6.1.2.1.6.13.1.4',
        	'tcpConnRemPort' => '1.3.6.1.2.1.6.13.1.5',
        	'tcpInErrs' 	=> '1.3.6.1.2.1.6.14',
        	'tcpOutRsts' 	=> '1.3.6.1.2.1.6.15',
		# udp
		'udpInDatagrams' => '1.3.6.1.2.1.7.1',
        	'udpNoPorts' 	=> '1.3.6.1.2.1.7.2',
        	'udpInErrors' 	=> '1.3.6.1.2.1.7.3',
        	'udpOutDatagrams' => '1.3.6.1.2.1.7.4',
        	'udpLocalAddress' => '1.3.6.1.2.1.7.5.1.1',
        	'udpLocalPort'  => '1.3.6.1.2.1.7.5.1.2',
		# at
		'atIfIndex'	=> '1.3.6.1.2.1.3.1.1.1',
        	'atPhysAddressIfIndex' => '1.3.6.1.2.1.3.1.1.2',
        	'atNetAddress'  => '1.3.6.1.2.1.3.1.1.3',
		# icmp
		'icmpInMsgs'	=> '1.3.6.1.2.1.5.1',	
        	'icmpInErrors' 	=> '1.3.6.1.2.1.5.2',
       	 	'icmpInDestUnreachs' => '1.3.6.1.2.1.5.3',
        	'icmpInTimeExcds' => '1.3.6.1.2.1.5.4',
        	'icmpInParmProbs' => '1.3.6.1.2.1.5.5',
        	'icmpInSrcQuenchs' => '1.3.6.1.2.1.5.6',
        	'icmpInRedirects' => '1.3.6.1.2.1.5.7',
       		'icmpInEchos' 	=> '1.3.6.1.2.1.5.8',
        	'icmpInEchoReps' => '1.3.6.1.2.1.5.9',
        	'icmpInTimestamps' => '1.3.6.1.2.1.5.10',
        	'icmpInTimestampsReps' => '1.3.6.1.2.1.5.11',
        	'icmpInAddrMasks' => '1.3.6.1.2.1.5.12',
        	'icmpInAddrMaskReps' => '1.3.6.1.2.1.5.13',
        	'icmpOutMsgs' 	=> '1.3.6.1.2.1.5.14',
        	'icmpOutErrors' => '1.3.6.1.2.1.5.15',
        	'icmpOutDestUnreachs' => '1.3.6.1.2.1.5.16',
        	'icmpOutTimeExcds' => '1.3.6.1.2.1.5.17',
        	'icmpOutParmProbs' => '1.3.6.1.2.1.5.18',
        	'icmpOutSrcQuenchs' => '1.3.6.1.2.1.5.19',
        	'icmpOutRedirects' => '1.3.6.1.2.1.5.20',
        	'icmpOutEchos' 	=> '1.3.6.1.2.1.5.21',
        	'icmpOutEchoReps' => '1.3.6.1.2.1.5.22',
        	'icmpOutTimestampsReps' => '1.3.6.1.2.1.5.23',
        	'icmpOutTimestampsReps' => '1.3.6.1.2.1.5.24',
        	'icmpOutAddrMasks' => '1.3.6.1.2.1.5.25',
       	 	'icmpOutAddrMaskReps' => '1.3.6.1.2.1.5.26',

For example, to get the number of outbound and inbound errors on the 'second' ethernet interface, we would assign the ifOutErrors and ifInErrors OIDs to variables.  Thus:

	<snmp> errorin=ifInErrors.2 errorout=ifOutErrors.2 </snmp>

Note that more than one command can be nested inside a single set of <snmp> tags, as long as they are separated by whitespace.

=head1 Commands

The following command statements are currently available:

B<connect> initiates a connection with the SNMP host defined with the B<host> configuration statement.  This statement can be can be utilized multiple times in order to connect to several different machines, however any queries sent will be sent to the B<current> connection.  

B<query> actually initiates the SNMP get for the information you have requested in your variables, contacting the host defined by the host configuration command, and storing the data in the proper variable.

B<print(variable_name)> simply prints the information returned to a variable after a B<query> command.


=head1 EXAMPLE

To put all this together, let us take a simple example:  we wish to retrieve information concerning the ethernet interface on a host named 'host.domain.net'.  Primarily we are concerned with the administrative status, mac address, and bytes transferred in and out of the interface.  We would begin with the following block:

	<snmp>
	        host=host.domain.net
	        community=public
        	connect
	</snmp>

This block defines the host and the SNMP community, and actually makes the connection to the host.  This block can be placed anywhere within your HTML document, as long as it comes before your SNMP queries.  Next, we must define the information that we wish to obtain:

	<snmp>
		description=ifDescr.2
		mac=ifPhysAddress.2
		inbytes=ifInOctets.2
		outbytes=ifOutOctets.2
		query
	</snmp>

This block instantiates four variables: description, mac, inbytes, and outbytes, in which the information we wish to obtain will be stored.  The extension commands tell the program that we are interested in interface 2.  Finally, the query statement performs the SNMP get on the connected host.  All that remains is to print out our data.  Let us put it in tabular format:

	<table>
		<tr>
			<td>
				Description
			</td>
			<td>	
				Mac Address	
			</td>
			<td>
				Bytes In
			</td>
			<td>
				Bytes Out
			</td>
		</tr>
                <tr>
                        <td>
                                print(description)
                        </td>
                        <td>    
                                print(mac)     
                        </td>
                        <td>
                                print(inbytes)
                        </td>
                        <td>
                                print(outbytes)
                        </td>
                </tr>
	</table> 
This block merely prints out our information as an HTML table.  Mission accomplished.

=head1 AUTHOR

Chris Rigby


 





