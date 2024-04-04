package App::KamstrupKemSplit;

our $VERSION = '0.007'; # VERSION
# ABSTRACT: Helper functions for the Kamstrup KEM file splitter application

use Modern::Perl;
use Log::Log4perl qw(:easy);
use Text::CSV;
use Archive::Zip qw(:ERROR_CODES);
use XML::Simple;
use Crypt::Rijndael;
use MIME::Base64;
use Exporter qw(import);
our @EXPORT = qw(split_order read_config unzip_kem decode_kem parse_xml_string_to_data write_xml_output write_kem2_xml_output);

=head1 DESCRIPTION

This script takes as input a delivery file from Kamstrup (encrypted, compressed KEM file), unpacks it and splits the file into different
decoded XML files that can be further processed.

Minimal input to the script are the encryption key and the input file. If no further configuration file is passed then all information
in the input file is written to the output file.

A configuration file consists of a CSV file with `;` as delimeter and the following columns:

C<kamstrup_ordernr;kamstrup_serial_number_start;kamstrup_serial_number_end;number_of_devices;internal_batch_number>

The output file name will be [kamstrup_ordernr]_[internal_batch_number].

Following functions are available in this package:

=over 

=item unzip_kem

Extracts the KEM file from the archive file delivered by Kamstrup.
Do not forget to delete the file after processing.

Takes the archive file name as input.
Returns the filename.

=cut
sub unzip_kem {
	my $input_file = shift();

	# Unzip the file
	INFO "Opening $ input_file archive file...";
	my $zip    = Archive::Zip->new();
	my $status = $zip->read($input_file);
	LOGDIE "Read of $input_file failed\n" if $status != AZ_OK;

	# There should be only a single kem in the zipfile
	my @kems = $zip->membersMatching('.*\.kem');
	LOGDIE "Please examine the zipfile, it does not contain a single kem file"
	  if ( scalar(@kems) != 1 );
	my $filename = $kems[0]->{'fileName'};
	DEBUG "Kem filename in archive : " . $filename . " -> unzip";
	$status = $zip->extractMemberWithoutPaths($filename);
	LOGDIE "Extracting $filename from archive failed\n" if $status != AZ_OK;
	return $filename;
}

=item decode_kem

Decode an encrypted KEM file, requires the input filename and the encryption key.

Returns the decrypted XML contents of the KEM file as string.
=cut
sub decode_kem {
	my $input_file = shift();
	my $key        = shift();
	my $kemformat  = shift() // 2;
	
	my $kem_xml    = XMLin($input_file);
	DEBUG "Decoding encrypted section from XML with key '$key'";
	my $data    = decode_base64( $kem_xml->{CipherData}->{CipherValue} );
	my $fullkey = $key . ( "\0" x ( 16 - length($key) ) );
	my $cipher  = Crypt::Rijndael->new( $fullkey, Crypt::Rijndael::MODE_CBC() );
	my $plain_xml = $cipher->decrypt($data);

	my $fix_head = $kemformat == 2 ? "<Devices schem" : "<MetersInOrder";

	# Fix the XML                 
	substr( $plain_xml, 0, 14 ) = $fix_head;
	chomp($plain_xml);

	# Remove trailing characters after last closing bracket in the XML
	if ( $plain_xml =~ /(<.+>)/ ) {
		$plain_xml = $1;
	}
	return $plain_xml;
}

=item split_order

Extracts the contents of a specific order from the combined Kamstrup KEM file.

Takes as input the parsed content of the KEM file (meter details),
the lowest meter number in the order,
and the highest meter number in the order.

Returns all meter information of the devices that match the filter criteria.
=cut
sub split_order {
	my $meters = shift();
	my $nr_min = shift();
	my $nr_max = shift();
	
	my $response;
	foreach my $meter ( @{ $meters->{'Meter'} } ) {
		# If we want to dump all devices, $nr_max will be -1, so if this is not the case do the check and otherwise just dump all
		if ($nr_max == -1) {
			$response->{$meter} = $meter;
		} elsif ( $meter->{'MeterNo'} >= $nr_min && $meter->{'MeterNo'} <= $nr_max ) {
			$response->{$meter} = $meter;
		}
	}
	return $response;
}

=item read_config

Read a CSV configuration file containing the various sub orders.

CSV needs to be separated with ';' and needs to contain the headers 'kamstrup_ordernr',  'kamstrup_serial_number_start',
		'kamstrup_serial_number_end', 'number_of_devices' and 'internal_batch_number'.

