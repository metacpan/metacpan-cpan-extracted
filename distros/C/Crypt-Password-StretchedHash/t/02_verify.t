use strict;
use warnings;

use Test::More;
use Crypt::Password::StretchedHash qw(
    verify
);
use Digest::SHA;
use MIME::Base64 qw(
    decode_base64
);

TEST_VERIFY_MONDATORY: {

    my $pwhash = q{4hvvzqZio+l9vGifQ7xF2+FKiyWRcb4lV3OSo9PsfUw=};
    $pwhash = decode_base64 $pwhash;
    my $result = Crypt::Password::StretchedHash::verify(
        password        => q{password},
        password_hash   => $pwhash,
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5000,
    );
    ok ( $result, q{only password hash} );

    $result = verify(
        password        => q{password},
        password_hash   => $pwhash,
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5000,
    );
    ok ( $result, q{only password hash} );

};

TEST_VEERIFY_FORMAT: {

    my $pwhash = q{4hvvzqZio+l9vGifQ7xF2+FKiyWRcb4lV3OSo9PsfUw=};
    my $result = verify(
        password        => q{password},
        password_hash   => $pwhash,
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5000,
        format          => q{base64},
    );
    ok ( $result, q{format is base64} );

    $pwhash = decode_base64 $pwhash;
    $pwhash = unpack("H*", $pwhash);
    $result = verify(
        password        => q{password},
        password_hash   => $pwhash,
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5000,
        format          => q{hex},
    );
    ok ( $result, q{format is hex} );

};

TEST_VERIFY_ERROR: {

    my $pwhash = q{4hvvzqZio+l9vGifQ7xF2+FKiyWRcb4lV3OSo9PsfUw=};
    $pwhash = decode_base64 $pwhash;
    my $result = verify(
        password        => q{password1},
        password_hash   => $pwhash,
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5000,
    );
    ok ( !$result, q{invalid password} );

    $result = verify(
        password        => q{password},
        password_hash   => $pwhash."a",
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5000,
    );
    ok ( !$result, q{invalid password hash} );

    $result = verify(
        password        => q{password},
        password_hash   => $pwhash,
        hash            => Digest::SHA->new("sha384"),
        salt            => q{salt},
        stretch_count   => 5000,
    );
    ok ( !$result, q{invalid hash function} );

    $result = verify(
        password        => q{password},
        password_hash   => $pwhash,
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt_invalid},
        stretch_count   => 5000,
    );
    ok ( !$result, q{invalid hash function} );

    $result = verify(
        password        => q{password},
        password_hash   => $pwhash,
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5001,
    );
    ok ( !$result, q{invalid stretching count} );

};

done_testing;
