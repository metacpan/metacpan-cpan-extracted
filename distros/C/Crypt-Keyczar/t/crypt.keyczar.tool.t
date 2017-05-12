use Test::More tests => 218;
use strict;
use warnings;
use FindBin;
use File::Path;

use Crypt::Keyczar::FileWriter;
use Crypt::Keyczar::Util qw(decode_json encode_json);


sub BEGIN { use_ok('Crypt::Keyczar::Tool') }
sub END { rmtree(["$FindBin::Bin/data/tool"], 0, 0) }
rmtree(["$FindBin::Bin/data/tool"], 0, 0);

my $tool = Crypt::Keyczar::Tool->new(Crypt::Keyczar::FileWriter->new);


# create --purpose=sign
create_operation($tool, "$FindBin::Bin/data/tool/sign", 'sign', undef, {
    purpose => 'SIGN_AND_VERIFY', name => 'sign t', type => 'HMAC_SHA1'
});
addkey_operation($tool, "$FindBin::Bin/data/tool/sign", undef, {
    size => '256', 'exist' => [ qw(hmacKeyString) ]
});
promote_operation($tool, "$FindBin::Bin/data/tool/sign");
demote_operation($tool, "$FindBin::Bin/data/tool/sign");
revoke_operation($tool, "$FindBin::Bin/data/tool/sign");


# create --purpose=sign --asymmetric
create_operation($tool, "$FindBin::Bin/data/tool/sign-dsa", 'sign', 1, {
    purpose => 'SIGN_AND_VERIFY', name => 'sign DSA t', type => 'DSA_PRIV'
});
addkey_operation($tool, "$FindBin::Bin/data/tool/sign-dsa", undef, {
    size => '1024', 'exist' => [ qw(publicKey x) ]
});
promote_operation($tool, "$FindBin::Bin/data/tool/sign-dsa");
demote_operation($tool, "$FindBin::Bin/data/tool/sign-dsa");
revoke_operation($tool, "$FindBin::Bin/data/tool/sign-dsa");
pubkey_operation($tool, "$FindBin::Bin/data/tool/sign-dsa",
    { purpose => 'VERIFY', type => 'DSA_PUB' },
    [ qw(y p q g size) ], [ qw(publicKey x)]
);


# create --purpose=sign --asymmetric=rsa
create_operation($tool, "$FindBin::Bin/data/tool/sign-rsa", 'sign', 'rsa', {
    purpose => 'SIGN_AND_VERIFY', name => 'sign RSA t', type => 'RSA_PRIV'
});
addkey_operation($tool, "$FindBin::Bin/data/tool/sign-rsa", 2048, {
    size => '2048', 'exist' => [ qw(publicKey privateExponent primeP primeQ primeExponentP primeExponentQ crtCoefficient) ]
});
promote_operation($tool, "$FindBin::Bin/data/tool/sign-rsa");
demote_operation($tool, "$FindBin::Bin/data/tool/sign-rsa");
revoke_operation($tool, "$FindBin::Bin/data/tool/sign-rsa");
pubkey_operation($tool, "$FindBin::Bin/data/tool/sign-rsa",
    { purpose => 'VERIFY', type => 'RSA_PUB' },
    [ qw(modulus publicExponent size) ], [ qw(publicKey privateExponent primeP primeQ primeExponentP primeExponentQ crtCoefficient)]
);



# create --purpose=crypt
create_operation($tool, "$FindBin::Bin/data/tool/crypt", 'crypt', undef, {
    purpose => 'DECRYPT_AND_ENCRYPT', name => 'crypt AES t', type => 'AES'
});
addkey_operation($tool, "$FindBin::Bin/data/tool/crypt", undef, {
    size => '128', 'exist' => [ qw(aesKeyString hmacKey mode) ]
});
promote_operation($tool, "$FindBin::Bin/data/tool/crypt");
demote_operation($tool, "$FindBin::Bin/data/tool/crypt");
revoke_operation($tool, "$FindBin::Bin/data/tool/crypt");


