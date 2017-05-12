use strict;
use warnings;

use Test::More;
use Crypt::Password::StretchedHash qw(
    crypt_with_hashinfo
    verify_with_hashinfo
);
use Digest::SHA;
use lib 't/lib';
use TestHashInfo;

TEST_TESTHASHINFO: {
    my $hash_info = TestHashInfo->new;
    ok( $hash_info, q{TestHashInfo} );
};

TEST_CRYPT_WITH_HASHINFO: {
    my $hash_info = TestHashInfo->new;
    $hash_info->set_delimiter(q{$});
    $hash_info->set_identifier(q{1});
    $hash_info->set_hash(Digest::SHA->new("sha256"));
    $hash_info->set_salt(q{test_salt_1234567890});
    $hash_info->set_stretch_count(5000);
    $hash_info->set_format(q{base64});

    my $pwhash = crypt_with_hashinfo(
        password    => q{password},
        hash_info   => $hash_info,
    );
    ok( $pwhash, q{pwhash is returned});
    is( $pwhash, q{$1$dGVzdF9zYWx0XzEyMzQ1Njc4OTA=$6t8PoejG3He/QujMmN1MpBi5iwNY9t0mdl+OHOwceo0=}, q{pwhash is matched} );

    # delimiter
    $hash_info->set_delimiter(q{%});
    $pwhash = crypt_with_hashinfo(
        password    => q{password},
        hash_info   => $hash_info,
    );
    ok( $pwhash, q{pwhash is returned});
    is( $pwhash, q{%1%dGVzdF9zYWx0XzEyMzQ1Njc4OTA=%6t8PoejG3He/QujMmN1MpBi5iwNY9t0mdl+OHOwceo0=}, q{delimiter} );
    $hash_info->set_delimiter(q{$});

    # identifier
    $hash_info->set_identifier(q{2});
    $pwhash = crypt_with_hashinfo(
        password    => q{password},
        hash_info   => $hash_info,
    );
    ok( $pwhash, q{pwhash is returned});
    is( $pwhash, q{$2$dGVzdF9zYWx0XzEyMzQ1Njc4OTA=$6t8PoejG3He/QujMmN1MpBi5iwNY9t0mdl+OHOwceo0=}, q{identifier} );
    $hash_info->set_identifier(q{1});

    # hash
    $hash_info->set_hash(Digest::SHA->new("sha512"));
    $pwhash = crypt_with_hashinfo(
        password    => q{password},
        hash_info   => $hash_info,
    );
    ok( $pwhash, q{pwhash is returned});
    is( $pwhash, q{$1$dGVzdF9zYWx0XzEyMzQ1Njc4OTA=$4V/aqHXUQKExBIoUOkaAON/6735mL7zXdu6Zpby0237bXxnZfGjc5ocdkeLJjsqUMxMwa/5vyw+1lCcxaQJUBA==}, q{hash} );
    $hash_info->set_hash(Digest::SHA->new("sha256"));

    # salt
    $hash_info->set_salt(q{test_salt2_1234567890});
    $pwhash = crypt_with_hashinfo(
        password    => q{password},
        hash_info   => $hash_info,
    );
    ok( $pwhash, q{pwhash is returned});
    is( $pwhash, q{$1$dGVzdF9zYWx0Ml8xMjM0NTY3ODkw$Uah1f76DiyXz/l9vPcYrhPNhDh3EDfc+npYDMT4DKe0=}, q{salt} );
    $hash_info->set_salt(q{test_salt_1234567890});

    # stretch_count
    $hash_info->set_stretch_count(q{1000});
    $pwhash = crypt_with_hashinfo(
        password    => q{password},
        hash_info   => $hash_info,
    );
    ok( $pwhash, q{pwhash is returned});
    is( $pwhash, q{$1$dGVzdF9zYWx0XzEyMzQ1Njc4OTA=$fpq0X06qxQg/e4UR2DnaRyU7vPHgXO0V5A7Puy0q5jQ=}, q{stretch_count} );
    $hash_info->set_stretch_count(q{5000});

    # format : hex
    $hash_info->set_format(q{hex});
    $pwhash = crypt_with_hashinfo(
        password    => q{password},
        hash_info   => $hash_info,
    );
    ok( $pwhash, q{pwhash is returned});
    is( $pwhash, q{$1$746573745f73616c745f31323334353637383930$eadf0fa1e8c6dc77bf42e8cc98dd4ca418b98b0358f6dd26765f8e1cec1c7a8d}, q{format is hex} );
    $hash_info->set_format(q{base64});
};

