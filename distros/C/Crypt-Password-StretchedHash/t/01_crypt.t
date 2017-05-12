use strict;
use warnings;

use Test::More;
use Crypt::Password::StretchedHash qw(
    crypt
);
use Digest::SHA;
use Digest::SHA3;
use MIME::Base64 qw(
    encode_base64
);

sub manual_crypt_sha256 {
    my $hash = Digest::SHA->new("sha256");
    my $pwhash = q{};
    my $password = q{password};
    my $salt = q{salt};

    for (1..5000) {
        $hash->add( $pwhash, $password, $salt );
        $pwhash = $hash->digest;
    }

    $pwhash = encode_base64( $pwhash );
    chomp($pwhash);
    return $pwhash;
}

TEST_CRYPT_MONDATORY: {

    my $pwhash = Crypt::Password::StretchedHash::crypt(
        password        => q{password},
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5000,
    );
    ok($pwhash, q{password hash is returned});
    $pwhash = encode_base64( $pwhash );
    chomp($pwhash);
    my $expected =  manual_crypt_sha256;
    is($pwhash, $expected);

    $pwhash = crypt(
        password        => q{password},
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5000,
    );
    ok($pwhash, q{password hash is returned});
    $pwhash = encode_base64( $pwhash );
    chomp($pwhash);
    is($pwhash, $expected);

};

TEST_CRYPT_VALIDATE: {

    my $pwhash;
    # mondatory
    eval {
        $pwhash = crypt(
            hash            => Digest::SHA->new("sha256"),
            salt            => q{salt},
            stretch_count   => 5000,
        );
    };
    ok($@, q{error has returned.});

    eval {
        $pwhash = crypt(
            password        => q{password},
            salt            => q{salt},
            stretch_count   => 5000,
        );
    };
    ok($@, q{error has returned.});

    eval {
        $pwhash = crypt(
            password        => q{password},
            hash            => Digest::SHA->new("sha256"),
            stretch_count   => 5000,
        );
    };
    ok($@, q{error has returned.});

    eval {
        $pwhash = crypt(
            password        => q{password},
            hash            => Digest::SHA->new("sha256"),
            salt            => q{salt},
        );
    };
    ok($@, q{error has returned.});

    # password is not SCALAR
    eval {
        $pwhash = crypt(
            password        => qw{password1 password2},
            hash            => Digest::SHA->new("sha256"),
            salt            => q{salt},
            stretch_count   => 5000,
        );
    };
    ok($@, q{error has returned.});

    # hash is not Digest::SHAx
    eval {
        $pwhash = crypt(
            password        => q{password},
            hash            => q{scalar text},
            salt            => q{salt},
            stretch_count   => 5000,
        );
    };
    ok($@, q{error has returned.});

    # salt is not SCALAR
    eval {
        $pwhash = crypt(
            password        => q{password},
            hash            => Digest::SHA->new("sha256"),
            salt            => qw{salt1 salt2},
            stretch_count   => 5000,
        );
    };
    ok($@, q{error has returned.});

    # stretch_count is not SCALAR and int
    eval {
        $pwhash = crypt(
            password        => q{password},
            hash            => Digest::SHA->new("sha256"),
            salt            => q{salt},
            stretch_count   => q{count},
        );
    };
    ok($@, q{error has returned.});

    eval {
        $pwhash = crypt(
            password        => q{password},
            hash            => Digest::SHA->new("sha256"),
            salt            => q{salt},
            stretch_count   => qw{1000 5000},
        );
    };
    ok($@, q{error has returned.});

    eval {
        $pwhash = crypt(
            password        => q{password},
            hash            => Digest::SHA->new("sha256"),
            salt            => q{salt},
            stretch_count   => 0,
        );
    };
    ok($@, q{error has returned.});
};

TEST_CRYPT_FORMAT: {

    # format is hex
    my $pwhash = crypt(
        password        => q{password},
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5000,
        format          => q{hex},
    );
    ok($pwhash, q{password hash is returned});
    is($pwhash, q{e21befcea662a3e97dbc689f43bc45dbe14a8b259171be25577392a3d3ec7d4c});

    # base64
    $pwhash = crypt(
        password        => q{password},
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5000,
        format          => q{base64},
    );
    ok($pwhash, q{password hash is returned});
    is($pwhash, q{4hvvzqZio+l9vGifQ7xF2+FKiyWRcb4lV3OSo9PsfUw=});

};

TEST_CRYPT_SHAx: {

    my $pwhash = crypt(
        password        => q{password},
        hash            => Digest::SHA3->new("sha3_256"),
        salt            => q{salt},
        stretch_count   => 5000,
        format          => q{base64},
    );
    ok($pwhash, q{password hash is returned});
    is($pwhash, q{j8UDYCAmRhgDlGY6Ed0c4n4TyuYR/2kE/XzCiSSRPys=});

};

done_testing;
