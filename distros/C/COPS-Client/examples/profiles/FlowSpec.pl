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
			Direction	=> 'Downstream',
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
			Envelope_Type		=> "authorize",
			Service_Type		=> 'Flow Spec',

                        'Envelope_authorize_Token Bucket Rate' => 200,
                        'Envelope_authorize_Token Bucket Size' => 50000,
                        'Envelope_authorize_Peak Data Rate' =>    20000,
                        'Envelope_authorize_Minimum Policed Unit' => 64,
                        'Envelope_authorize_Maximum Packet Size' => 2000,
			'Envelope_authorize_Rate' => 20,
                        'Envelope_authorize_Slack Term' => 20,

                        'Envelope_reserve_Token Bucket Rate' => 10000,
                        'Envelope_reserve_Token Bucket Size' => 5000,
                        'Envelope_reserve_Peak Data Rate' =>    2000,
                        'Envelope_reserve_Minimum Policed Unit' => 1024,
                        'Envelope_reserve_Maximum Packet Size' => 1500,
			'Envelope_reserve_Rate' => 2000,
                        'Envelope_reserve_Slack Term' => 2000,

                        'Envelope_commit_Token Bucket Rate' => 10000,
                        'Envelope_commit_Token Bucket Size' => 5000,
                        'Envelope_commit_Peak Data Rate' =>    2000,
                        'Envelope_commit_Minimum Policed Unit' => 1024,
                        'Envelope_commit_Maximum Packet Size' => 1500,
			'Envelope_commit_Rate' => 2000,
                        'Envelope_commit_Slack Term' => 2000,

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


