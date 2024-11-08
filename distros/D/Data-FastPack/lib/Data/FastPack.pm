package Data::FastPack;
use strict;
use warnings;

our $VERSION="v0.0.1";

use feature ":all";
no warnings "experimental";
use Export::These qw<decode_fastpack encode_fastpack decode_message encode_message FP_MSG_TIME FP_MSG_ID FP_MSG_PAYLOAD FP_MSG_TOTAL_LEN>;



use constant::more <FP_MSG_{TIME=0,ID,PAYLOAD,TOTAL_LEN}>;

# routine indicating the required size of a buffer to store the requested
# payload length
#
sub size_message {
  my $payload_size=shift;
		my$padding=($payload_size%8);
    $padding= 8-$padding  if $padding;

    #return the total length of the head, payload and padding
    16+$payload_size+$padding;
}

#passing arrays of arrays, [time, info, payload] Computes padding, appends
#the serialized data to the supplied buffer, and sets the length.  If id
#has MORE bit set, at least one more messags to follow (at some point).
#$buf, [$time, $id, $data]
#
my $pbuf= pack "x8";


=over 

=item encode_message

=item encode_fastpack

Encodes an array of fast pack message structures into an buffer

Buffer is aliased and is an in/out parameter. Encoded data is appended to the buffer.

Inputs is an array of message structure (also array refs). Array is consumed 

An optional limit can be sepecified on how many messages to encode in a single call

Returns the number of bytes encoded


=back

=cut

sub encode_message {
  \my $buf=\$_[0]; shift;
  my $inputs=shift;
  my $limit=shift;

  $limit//=@$inputs;
  my $bytes=0;
  my $processed=0;
	my $padding;
  my $tmp;
  
  my $flags=0;

	for(@$inputs){
		$padding=((length $_->[FP_MSG_PAYLOAD])%8);
    $padding= 8-$padding  if $padding;

		my $s=pack("d V V/a*", @$_);
    $tmp=$s.substr $pbuf, 0, $padding;
    $bytes+=length $tmp;
		$buf.=$tmp;
    last if ++$processed == $limit;
	}
  # Remove the messages from the input array
  splice @$inputs, 0, $processed;
  
  $bytes;	
}

*encode_fastpack=\&encode_message;

# Decode a message from a buffer. Buffer is aliased
=over

=item decode_message

=item decode_fastpack

Consumes data from an input buffer and decodes it into 0 or more messages.
Buffer is aliased and is an in/out parameter
Decoded messages are added to the dereferenced output array
An optional limit of message count can be specified.

Returns the number of bytes consumed during decoding. I a message could not be
decoded, 0 bytes are consumed.

  buffer (aliased) 
  output (array ref)
  limit (numeric)

  return (byte count)


=back 

=cut

sub decode_message {
  \my $buf=\$_[0]; shift;
  my $output=shift;
  my $limit=shift//4096;

  my $byte_count=0;
  for(1..$limit){
    # Minimum message length 8 bytes long (header)
    last if length($buf)<16;

    # Decode  header. Leave length for in buffer
    my @message= unpack "d V V", substr($buf, 0, 16);



    # Calculate pad. Payload in message here is actuall just length atm
    my $pad= $message[FP_MSG_PAYLOAD]%8;
    $pad=8-$pad if $pad;

    # Calculate total length
    my $total=$message[FP_MSG_PAYLOAD]+16+$pad;

    last if(length($buf)<$total);




    $byte_count+=$total;


    ($message[FP_MSG_PAYLOAD],undef)=unpack "V/a* ", substr($buf,12);
    push @message, $total;

    # remove from buffer
    substr($buf, 0, $total,"");
    push @$output, \@message;
  }
  $byte_count;
}

*decode_fastpack=\&decode_message;


1;