# create --purpose=crypt --asymmetric
create_operation($tool, "$FindBin::Bin/data/tool/crypt-rsa", 'crypt', 1, {
    purpose => 'DECRYPT_AND_ENCRYPT', name => 'crypt RSA t', type => 'RSA_PRIV'
});
addkey_operation($tool, "$FindBin::Bin/data/tool/crypt-rsa", 4096, {
    size => '4096', 'exist' => [ qw(publicKey privateExponent primeP primeQ primeExponentP primeExponentQ crtCoefficient) ]
});
promote_operation($tool, "$FindBin::Bin/data/tool/crypt-rsa");
demote_operation($tool, "$FindBin::Bin/data/tool/crypt-rsa");
revoke_operation($tool, "$FindBin::Bin/data/tool/crypt-rsa");
pubkey_operation($tool, "$FindBin::Bin/data/tool/crypt-rsa",
    { purpose => 'ENCRYPT', type => 'RSA_PUB' },
    [ qw(modulus publicExponent size) ], [ qw(publicKey privateExponent primeP primeQ primeExponentP primeExponentQ crtCoefficient)]
);


# Test key lifetime
# https://rt.cpan.org/Public/Bug/Display.html?id=62032
test_key_lifetime($tool, "$FindBin::Bin/data/tool/lifecycle");


sub test_key_lifetime {
    my $tool = shift;
    my $path = shift;

    my $key_id1;
    my $key_id2;
    my $meta;
    my $v;
    $tool->create($path, 'sign', {});
    $key_id1 = $tool->addkey($path, 'PRIMARY', {});
    $key_id2 = $tool->addkey($path, 'ACTIVE', {});
    $meta = _load_json("$path/meta");
    $v = $meta->{versions};
    is($v->[0]->{status}, 'PRIMARY');
    is($v->[1]->{status}, 'ACTIVE');

    $tool->promote($path, $key_id2);
    $meta = _load_json("$path/meta");
    $v = $meta->{versions};
    is($v->[0]->{status}, 'ACTIVE');
    is($v->[1]->{status}, 'PRIMARY');

    $tool->demote($path, $key_id1);
    $meta = _load_json("$path/meta");
    $v = $meta->{versions};
    is($v->[0]->{status}, 'INACTIVE');
    is($v->[1]->{status}, 'PRIMARY');

    $tool->promote($path, $key_id1);
    $meta = _load_json("$path/meta");
    $v = $meta->{versions};
    is($v->[0]->{status}, 'ACTIVE');
    is($v->[1]->{status}, 'PRIMARY');

    $tool->promote($path, $key_id1);
    $meta = _load_json("$path/meta");
    $v = $meta->{versions};
    is($v->[0]->{status}, 'PRIMARY');
    is($v->[1]->{status}, 'ACTIVE');

    $tool->demote($path, $key_id2);
    $meta = _load_json("$path/meta");
    $v = $meta->{versions};
    is($v->[0]->{status}, 'PRIMARY');
    is($v->[1]->{status}, 'INACTIVE');

    $tool->revoke($path, $key_id2);
    $meta = _load_json("$path/meta");
    $v = $meta->{versions};
    is($v->[0]->{status}, 'PRIMARY');
    is($v->[1], undef);
}


sub create_operation {
    my $tool = shift;
    my $path = shift;
    my $purpose = shift;
    my $asymmetric = shift;
    my $opt = shift;

    $tool->create($path, $purpose, { asymmetric => $asymmetric, name => $opt->{name}});
    my $json = _load_json("$path/meta"); 
    ok($json, "create --purpose=$purpose". ($asymmetric ? " --asymmetric=$asymmetric" : ""));
    for my $key (sort keys %$opt) {
        ok($json->{$key} eq $opt->{$key}, qq|{"$key": "$opt->{$key}"}|);
    }
}