TEST_VERIFY_WITH_HASHINFO: {
    my $hash_info = TestHashInfo->new;
    $hash_info->set_delimiter(q{$});
    $hash_info->set_identifier(q{1});
    $hash_info->set_hash(Digest::SHA->new("sha256"));
    $hash_info->set_salt(q{test_salt_1234567890});
    $hash_info->set_stretch_count(5000);
    $hash_info->set_format(q{base64});

    my $result = verify_with_hashinfo(
        password        => q{password},
        password_hash   => q{invalid_password_hash},
        hash_info       => $hash_info,
    );
    ok( !$result, q{password is not matched});

    $result = verify_with_hashinfo(
        password        => q{password},
        password_hash   => q{$1$dGVzdF9zYWx0XzEyMzQ1Njc4OTA=$6t8PoejG3He/QujMmN1MpBi5iwNY9t0mdl+OHOwceo0=},
        hash_info       => $hash_info,
    );
    ok( $result, q{password is matched});

    $result = verify_with_hashinfo(
        password        => q{password},
        password_hash   => q{$$dGVzdF9zYWx0XzEyMzQ1Njc4OTA=$6t8PoejG3He/QujMmN1MpBi5iwNY9t0mdl+OHOwceo0=},
        hash_info       => $hash_info,
    );
    ok( !$result, q{no identifier});

    $result = verify_with_hashinfo(
        password        => q{password},
        password_hash   => q{$1$$6t8PoejG3He/QujMmN1MpBi5iwNY9t0mdl+OHOwceo0=},
        hash_info       => $hash_info,
    );
    ok( !$result, q{no salt});

    $result = verify_with_hashinfo(
        password        => q{password},
        password_hash   => q{$1$dGVzdF9zYWx0XzEyMzQ1Njc4OTA=$},
        hash_info       => $hash_info,
    );
    ok( !$result, q{no password hash});

    $hash_info->set_delimiter(q{%});
    $result = verify_with_hashinfo(
        password        => q{password},
        password_hash   => q{$1$dGVzdF9zYWx0XzEyMzQ1Njc4OTA=$6t8PoejG3He/QujMmN1MpBi5iwNY9t0mdl+OHOwceo0=},
        hash_info       => $hash_info,
    );
    ok( !$result, q{delimiter is different});
    $hash_info->set_delimiter(q{$});
    
    $hash_info->set_identifier(q{2});
    $result = verify_with_hashinfo(
        password        => q{password},
        password_hash   => q{$1$dGVzdF9zYWx0XzEyMzQ1Njc4OTA=$6t8PoejG3He/QujMmN1MpBi5iwNY9t0mdl+OHOwceo0=},
        hash_info       => $hash_info,
    );
    ok( !$result, q{identifier is different});
    $hash_info->set_identifier(q{1});
    
    $hash_info->set_hash(Digest::SHA->new("sha512"));
    $result = verify_with_hashinfo(
        password        => q{password},
        password_hash   => q{$1$dGVzdF9zYWx0XzEyMzQ1Njc4OTA=$6t8PoejG3He/QujMmN1MpBi5iwNY9t0mdl+OHOwceo0=},
        hash_info       => $hash_info,
    );
    ok( !$result, q{hash function is different});
    $hash_info->set_hash(Digest::SHA->new("sha256"));

    $result = verify_with_hashinfo(
        password        => q{password},
        password_hash   => q{$1$dGVzdF9zYWx0Ml8xMjM0NTY3ODkw$6t8PoejG3He/QujMmN1MpBi5iwNY9t0mdl+OHOwceo0=},
        hash_info       => $hash_info,
    );
    ok( !$result, q{salt is different});

    $hash_info->set_stretch_count(4999);
    $result = verify_with_hashinfo(
        password        => q{password},
        password_hash   => q{$1$dGVzdF9zYWx0XzEyMzQ1Njc4OTA=$6t8PoejG3He/QujMmN1MpBi5iwNY9t0mdl+OHOwceo0=},
        hash_info       => $hash_info,
    );
    ok( !$result, q{stretch_count is different});
    $hash_info->set_stretch_count(5000);

    $hash_info->set_format(q{hex});
    $result = verify_with_hashinfo(
        password        => q{password},
        password_hash   => q{$1$dGVzdF9zYWx0XzEyMzQ1Njc4OTA=$6t8PoejG3He/QujMmN1MpBi5iwNY9t0mdl+OHOwceo0=},
        hash_info       => $hash_info,
    );
    ok( !$result, q{format is different});
    $hash_info->set_format(q{base64});

};

done_testing;
