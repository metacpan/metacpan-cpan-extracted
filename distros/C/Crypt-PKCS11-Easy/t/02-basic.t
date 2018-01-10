use lib 't/lib';
use Test::Roo;
use Test::Fatal;

use Path::Tiny;

with 'CommonTest';

sub BUILD {
    my $self = shift;

    if (!$self->has_softhsm2) {
        plan skip_all => 'SoftHSM2 is required to run these tests';
    }

}

test info => sub {
    my $self = shift;

    ok my $info = $self->pkcs11->get_info;
    isa_ok $info, 'HASH';
    is_deeply [sort keys %$info],
      [qw/cryptokiVersion libraryDescription libraryVersion manufacturerID/],
      'Keys are as expected';
    is $info->{manufacturerID}, 'SoftHSM', 'Correct manufacturerID';
};

test slots => sub {
    my $self = shift;

    ok my $slots = $self->pkcs11->get_slots;
    isa_ok $slots, 'ARRAY';
    is scalar @$slots, 2, 'softhsm always has at least one token';

    $self->clear_pkcs11;

    ok $slots = $self->pkcs11->get_slots;

    isa_ok $slots, 'ARRAY';
    is scalar @$slots, 2, 'There are now two tokens';

    like(
        exception { $self->pkcs11->get_slot(label => 'test_keys_1') },
        qr/Missing id or token/,
        'Failed to find slot using invalid args',
    );

    like(
        exception { $self->pkcs11->get_slot(token => 'nosuchtoken') },
        qr/Unable to find slot containing token labelled/,
        'Failed to find slot using invalid args',
    );

    my $slot;
    is(
        exception { $slot = $self->pkcs11->get_slot(token => 'test_keys_1') },
        undef,
        'Found token by label',
    );

    my $slot2;
    is(
        exception { $slot2 = $self->pkcs11->get_slot(id => $slot->{id}) },
        undef, 'Found token by id',
    );

    is_deeply $slot, $slot2, 'Slots are the same';
};

test get_mechs => sub {
    my $self = shift;
    ok my $slot = $self->pkcs11->get_slot(token => 'test_keys_1');

    my $mechs = $self->pkcs11->get_mechanisms($slot->{id});
    isa_ok $mechs, 'HASH';

};

test signing_and_verifying => sub {
    my $self = shift;

    my $data_file = path 't/data/10K.file';
    my $key_file  = path 't/keys/1024_sign.pem';

    my $pkcs11 = $self->_new_pkcs11(key => 'signing_key');

    ok my $sig = $pkcs11->sign(file => $data_file);
    my $ossl_sig = $self->openssl_sign($key_file, $data_file);

    is $sig, $ossl_sig, 'Signing produced same sig as openssl';

    # save the sig to verify with openssl later
    my $sig_file = $self->workdir->child($data_file->basename . '.sig');
    $sig_file->spew_raw($sig);

    ok my $enc_sig = $pkcs11->sign_and_encode(file => $data_file);
    my $expected_sig = q{-----BEGIN SIGNATURE-----
mjNMN4+Xf7PNsDGXjzyentTLSs1JI8G55Bbr+rBvHvDl9sOgFZTh9ZjTM1ekVcTN
mUwq3aC/GjFW+pOLRYevQ2UwJiZmcVtP4nDD9Vt/exZS/ggM4HnaoGm8QyGnhlk3
77J68o6bq2ilVIUxhTn2WzwZN/Se+5PuCCIomcy2OEY=
-----END SIGNATURE-----
};

    is $enc_sig, $expected_sig, 'Encoded sigs are good';

    $pkcs11 = undef;
    $pkcs11 = $self->_new_pkcs11(key => 'signing_key', function => 'verify');
    ok $pkcs11->verify(sig => $sig, file => $data_file), 'verified signature';

    $key_file = path 't/keys/1024_sign_pub.pem';
    ok $self->openssl_verify($key_file, $sig_file, $data_file);
};

test encryption => sub {
    my $self = shift;

    my $data_file = path 't/data/64B.file';

    for my $mech (qw/RSA_PKCS RSA_PKCS_OAEP/) {
        my $pkcs11 = $self->_new_pkcs11(
            key      => 'encryption_key',
            function => 'encrypt'
        );
        ok my $encrypted_data =
          $pkcs11->encrypt(file => $data_file, mech => $mech),
          "Encrypted with mech $mech";

        my $private_key_file = path 't/keys/1024_enc.pem';
        ok my $decrypted_data =
          $self->openssl_decrypt($private_key_file, $encrypted_data, $mech),
          'Decrypted using openssl';
        is $decrypted_data, $data_file->slurp_raw, 'Successful round-trip';
    }

};

run_me;
done_testing;
