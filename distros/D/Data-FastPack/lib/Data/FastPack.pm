package Data::FastPack;
use strict;
use warnings;

our $VERSION="v0.2.0";

use feature ":all";
no warnings "experimental";
use Export::These qw<decode_fastpack encode_fastpack decode_message encode_message create_namespace name_for_id id_for_name FP_MSG_TIME FP_MSG_ID FP_MSG_PAYLOAD FP_MSG_TOTAL_LEN>;



use constant::more <FP_MSG_{TIME=0,ID,PAYLOAD,TOTAL_LEN}>;

use constant::more <FP_NS_{ID=0,SPACE,PARENT,NAME,USER}>;
use constant::more qw<N2E=0 I2E NEXT_ID FREE_ID>;
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

sub encode_message;
sub encode_message {
  \my $buf=\$_[0]; shift;
  my $inputs=shift;
  my $limit=shift;
  my $ns=shift;  # if name space is present. the id is taken as a name. Even though this could be numeric,
                 # It is then looked up from a dynamic table
                 # If it found, the allocated number is use.
                 # if is not, a system message with the table entry is created and set along with it.

  $limit//=@$inputs;
  my $bytes=0;
  my $processed=0;
	my $padding;
  my $tmp;
  
  my $flags=0;
  # Loop through and do namespace name to id conversion
  if($ns){
    for(@$inputs){
      # NOTE: messages with "0" and 0 and undef are ignored
      if($_->[FP_MSG_ID]){
        my $name=$_->[FP_MSG_ID];
        # Convert to id if ns is present and ID is NOT 0
        my $id=$ns->[N2E]{$name};
        unless (defined $id){
          if(defined $_->[FP_MSG_PAYLOAD]){
            # Update id tracking and lookup tables
            $id=pop($ns->[FREE_ID]->@*)//$ns->[NEXT_ID]++;
            $ns->[N2E]{$name}=$id;
            $ns->[I2E]{$id}=$name;

            # encode definition into buffer
            $bytes+=encode_message $buf, [[$_->[FP_MSG_TIME], $id, $name ]];
          }
          else {
            # A message with no payload is an unregistration
            # Remove the entry from the tabe
            #
            delete $ns->[N2E]{$name};
            delete $ns->[I2E]{$id};
            push $ns->[FREE_ID]->@*, $id;
          }
        }
        $_->[FP_MSG_ID]=$id;
      }
      else {
        # If the msg id is 0 this  is passed thourgh un modified and not name translated. 
        #
        #warn 'FastPack encode: Ignoring message. Named FastPack Messages cannot be named 0 or "0" or undefined';
      }
    }
  }

  # Do normal encoding
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
  my $ns=shift;

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

    # Process name space definitions and lookups
    if($ns and $message[FP_MSG_ID]){
      
      # This is a non system message which needs conversion 
      my $id=$message[FP_MSG_ID];
      my $name= $ns->[I2E]{$id};
      unless($name){
        # This id has not been seen before. so we know the payload it the name
        $name=$message[FP_MSG_PAYLOAD];
        $ns->[I2E]{$id}=$name;
        $ns->[N2E]{$name}=$id;
      }
      else {
        if($message[FP_MSG_PAYLOAD]){

          # only push the message to output if this code has been seen before
          push @$output, \@message;
          # Finally convert id to name as we asked for named message
          $message[FP_MSG_ID]=$name;
        }
        else {
          delete $ns->[N2E]{$name};
          delete $ns->[I2E]{$id};
          push $ns->[FREE_ID]->@*, $id;
        }
      }
    }
    else {
     push @$output, \@message;
    }
  }
  $byte_count;
}

*decode_fastpack=\&decode_message;

sub create_namespace {
  [{},{}, 1, []];
}

sub id_for_name {

  my $ns=shift;
  my $name=shift;
  $ns->[N2E]{$name};
}

sub name_for_id {
  my $ns=shift;
  my $id=shift;
  $ns->[I2E]{$id};

}


1;
