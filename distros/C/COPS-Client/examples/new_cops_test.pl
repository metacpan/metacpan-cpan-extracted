#!/usr/local/bin/perl

use strict;
use COPS::Client;

my $cmts_ip = $ARGV[0];
my $action=$ARGV[1];
my $id = $ARGV[2];

my $cops_client = new COPS::Client (
                        [
                        VendorID => 'COPS Client',
                        ServerIP => $cmts_ip,
                        ServerPort => '3918',
                        Timeout => 2,
			DEBUG => 10,
			DataHandler => \&display_data,
			ListenServer => 0
                        ]
                        );

# We send a connect message to the COPS server
if ( $cops_client->connect() )
	{

	if ( $action=~/^set$/i )
	{
	$cops_client->set_command("set");
	$cops_client->subscriber_set("ipv4","172.26.65.19");

	$cops_client->gate_specification_add(
			[
			Direction	=> 'Downstream',
			DSCPToSMark	=> 0,
			Priority	=> 0,
			PreEmption	=> 1,

			Gate_Flags	=> 0,
	                Gate_TOSField	=> 0,
			Gate_TOSMask	=> 0,
			Gate_Class	=> 0,
			Gate_T1		=> 0,
			Gate_T2		=> 0,
			Gate_T3		=> 0,
			Gate_T4		=> 0
			]
			);


	$cops_client->classifier_add(
			[
			Classifier_Type		=> 'Classifier',
			Classifier_Priority => 64,
			Classifier_SourceIP => "172.26.65.19",
			Classifier_DestinationIP => "172.26.65.1",
			Classifier_ClassifierID => 100,
			Classifier_State => 1
			]
			);

	$cops_client->envelope_add (
			[
			Envelope_Type		=> "authorize,reserve,commit",
			Service_Type		=> 'DOCSIS Service Class Name',
			ServiceClassName 	=> 'S_down'
			]
			);

	my $timer= time();

	$cops_client->rks_set (
			[
			PRKS_IPAddress		=> '192.168.50.2',
			PRKS_Port		=> 2000,
			PRKS_Flags		=> 1,
			SRKS_IPAddress		=> 0,
			SRKS_Port		=> 0,
			SRKS_Flags		=> 0,
			BCID_TimeStamp		=> $timer,
			BCID_ElementID		=> '99999999',
			BCID_TimeZone		=> '00000000',
			BCID_EventCounter	=> 12347890
			]
			);

#	$cops_client->opaque_set (
#			[
#			OpaqueData		=> 'a test'
#			]
#			);

#	$cops_client->timebase_set ( 
#			[
#			TimeLimit	=> 30
#			]
#			);
#

#	$cops_client->volume_set ( 
#			[
#			VolumeLimit	=> 3000
#			]
#			);


	}

	if ( $action=~/^delete$/i )
		{
	$cops_client->set_command("delete");
	$cops_client->set_gate_id($id);
	$cops_client->subscriber_set("ipv4","172.26.65.19");
		}


	if ( $action=~/^synch$/i )
	{
	$cops_client->subscriber_set("ipv4","172.26.65.19");
	$cops_client->set_command("synch");
	}

	if ( $action=~/^info$/i )
		{
		$cops_client->set_command("info");
		$cops_client->set_gate_id($id);
		$cops_client->subscriber_set("ipv4","172.26.65.19");
		}

	$cops_client->check_data_available();

	}
	else
	{
	print "Error was '".$cops_client->get_error()."'\n";
	}

$cops_client->disconnect();

sub display_data
{
my ( $self ) = shift;
my ( $data ) = shift;

print "Report Datagram sent.\n\n";

foreach my $name ( sort { $a cmp $b } keys %{$data} )
        {
        print "Name  is '$name' value is '${$data}{$name}'\n";
        }

}

exit(0);