=cut
sub read_config {
	my $csv_file = shift();

	# Init the CSV reader
	my $csv = Text::CSV->new(
		{
			binary             => 1,
			auto_diag          => 1,
			sep_char           => ';',
			allow_loose_quotes => 1,
		}
	);
	open( my $data, '<:encoding(utf8)', $csv_file )
	  or LOGDIE "Could not open '$csv_file' $!\n";
	INFO "Reading config file '$csv_file'";

	# Fetch the header to determine at what position the useful data is
	# Required headers are listed below
	my @reflist = (
		'kamstrup_ordernr',           'kamstrup_serial_number_start',
		'kamstrup_serial_number_end', 'number_of_devices',
		'internal_batch_number'
	);
	my $fields = $csv->getline($data);
	my $index;
	my $entries = 0;
	my $idx     = 0;
	foreach my $field ( @{$fields} ) {
		$index->{$field} = $idx;
		$idx++;
	}
	my $content;

	# Check all headers are present
	foreach my $label (@reflist) {
		if ( !defined $index->{$label} ) {
			LOGDIE "Input configuration file does not contain a column with label '$label'! Quitting...";
		}
	}

	# Parse the file data based on the header information
	while ( my $fields = $csv->getline($data) ) {
		my $kamstrup_ordernr = $fields->[ $index->{'kamstrup_ordernr'} ];
		my $kamstrup_start =   $fields->[ $index->{'kamstrup_serial_number_start'} ];
		my $kamstrup_stop =    $fields->[ $index->{'kamstrup_serial_number_end'} ];
		my $internal_batchnr = $fields->[ $index->{'internal_batch_number'} ];
		my $nr_of_devices    = $fields->[ $index->{'number_of_devices'} ];
		if (   defined $kamstrup_ordernr
			&& defined $kamstrup_start
			&& defined $kamstrup_stop
			&& defined $internal_batchnr )
		{
			$content->{$internal_batchnr} = {
				'kamstrup_ordernr' => $kamstrup_ordernr,
				'kamstrup_start'   => $kamstrup_start,
				'kamstrup_stop'    => $kamstrup_stop,
				'nr_of_devices'    => $nr_of_devices
			};
		} else {
			WARN "Skipping line $. of input file because it does not contain the required fields";
		}
	}
	close($data);
	return $content;
}

=item parse_cml_string_to_data

Convert the XML from the decoded file into a Perl datastructure that can be processed programmatorically.

=cut
sub parse_xml_string_to_data {
	my $xml = shift();

	# Write XML to output in order to be able to read it back as data structure
	open( my $fh, '>', "decoded.xml" ) or die "Could not open output file: $!";
	print $fh $xml;
	close $fh;

	# Parse the written XML to data structure
	my $meters = XMLin( "decoded.xml", ForceArray => ['Meter'] );
	unlink 'decoded.xml';
	return $meters;
}

=item write_xml_output

Write the filtered XML to a file taking into account the required formatting.

Takes as input the xml skeleton structure

=cut
sub write_xml_output {
	my $skeleton = shift();	
	
	my $xml = XMLout( $skeleton, 'noattr' => 1, KeyAttr => ["MeterNo"] );

	# Ensure we end up with the expected XML file structure
	$xml =~ s/opt/MetersInOrder/g;  # Replace the default 'opt' by 'MetersInOrder'
	$xml =~ s/\<orderid.+orderid\>\s+//;                # Strip orderid line
	$xml =~ s/\<schemaVersion.+schemaVersion\>\s+//;    # Strip orderid line
	$xml =~ s/\<MetersInOrder\>//; 						# Strip first line, we will replace it with a custom line to match the original XML output
	$xml =	'<?xml version="1.0" encoding="utf-8"?>'
		  . "\n<MetersInOrder orderid=\"$skeleton->{'orderid'}\" schemaVersion=\"2.0\">"
		  . $xml;
	
	my $outputfile = $skeleton->{'orderid'} . ".xml";
	my $fh = IO::File->new( "> " . $outputfile );

	if ( defined $fh ) {
		print $fh $xml;
		$fh->close;
		INFO "Wrote outputfile $outputfile";
	} else {
		LOGDIE "Could not write to outputfile: $!";
	}
	
}

=item write_kem2_xml_output

Write the raw KEM2 file output to a file with name based on the ordercodes in the file.

Takes as input the raw xml string

=cut
sub write_kem2_xml_output {
	my $xml = shift();
	
	# Order code fetch an sanity check
	my @ordercodes = $xml =~ /<OrderNumber>(\d+)<\/OrderNumber>/g;
	my $ordercode = $ordercodes[0];
	
	my %codes = map { $_, 1 } @ordercodes;
	if (keys %codes == 1) {
 		# all equal -> continue
 		INFO "All devices in the KEM file have the same ordercode '$ordercode'";
	} else {
		WARN "WARNING: the XML file contains multiple ordercodes in a single file -- check if this is supported by HydroSense first!";
		$ordercode = '';
		foreach (keys %codes) {
			WARN " * $_";
			$ordercode .= "$_" . "-";
		}
		
		# Cut last '-' from filename
		$ordercode =~ s/-$//;
		
	}
	
	
	# Write the XML to file and stop
	my $fname = $ordercode . ".xml";
	open( my $fh, '>', $fname ) or die "Could not open output file: $!";
	print $fh $xml;
	close $fh;
	
	INFO "Wrote decoded KEM2 file output to $fname";
	
	return;
}


1;

=back

=head1 AUTHOR

Lieven Hollevoet <lieven@quicksand.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Lieven Hollevoet.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
