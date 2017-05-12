package ECDSAKeyTest;

use strict;
use warnings;

use Test::More;

use parent qw(
    TestClass
);

#This has hybrid public and base points and so is good for testing
#hybrid parsing.
use constant PEM_FOR_COMPRESSED_TEST => <<END;
-----BEGIN EC PRIVATE KEY-----
MIIBaAIBAQQgxp3p5ut4rOq3yM/QYC7OpyWDBQyLiOxxQnneOpiavsaggfowgfcC
AQEwLAYHKoZIzj0BAQIhAP////8AAAABAAAAAAAAAAAAAAAA////////////////
MFsEIP////8AAAABAAAAAAAAAAAAAAAA///////////////8BCBaxjXYqjqT57Pr
vVV2mIa8ZR0GsMxTsPY7zjw+J9JgSwMVAMSdNgiG5wSTamZ44ROdJreBn36QBEEH
axfR8uEsQkf4vOblY6RA8ncDfYEt6zOg9KE5RdiYwpZP40Li/hp/m47n60p8D54W
K84zV2sxXs7LtkBoN79R9QIhAP////8AAAAA//////////+85vqtpxeehPO5ysL8
YyVRAgEBoUQDQgAGRWiv/yjXvsCl0pGfNJ/qV5ya42dAu8LcZxQY8/q15BJbo09f
c7esddpYiQoziP/IVhwoJz2xFbzJSGeYCfzmeA==
-----END EC PRIVATE KEY-----
END

sub test_compressed : Tests(9) {
    my ($self) = @_;

    my $key_obj = $self->_key_for_test_compressed(PEM_FOR_COMPRESSED_TEST());

    my $pub_x_hex = '4568afff28d7bec0a5d2919f349fea579c9ae36740bbc2dc671418f3fab5e412';
    my $pub_y_hex = '5ba34f5f73b7ac75da58890a3388ffc8561c28273db115bcc948679809fce678';

    my $pr_uncompressed = unpack 'H*', $key_obj->to_der_with_curve_name();
    my $pr_compressed = unpack 'H*', $key_obj->to_der_with_curve_name(compressed => 1);

    like( $pr_uncompressed, qr<$pub_y_hex>, 'named: uncompressed has the public Y component' );
    unlike( $pr_compressed, qr<$pub_y_hex>, 'named: compressed lacks the public Y component' );

    like( $pr_compressed, qr<02$pub_x_hex>, 'named: compressed includes the public X with correct prefix' );

    #----------------------------------------------------------------------

    $pr_uncompressed = unpack 'H*', $key_obj->to_der_with_explicit_curve();
    $pr_compressed = unpack 'H*', $key_obj->to_der_with_explicit_curve(compressed => 1);

    like( $pr_uncompressed, qr<$pub_y_hex>, 'explicit: uncompressed has the public Y component' );
    unlike( $pr_compressed, qr<$pub_y_hex>, 'explicit: compressed lacks the public Y component' );

    like( $pr_compressed, qr<02$pub_x_hex>, 'explicit: compressed includes the public X with correct prefix' );

    my $curve_data = Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_name('prime256v1');
    my $gy_hex = substr( $curve_data->{'gy'}->as_hex(), 2 );

    like( $pr_uncompressed, qr<$gy_hex>, 'explicit: uncompressed has the base Y component' );
    unlike( $pr_compressed, qr<$gy_hex>, 'explicit: compressed lacks the base Y component' );

    my $gx_hex = substr( $curve_data->{'gx'}->as_hex(), 2 );
    like( $pr_compressed, qr<03$gx_hex>, 'explicit: compressed includes the base X with correct prefix' );

    return;
}

1;
