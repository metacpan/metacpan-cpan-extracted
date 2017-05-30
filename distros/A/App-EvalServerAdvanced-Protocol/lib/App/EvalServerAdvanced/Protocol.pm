package App::EvalServerAdvanced::Protocol;
our @VERSION = 0.100;
# ABSTRACT: Protocol abstraction for App::EvalServerAdvanced 

use strict;
use warnings;
use Google::ProtocolBuffers::Dynamic;
use Path::Tiny qw/path/;
use Function::Parameters;

use Exporter 'import';
our @EXPORT = qw/decode_message encode_message/;

my $path = path(__FILE__)->parent->child("protocol.proto");

# load_file tries to allocate >100TB of ram.  Not sure why, so we'll just read it ourselves
my $proto = $path->slurp_raw;

my $gpb = Google::ProtocolBuffers::Dynamic->new();

$gpb->load_string("protocol.proto", $proto);

$gpb->map({ pb_prefix => "messages", prefix => "App::EvalServerAdvanced::Protocol", options => {accessor_style => 'single_accessor'} });

fun encode_message($type, $obj) {
    my $message = App::EvalServerAdvanced::Protocol::Packet->encode({$type => $obj});

    # 8 byte header, 0x0000_0000 0x1234_5678
    # first 4 bytes are reserved for future fuckery, last 4 are length of the message in octets
    my $header = pack "NN", 0, length($message);
    return ($header . $message);
};

fun decode_message($buffer) {
    return (0, undef, undef) if length $buffer < 8; # can't have a message without a header

    my $header = substr($buffer, 0, 8); # grab the header
    my ($reserved, $length) = unpack("NN", $header);

    die "Undecodable header" if ($reserved != 0);
    
    # Packet isn't ready yet
    return (0, undef, undef) if (length($buffer) - 8 < $length);

    my $message_bytes = substr($buffer, 8, $length);
    substr($buffer, 0, $length+8, "");

    my $message = App::EvalServerAdvanced::Protocol::Packet->decode($message_bytes);
    my ($k) = keys %$message;

    die "Undecodable message" unless ($k);

    return (1, $message->$k, $buffer);
};

1;
