#=============================================================

package Convert::Cisco;

use warnings;
use strict;

use FileHandle;
use File::Basename;
use Log::Log4perl qw(get_logger);
use YAML qw(Dump Load);
use DateTime;
use XML::Writer;

=head1 NAME

Convert::Cisco - Module for converting Cisco billing records

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

Convert Cisco billing record binary files. The format is available on the
Cisco Website:

 http://www.cisco.com/univercd/cc/td/doc/product/access/sc/rel9/billinf/r9chap1.htm

Module used to convert Cisco billing records into XML

 use Convert::Cisco;

 my $obj = Convert::Cisco->new(stylesheet=>"cisco.xsl");
 $obj->to_xml("test.bin", "test.xml");

=head1 FUNCTIONS

=cut

#-------------------------------------------------------------

=head2 new

Constructor method, has the following optional parameters:

=over

=item stylesheet

Adds a xml-stylesheet processing instruction to the top of all converted XML files

 <?xml-stylesheet href="cisco.xsl" type="text/xsl"?>

=item config

Billing record configuration data expressed in YAML format. This option is normally
only used by the tests because it over-rides the modules field configuration.

=back

=cut

sub new {
   my $class = shift;
   my (%args) = @_;
   my $self = bless {stylesheet=>undef, config=>undef, %args}, $class;

   ### Load record configuration
   if (defined $self->{config}) {
      $self->{_config} = Load($self->{config});
   }
   else {
      $self->{_config} = Load(join("\n", <Convert::Cisco::DATA>));
   }

   ### Default configuration
   unless (exists $self->{_config}{"CDE Records"}{6003}) {
      $self->{_config}{"CDE Records"}{6003} = {name=>"record_count", spec=>"N"};
   }

   return $self;
}

#-------------------------------------------------------------

# _decodeCDB
#
# Returns the configured name for the CDB record
#

sub _decodeCDB {
   my ($self, $key) = @_;
   my $log = get_logger;

   if (exists $self->{_config}{"CDB Names"}{$key}) {
      return $self->{_config}{"CDB Names"}{$key};
   }
   else {
      $log->warn("CDB not configured: ", $key);
      return "UNKNOWN"
   }
}

#-------------------------------------------------------------

# _decodeCDE
#
# Unpacks the CDE record based on the configured specification
#

sub _decodeCDE {
   my ($self, $key, $value) = @_;
   my $log = get_logger;
   my $decodeValue;
   my $decodeName;
   my $decodeValueUnformatted;

   if (exists $self->{_config}{"CDE Records"}{$key}) {

      $decodeName = $self->{_config}{"CDE Records"}{$key}{name};
      my $spec    = $self->{_config}{"CDE Records"}{$key}{spec};
      my $format  = $self->{_config}{"CDE Records"}{$key}{format};

	  ### Handling for multi-part records
      if (ref($spec) eq "ARRAY")  {
         $decodeValue = join("-", unpack(join(" ", @{$spec}), $value));
      }
      else {
         $decodeValue = unpack($spec, $value);
      }

	  ### Optional output formatting
	  if (defined $format) {
         $decodeValueUnformatted = $decodeValue;

	     if ($format eq "epoch2datetime") {
            $decodeValue = DateTime->from_epoch(epoch => $decodeValueUnformatted)->datetime;
	     }
		 elsif ($format eq "compoundEpoch2datetime") {
			my @timeComponents = split("-", $decodeValueUnformatted);
            $decodeValue = DateTime->from_epoch(epoch => $timeComponents[0])->datetime.".".$timeComponents[1];
	     }
		 else {
			 $log->warn("Unsupported format configured for CDE: $key");
		 }
	  }
   }
   else {
      $log->warn("CDE not configured: ", $key);
	  $decodeName  = "UNKNOWN";
      $decodeValue = unpack("H*", $value);
   }

   return ($decodeValue, $decodeName, $decodeValueUnformatted);
}

#-------------------------------------------------------------

# _stylesheetDecl
#
# Write XSL stylesheet declaration
#

sub _stylesheetDecl {
   my ($self, $writer) = @_;

   if (defined $self->{stylesheet}) {
      $writer->pi('xml-stylesheet', sprintf('href="%s" type="%s"', $self->{stylesheet}, "text/xsl"));
   }
}

#-------------------------------------------------------------

=head2 to_xml

