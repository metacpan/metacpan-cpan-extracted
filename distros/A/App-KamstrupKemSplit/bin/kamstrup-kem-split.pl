#! /usr/bin/env perl
# PODNAME: kamstrup-kem-split.pl
# ABSTRACT: Split encrypted KEM file input from the Kamstrup backend into separate XML files with device information
our $VERSION = '0.007'; # VERSION	

use Modern::Perl '2022';
use App::KamstrupKemSplit;
use Log::Log4perl qw(:easy);
use XML::Simple;
use Getopt::Long;
use Pod::Usage;
my ( $key, $verbose, $help, $man, $config, $kemformat, $show_version );

# Default values
$verbose = 0;
$kemformat = 2; # Default to KEM file format type 2

# Get the command line options
GetOptions(
	'help|?|h'  => \$help,
	'man'       => \$man,
	'v|verbose' => \$verbose,
	'key=s'     => \$key,
	'config=s'  => \$config,
	'kem=s'     => \$kemformat,
	'version'   => \$show_version
) or pod2usage(2);

pod2usage(1) if (defined $help);

if ($verbose) {
	Log::Log4perl->easy_init($DEBUG);
	INFO "Starting in verbose mode";
} else {
	Log::Log4perl->easy_init($INFO);
}

if (defined $show_version) {
	my $version = $main::VERSION // 'dev';
	INFO "This is kamstrup-kem-split version " . $version;
	exit(0);
}

pod2usage(1) if (!defined $ARGV[0]);

# Open the config file
my $orders;
$orders = read_config($config) if (defined $config);

# Unzip it
my $kem_file = unzip_kem( $ARGV[0] );

# Decode the kem file from the archive
my $xml = decode_kem( $kem_file, $key, $kemformat);


# Remove the unzipped file
unlink $kem_file;

# If we are parsing KEM2 file we dump the XML and stop here
INFO "KEMformat is '$kemformat'";
if ($kemformat == 2) {
	write_kem2_xml_output($xml);
	exit(0);
}

my $meters = parse_xml_string_to_data($xml);

# If no config is passed, just dump all information into a single outputfile
if ( !defined $orders ) {
	# Prepare an order structure that contains all devices
	$orders->{'fulldump'} = {
		'kamstrup_ordernr' => -1,
		'kamstrup_start'   => 0,
		'kamstrup_stop'	   => -1,
		'nr_of_devices'	   => -1
	};
	
}

# Run over the orders to create the outputfiles
foreach my $order ( sort keys %{$orders} ) {
	DEBUG "Processing batch $order";
	my $meterinfo = split_order(
		$meters,
		$orders->{$order}->{'kamstrup_start'},
		$orders->{$order}->{'kamstrup_stop'}
	);

	# Sanity check on the number of devices
	if ( scalar( keys %{$meterinfo} ) != $orders->{$order}->{'nr_of_devices'} 
	     && $orders->{$order}->{'nr_of_devices'} != -1) {
		LOGDIE "Expecting " . $orders->{$order}->{'nr_of_devices'} . " devices in batch $order but found " . scalar( keys %{$meterinfo} ) . " in XML file";
	}

	my $skeleton;

	$skeleton->{'orderid'} = $meters->{'orderid'};
	$skeleton->{'orderid'} .= "_" . "$order" if $orders->{$order}->{'nr_of_devices'} != -1; # Add the _orderinfo in case we are not doing a full dump
	my $order_name = $meters->{'orderid'};
	$order_name = $order if $orders->{$order}->{'nr_of_devices'} != -1; # Use the suborder name in case we are not doing a full dump
	
	INFO "Dumping info from order # $order_name for " . scalar( keys %{$meterinfo} ) . " devices";
	
	$skeleton->{'Meter'}   = $meterinfo;
	write_xml_output($skeleton);
}

exit(0);

=head1 NAME

kamstrup-kem-split - Splits an encrypted delivery file from Kamstrup into separate XML files with device information

=head1 SYNOPSIS

    ./kamstrup-kem-split.pl --key=<key> [--config=<configfile> --kem=1] inputfile_from_backend

=head1 DESCRIPTION

This script takes as input a delivery file from Kamstrup (encrypted, compressed KEM file), unpacks it and splits the file into different
decoded XML files that can be further processed.

Minimal input to the script are the encryption key and the input file. If no further configuration file is passed then all information
in the input file is written to the output file.

A configuration file consists of a CSV file with `;` as delimeter and the following columns:

C<kamstrup_ordernr;kamstrup_serial_number_start;kamstrup_serial_number_end;number_of_devices;internal_batch_number>

The output file name will be [kamstrup_ordernr]_[internal_batch_number].

Please note that order splitting si only supported for KEM files and not for the default KEM2 files.

Note that this script support the KEM2 file format by default. If you want to process an older KEM file, please configure the script as such via the commandline.

=head1 AUTHOR

Lieven Hollevoet <lieven@quicksand.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Lieven Hollevoet.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

