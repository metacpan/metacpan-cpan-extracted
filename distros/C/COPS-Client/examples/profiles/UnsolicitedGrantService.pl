#!/usr/local/bin/perl

use strict;
use COPS::Client;

my $cops_client = new COPS::Client (
                        [
                        VendorID => 'COPS Client',
                        ServerIP => '192.168.1.1',
                        ServerPort => '3918',
                        Timeout => 2,
			DataHandler => \&display_data
                        ]
                        );

if ( $cops_client->connect() )
	{
	$cops_client->set_command("set");
	$cops_client->subscriber_set("ipv4","172.26.65.19");

	$cops_client->gate_specification_add(
			[
			Direction	=> 'Upstream',
			DSCPToSMark	=> 0,
			Priority	=> 0,
			PreEmption	=> 0,

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
			Classifier_ClassifierID => 100,
			Classifier_State => 1
			]
			);

	$cops_client->envelope_add (
			[
			Envelope_Type		=> "authorize,reserve,commit",
			Service_Type		=> 'Unsolicited Grant Service',

			'Envelope_authorize_Request Transmission Policy' => 0,
			'Envelope_authorize_Unsolicited Grant Size' => 10000,
			'Envelope_authorize_Grants Per Interval' => 10,
			'Envelope_authorize_Nominal Grant Interval' => 1000000,
			'Envelope_authorize_Tolerated Grant Jitter' => 400000,
			'Envelope_authorize_Required Attribute Mask' => 0,
			'Envelope_authorize_Forbidden Attribute Mask' => 0,

			'Envelope_reserve_Request Transmission Policy' => 0,
			'Envelope_reserve_Unsolicited Grant Size' => 10000,
			'Envelope_reserve_Grants Per Interval' => 10,
			'Envelope_reserve_Nominal Grant Interval' => 1000000,
			'Envelope_reserve_Tolerated Grant Jitter' => 400000,
			'Envelope_reserve_Required Attribute Mask' => 0,
			'Envelope_reserve_Forbidden Attribute Mask' => 0,

			'Envelope_commit_Request Transmission Policy' => 0,
			'Envelope_commit_Unsolicited Grant Size' => 10000,
			'Envelope_commit_Grants Per Interval' => 10,
			'Envelope_commit_Nominal Grant Interval' => 1000000,
			'Envelope_commit_Tolerated Grant Jitter' => 400000,
			'Envelope_commit_Required Attribute Mask' => 0,
			'Envelope_commit_Forbidden Attribute Mask' => 0,

			]
			);

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

print "Report Information Received.\n\n";

foreach my $name ( sort { $a cmp $b } keys %{$data} )
        {
        print "Name  is '$name' value is '${$data}{$name}'\n";
        }

}

exit(0);