Converts a file into XML format. The current record format is:

 <?xml version="1.0" encoding="UTF-8"?>
 <cdrs>
  ..
  ..
  <cdb tag="1110" name="EndOfCall">
    <cde name="calling_party_category" tag="3000">0a</cde>
    <cde name="user_service_info" tag="3001">8090a3</cde>
    <cde name="calling_number_nature_of_address" tag="3003">02</cde>
	..
	..
  </cdb>
  ..
  ..

B<NOTE:>

The XML format is subject to change and needs an associated XML DTD or Schema.

=cut

sub to_xml {
   my ($self, $filename, $filename_output) = @_;
   my $log = get_logger;

   ### Print the name of the file processed
   $log->debug("Processing: ", $filename);

   ### Input file
   my $infile = new FileHandle($filename, "r") or $log->logcroak("Cannot open $filename - $!");
   binmode $infile;

   ### Output file
   my $file = new FileHandle($filename_output, "w") or $log->logcroak("Cannot open $filename_output - $!");

   ### XML Writer object
   my $writer = XML::Writer->new(OUTPUT => $file, DATA_MODE=>1, DATA_INDENT=>2);

   ### Write the start of the file
   $writer->xmlDecl("UTF-8");
   $self->_stylesheetDecl($writer);
   $writer->startTag("cdrs");

   ### Convert the file into CSV format
   my $bin;
   my $i = 0;
   my $recordCount = 0;

   while ($infile->read($bin, 4)) {
      $i++;

      ### Read the Call Data Block
      my ($cdbTag, $length) = unpack("n2", $bin);
      $infile->read($bin, $length);

      ### Decode the Call Data Elements
      # TLV format : Tag, Length, Value
      my %cde  = unpack("(n n/a*)*", $bin);

      ### Dump the CDB record
      $log->debug("CDB Record:\n", { filter => \&Dump, value  => [$cdbTag, \%cde] });

      ### Start the "cdb" block
      $writer->startTag("cdb", tag => $cdbTag, name => $self->_decodeCDB($cdbTag));

      foreach my $cdeTag ( sort keys %cde ) {
         my ($value, $name, $raw) = $self->_decodeCDE($cdeTag, $cde{$cdeTag});

		 if (defined $raw) {
            $writer->dataElement("cde", $value, tag=>$cdeTag, name=>$name, raw=>$raw);
		 }
		 else {
            $writer->dataElement("cde", $value, tag=>$cdeTag, name=>$name);
		 }
      }

      ### End "cdb" block
      $writer->endTag("cdb");

      ### Read number of records from Footer record
      if ($cdbTag == 1100) {
         ($recordCount) = $self->_decodeCDE(6003, $cde{6003});
      }
   }

   ### Audit check
   if ($i != $recordCount) {
      $log->logcroak("Footer does not match number of records");
   }

   ### Cleanup
   $infile->close;
   $writer->endTag("cdrs");
   $file->print("\n");
   $file->close;
}

#-------------------------------------------------------------

=head1 AUTHOR

Mark O'Connor, C<< <marko@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-convert-cisco at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Convert-Cisco>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Convert::Cisco

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Convert-Cisco>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Convert-Cisco>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Convert-Cisco>

=item * Search CPAN

L<http://search.cpan.org/dist/Convert-Cisco>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Mark O'Connor, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Convert::Cisco

__DATA__
#===========================================================================
#
# The Cisco billing record is documented on the cisco website:
#
# http://www.cisco.com/univercd/cc/td/doc/product/access/sc/rel9/billinf/r9chap1.htm
#
#===========================================================================

# Name of each Call Data Block (CDB)
CDB Names:
  1090: Header
  1100: Footer
  1010: Answer 
  1030: Abort
  1040: Release
  1060: Continue
  1110: EndOfCall

