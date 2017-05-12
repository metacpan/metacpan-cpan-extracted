package MockIdP;

use strict;
use warnings;

use parent 'Authen::NZRealMe::IdentityProvider';

use MIME::Base64 qw(encode_base64);
use Digest::SHA  qw(sha1);


use AuthenNZRealMeTestHelper;

sub make_artifact {
    my($self, $test_file_index) = @_;

    my $type_code   = 4;
    my $index       = 0;
    my $source_id   = sha1( $self->entity_id );
    my $msg_handle  = sprintf('%020u', $test_file_index);
    my $artifact = pack('nna20a20', $type_code, $index, $source_id, $msg_handle);
    return encode_base64($artifact, '');
}

1;