sub addkey_operation {
    my $tool = shift;
    my $path = shift;
    my $size = shift;
    my $opt = shift;

    my $num = $tool->addkey($path, 'PRIMARY', { size => $size });
    ok($num == 1, "addKey version 1");
    my $json = _load_json("$path/meta"); 
    ok(scalar @{$json->{versions}} == 1);

    $json = _load_json("$path/$num");
    is($json->{size}, $opt->{size});
    for my $key (@{$opt->{exist}}) {
        ok(defined $json->{$key}, qq{{"$key": ...}});
    }

    $num = $tool->addkey($path, 'ACTIVE', { size => $size });
    ok($num == 2, "addKey version 2(ret=$num)");
    $json = _load_json("$path/meta"); 
    ok(scalar @{$json->{versions}} == 2);
    $json = _load_json("$path/$num");
    ok($json->{size} eq $opt->{size}, qq|{ "size": "xxx" }|);
    for my $key (@{$opt->{exist}}) {
        ok(defined $json->{$key}, qq{{"$key": ...}});
    }
}


sub promote_operation {
    my $tool = shift;
    my $path = shift;

    my $num = $tool->addkey($path, 'ACTIVE', {});
    ok(_get_primary_number($path) == 1);
    $tool->promote($path, $num);
    ok(_get_primary_number($path) == 3, 'promote --version=3');

    $tool->promote($path, 2);
    ok(_get_primary_number($path) == 2, 'promote --version=2');
}


sub demote_operation {
    my $tool = shift;
    my $path = shift;

    $tool->demote($path, 1);
    ok(_get_version_status($path, 1) eq 'INACTIVE', 'demote --version=1');
    eval { $tool->demote($path, 1) };
    ok($@, 're-demote --version=1');

    $tool->demote($path, 2);
    ok(_get_version_status($path, 2) eq 'ACTIVE', 'demote --version=2');
    ok(!defined _get_primary_number($path), 'no PRIMARY');
}


sub revoke_operation {
    my $tool = shift;
    my $path = shift;

    ok(-e "$path/1");
    $tool->revoke($path, 1);
    ok(!_get_version_status($path, 1), 'revoke --version=1');
    ok(!-e "$path/1", 'removed 1');
    eval { $tool->revoke($path, 2) }; # revoke Active key
    ok($@, 'revoke --version=2(ACTIVE)');
    ok(_get_version_status($path, 2) eq 'ACTIVE');
    ok(-e "$path/2", 'exists 2');
}



sub pubkey_operation {
    my $tool = shift;
    my $path = shift;
    my $opt = shift;
    my $exists = shift;
    my $unexists = shift;

    $tool->pubkey($path, $path."-pub");
    ok(-e $path. "-pub/meta");
    my $json = _load_json($path. "-pub/meta"); 
    ok($json);
    ok(scalar @{$json->{versions}} == 3);
    ok(!$json->{encrypted});
    for my $key (sort keys %$opt) {
        ok($json->{$key} eq $opt->{$key}, qq|{ "$key": "$opt->{$key}"}|);
    }

    ok(-e $path. "-pub/2");
    $json = _load_json($path. "-pub/2");
    for my $key (@$exists) {
        ok(defined $json->{$key}, qq|{ "$key": ... }|);
    }
    for my $key (@$unexists) {
        ok(!exists $json->{$key}, qq|{ "$key": false }|);
    }
}


sub _get_primary_number {
    my $path = shift;
    my $json = _load_json("$path/meta");
    my $primary;
    for my $v (@{$json->{versions}}) {
        next if !$v;
        $primary = $v->{versionNumber} if $v->{status} eq 'PRIMARY';
    }
    return $primary; 
}


sub _get_version_status {
    my $path = shift;
    my $version = shift;

    my $json = _load_json("$path/meta");
    for my $v (@{$json->{versions}}) {
        next if !$v;
        return $v->{status} if $v->{versionNumber} == $version;
    }
    return undef;
}


sub _load_json {
    my $path = shift;
    my $json;
    return undef if !-r $path;
    open my $fh, '<', $path;
    {
        local $/ = undef;
        $json = decode_json(<$fh>);
    }
    close $fh;
    return $json;
} 