#
# Each CDE element has a different record format specfication
#
# C  - 1 Octet BE format
# n  - 2 Octet BE format
# N  - 4 Octet BE format
# H* - HEX string
# Z* - Character string (null padded)
#
CDE Records:
  3000:
    name: calling_party_category
    spec: H*
  3001:
    name: user_service_info
    spec: H*
  3003:
    name: calling_number_nature_of_address
    spec: H*
  3005:
    name: dialled_number_nature_of_address
    spec: H*
  3007:
    name: called_number_nature_of_address
    spec: H*
  3008:
    name: reason_code
    spec: H*
  3009:
    name: forward_call_indicators_received
    spec: H*
  3010:
    name: forward_call_indicators_sent
    spec: H*
  3011:
    name: nature_of_connection_indicators_received
    spec: H*
  3012:
    name: nature_of_connection_indicators_sent
    spec: H*
  3018:
    name: egress_calling_number_nature_of_address
    spec: C
  4000:
    name: version
    spec: C
  4001:
    name: timepoint
    spec: N
    format: epoch2datetime
  4002:
    name: call_reference_id
    spec: H*
  4008:
    name: originating_trunk_group
    spec: n
  4009:
    name: originating_member
    spec: n
  4010:
    name: calling_number
    spec: Z*
  4011:
    name: charged_number
    spec: Z*
  4012:
    name: dialled_number
    spec: Z*
  4014:
    name: called_number
    spec: Z*
  4015:
    name: terminating_trunk_group
    spec: n
  4016:
    name: terminating_member
    spec: n
  4019:
    name: glare_encountered
    spec: C
  4028:
    name: first_release_source
    spec: C
  4029:
    name: lnp_dip
    spec: C
  4030:
    name: total_meter_pulses
    spec: n
  4034:
    name: ingress_originating_point_code
    spec: N
  4035:
    name: ingress_destination_code
    spec: N
  4036:
    name: egress_originating_point_code
    spec: N
  4037:
    name: egress_destination_code
    spec: N
  4038:
    name: ingress_media_gateway_id
    spec: n
  4039:
    name: egress_media_gateway_id
    spec: n
  4046:
    name: ingress_packet_info
    spec: 
      - N
      - N
      - N
      - N
      - N
      - N
      - N
      - N
  4047:
    name: egress_packet_info
    spec: 
      - N
      - N
      - N
      - N
      - N
      - N
      - N
      - N
  4048:
    name: directional_flag
    spec: C
  4052:
    name: originating_gateway_primary_select
    spec: C
  4053:
    name: terminating_gateway_primary_select
    spec: C
  4066:
    name: ingress_sigpath_id
    spec: H*
  4067:
    name: ingress_span_id
    spec: H*
  4068:
    name: ingress_bearchan_id
    spec: H*
  4069:
    name: ingress_protocol_id
    spec: C
  4070:
    name: egress_sigpath_id
    spec: H*
  4071:
    name: egress_span_id
    spec: H*
  4072:
    name: egress_bearchan_id
    spec: H*
  4073:
    name: egress_protocol_id
    spec: C
  4081:
    name: fax_call
    spec: C
  4083:
    name: charge_indicator
    spec: C
  4084:
    name: outgoing_calling_party_number
    spec: Z*
  4087:
    name: ingress_mgcp_dlcx_return_code
    spec: C
  4088:
    name: egress_mgcp_dlcx_return_code
    spec: C
  4089:
    name: network_translated_address_indicator
    spec: C
  4090:
    name: reservation_request_accepted
    spec: C
  4091:
    name: reservation_request_error_count
    spec: C
  4095:
    name: route_list_name
    spec: Z*
  4096:
    name: route_name
    spec: Z*
  4098:
    name: originating_leg_dsp_stats
    spec: Z*
  4099:
    name: terminating_leg_dsp_stats
    spec: Z*
  4100:
    name: iam_timepoint_received
    spec: 
       - N
       - n
    format: compoundEpoch2datetime
  4101:
    name: iam_timepoint_sent
    spec: 
       - N
       - n
    format: compoundEpoch2datetime
  4102:
    name: acm_timepoint_received
    spec: 
       - N
       - n
    format: compoundEpoch2datetime
  4103:
    name: acm_timepoint_sent
    spec: 
       - N
       - n
    format: compoundEpoch2datetime
  4106:
    name: first_rel_timepoint_ms
    spec: 
       - N
       - n
    format: compoundEpoch2datetime
  4107:
    name: second_rel_timepoint_ms
    spec: 
       - N
       - n
    format: compoundEpoch2datetime
  4108:
    name: rlc_timepoint_received
    spec: 
       - N
       - n
    format: compoundEpoch2datetime
  4109:
    name: rlc_timepoint_sent
    spec: 
       - N
       - n
    format: compoundEpoch2datetime
  4213:
    name: meter_pulse_received
    spec: N
  4214:
    name: meter_pulse_sent
    spec: N
  4217:
    name: short_call_indicator
    spec: C
  5000:
    name: unique_call_correlator_id
    spec: H*
  6000:
    name: source
    spec: Z*
  6001:
    name: file_start_time
    spec: N
    format: epoch2datetime
  6002:
    name: file_end_time
    spec: N
    format: epoch2datetime
  6003:
    name: record_count
    spec: N
  6004:
    name: version
    spec: Z*
  6005:
    name: interim_cdb
    spec: C
