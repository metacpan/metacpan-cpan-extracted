=head1 NAME

Data::FastPack::Meta - Encode/decode rourines for fastpack meta data message payloads

=cut

package Data::FastPack::Meta;
use strict;
use warnings;

use Export::These qw<encode_meta_payload decode_meta_payload>;

# Meta / structured data encoding and decoding
# ============================================
#
# Structured or meta data messages are always of id 0. They
#

use Cpanel::JSON::XS;
use Data::MessagePack;

my $mp=Data::MessagePack->new();
$mp->prefer_integer(1);
$mp->utf8(1);

# Arguments: $payload, force_mp Forcing message pack decode is only needed if
# the encoded data is not of map or array type. Otherise automatic decoding is
# best
sub decode_meta_payload {
	my ($payload,$force_mp)=@_;
	my $decodedMessage;
  
	for(unpack("C", $payload)) {
		if (!$force_mp and ($_== 0x5B || $_== 0x7B)) {
			#JSON encoded string
			$decodedMessage=decode_json($payload);
		}
    else { 
			#msgpack encoded
			$decodedMessage=$mp->unpack($payload);
		}
	}
	$decodedMessage;
}

# Arguments: payload, force_mp
sub encode_meta_payload {
  $_[1]?$mp->encode($_[0]):encode_json($_[0]);
}
1;
