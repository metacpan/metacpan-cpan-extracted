package App::EvalServerAdvanced::Protocol;
use strict;
use warnings;

our $VERSION = '0.105';
# ABSTRACT: Protocol abstraction for App::EvalServerAdvanced 
my $protocol_version = 1;

use v5.24.0;
no warnings 'experimental';

use Google::ProtocolBuffers::Dynamic;
use Path::Tiny qw/path/;
use Function::Parameters;
use Encode qw/encode decode/;

use Exporter 'import';
our @EXPORT = qw/decode_message encode_message/;

my $path = path(__FILE__)->parent->child("protocol.proto");

# load_file tries to allocate >100TB of ram.  Not sure why, so we'll just read it ourselves
my $proto = $path->slurp_utf8;

my $gpb = Google::ProtocolBuffers::Dynamic->new();

$gpb->load_string("protocol.proto", $proto);

$gpb->map({ pb_prefix => "messages", prefix => "App::EvalServerAdvanced::Protocol", options => {accessor_style => 'single_accessor'} });

fun handle_encoding($type, $obj) {
    given($type) {
        when("eval") {
            for my $file ($obj->{files}->@*) {
                my $f_encoding = $file->{encoding};

                if (defined $f_encoding && $f_encoding ne "raw" && $f_encoding ne "") {
                    $file->{contents} = encode($f_encoding, $file->{contents});
                }
            }
        }
        when("warning") {
            if ($obj->{encoding}) {
                $obj->{message} = encode($obj->{encoding}, $obj->{message});
            }
        }
        when("response") {
            if ($obj->{encoding}) {
                $obj->{contents} = encode($obj->{encoding}, $obj->{contents});
            }
        }
    }
}

fun encode_message($type, $obj) {
    handle_encoding($type, $obj);
    my $message = App::EvalServerAdvanced::Protocol::Packet->encode({$type => $obj});

    # 8 byte header, 0x0000_0001 0x1234_5678
    # first 4 bytes are the protocol version, last 4 are length of the message in octets
    my $header = pack "NN", $protocol_version, length($message);
    return ($header . $message);
};

fun decode_message($buffer) {
    return (0, undef, undef) if length $buffer < 8; # can't have a message without a header

    my $header = substr($buffer, 0, 8); # grab the header
    my ($reserved, $length) = unpack("NN", $header);

    die "Undecodable header" if ($reserved != $protocol_version);
    
    # Packet isn't ready yet
    return (0, undef, $buffer) if (length($buffer) - 8 < $length);

    my $message_bytes = substr($buffer, 8, $length);
    substr($buffer, 0, $length+8, "");

    my $message = App::EvalServerAdvanced::Protocol::Packet->decode($message_bytes);
    my ($k) = keys %$message;

    die "Undecodable message" unless ($k);
    my $real_message = $message->$k;

    return (1, $real_message, $buffer);
};

package 
    App::EvalServerAdvanced::Protocol::EvalResponse;
use Encode qw//;

method get_contents() {
    if ($self->encoding && $self->encoding ne "raw") {
        return Encode::decode($self->encoding, $self->contents);
    }
    return $self->contents;
}

package
    App::EvalServerAdvanced::Protocol::Eval::File;
use Encode qw//;

method get_contents() {
    if ($self->encoding && $self->encoding ne "raw") {
        return Encode::decode($self->encoding, $self->contents);
    }
    return $self->contents;
}


    # given($type) {
    #     when("Eval") {
    #         # I can't decide if I should decode these or not.  Keeping them as raw bytes seems safer
    #         # for my $file ($obj->files->@*) {
    #         #     my $f_encoding = $file->encoding;

    #         #     if ($f_encoding ne "raw" && $f_encoding ne "") {
    #         #         $file->contents(decode($f_encoding, $file->contents));
    #         #     }
    #         # }            
    #     }


1;
