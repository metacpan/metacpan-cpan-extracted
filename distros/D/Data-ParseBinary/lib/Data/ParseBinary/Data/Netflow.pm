package Data::ParseBinary::Data::Netflow;

use strict;
use warnings;
use Data::ParseBinary;

our $netflow_v5_parser = Struct("nfv5_header",
	Const(UBInt16("version"), 5),
	UBInt16("count"),
	UBInt32("sys_uptime"),
	UBInt32("unix_secs"),
	UBInt32("unix_nsecs"),
	UBInt32("flow_seq"),
	UBInt8("engine_type"),
	UBInt8("engine_id"),
	Padding(2),
	Array(sub { $_->ctx->{count} },
		Struct("nfv5_record",
			Data::ParseBinary::lib::DataNetflow::IPAddr->create(
				UBInt32("src_addr")
			),
			Data::ParseBinary::lib::DataNetflow::IPAddr->create(
				UBInt32("dst_addr")
			),
			Data::ParseBinary::lib::DataNetflow::IPAddr->create(
			UBInt32("next_hop")
			),
			UBInt16("i_ifx"),
			UBInt16("o_ifx"),
			UBInt32("packets"),
			UBInt32("octets"),
			UBInt32("first"),
			UBInt32("last"),
			UBInt16("s_port"),
			UBInt16("d_port"),
			Padding(1),
			UBInt8("flags"),
			UBInt8("prot"),
			UBInt8("tos"),
			UBInt16("src_as"),
			UBInt16("dst_as"),
			UBInt8("src_mask"),
			UBInt8("dst_mask"),
			UBInt16("unused2")),
	),
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($netflow_v5_parser);

package Data::ParseBinary::lib::DataNetflow::IPAddr;

use Socket qw(inet_ntoa inet_aton);

our @ISA;
BEGIN { @ISA = qw{Data::ParseBinary::Adapter}; }

sub _decode {
	my ($self, $value) = @_;
	return inet_ntoa(pack('N',$value));
}

sub _encode {
	my ($self, $value) = @_;
	return sprintf("%d", unpack('N',inet_aton($value)));
}
1;

=head1 NAME

Data::ParseBinary::Data::Netflow - Parsing Netflow PDU binary structures

=head1 SYNOPSIS

    use Data::ParseBinary::Data::Netflow qw($netflow_v5_parser);
    $data = $netflow_v5_parser->parse(CreateStreamReader(File => $fh));
    # If file contain multiple flows, parse them till EOF
    while () {
	last if eof($fh);
	$data = $netflow_v5_parser->parse(CreateStreamReader(File => $fh));
    }	

=head1 CAVEAT

As for this moment version 5 format is supported only.
Read files only in network byte order (BE).

This is a part of the Data::ParseBinary package, and is just one ready-made parser.
please go to the main page for additional usage info.

=cut