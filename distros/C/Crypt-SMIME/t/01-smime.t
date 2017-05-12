# -*- perl -*-
use strict;
use warnings;
use ExtUtils::PkgConfig ();
use File::Spec;
use File::Temp qw(tempfile);
use Test::More;
use Test::Exception;
use Config;

my (%key, %csr, %crt, %p12);
do {
    my $OPENSSL = do {
        if (defined(my $prefix = ExtUtils::PkgConfig->variable('openssl', 'prefix'))) {
            my $OPENSSL = $prefix . '/bin/openssl' . $Config{exe_ext};
            if (-x $OPENSSL) {
                diag "Using `$OPENSSL' to generate a keypair";
                $OPENSSL;
            }
            else {
                plan skip_all => q{Executable `openssl' was not found};
            }
        }
        else {
            plan skip_all => q{No package `openssl' found};
        }
    };

    my ($conf_fh, $conf_file) = tempfile(UNLINK => 1);
    print {$conf_fh} <<'EOF';
[ req ]
distinguished_name     = req_distinguished_name
attributes             = req_attributes
prompt                 = no
[ req_distinguished_name ]
C                      = AU
ST                     = Some-State
L                      = Test Locality
O                      = Organization Name
OU                     = Organizational Unit Name
CN                     = Common Name
emailAddress           = test@email.address
[ req_attributes ]
EOF
    close $conf_fh;

    my $DEVNULL = File::Spec->devnull();
    foreach my $i (1 .. 2) {
        (undef, $key{$i}) = tempfile(UNLINK => 1);
        (undef, $csr{$i}) = tempfile(UNLINK => 1);
        (undef, $crt{$i}) = tempfile(UNLINK => 1);
        (undef, $p12{$i}) = tempfile(UNLINK => 1);

        system(qq{$OPENSSL genrsa -out $key{$i} >$DEVNULL 2>&1}) and die $!;
        system(qq{$OPENSSL req -new -key $key{$i} -out $csr{$i} -config $conf_file >$DEVNULL 2>&1}) and die $!;
        system(qq{$OPENSSL x509 -in $csr{$i} -out $crt{$i} -req -signkey $key{$i} -set_serial $i >$DEVNULL 2>&1}) and die $!;
        system(qq{$OPENSSL pkcs12 -export -out $p12{$i} -inkey $key{$i} -in $crt{$i} -passout pass:Secret123 >$DEVNULL 2>&1}) and die $!;
    }
};

sub key {
    my $i = shift;

    local $/;
    open my $fh, '<', $key{$i} or die $!;
    return scalar <$fh>;
}

sub crt {
    my $i = shift;

    local $/;
    open my $fh, '<', $crt{$i} or die $!;
    return scalar <$fh>;
}

sub p12 {
    my $i = shift;

    local $/;
    open my $fh, '<', $p12{$i} or die $!;
    binmode $fh;
    return scalar <$fh>;
}

my $plain = q{From: alice@example.org
To: bob@example.org
Subject: Crypt::SMIME test
Content-Type: text/plain

This is a test mail. Please ignore...
};
$plain =~ s/\r?\n|\r/\r\n/g;
my $verify = q{Subject: Crypt::SMIME test
Content-Type: text/plain

This is a test mail. Please ignore...
};
$verify =~ s/\r?\n|\r/\r\n/g;

#-----------------------
plan tests => 25;
use_ok('Crypt::SMIME');

my $smime;
ok($smime = Crypt::SMIME->new, 'new');

ok($smime->setPrivateKey(key(1), crt(1)), 'setPrivateKey (without passphrase)');

dies_ok {$smime->sign} 'sign undef';
dies_ok {$smime->sign(\123)} 'sign ref';
dies_ok {$smime->signonly} 'signonly undef';
dies_ok {$smime->signonly(\123)} 'signonly ref';
dies_ok {$smime->encrypt} 'encrypt undef';
dies_ok {$smime->encrypt(\123)} 'encrypt ref';
dies_ok {$smime->isSigned} 'isSigned undef';
dies_ok {$smime->isSigned(\123)} 'isSigned ref';
dies_ok {$smime->isEncrypted} 'isEncrypted undef';
dies_ok {$smime->isEncrypted(\123)} 'isEncrypted ref';

my $signed;
ok($signed = $smime->sign($plain), 'sign');
ok($smime->isSigned($signed), 'signed');

ok($smime->setPublicKey(crt(1)), 'setPublicKey (one key)');

my $checked;
ok($checked = $smime->check($signed), 'check');
is($checked, $verify, '$verify eq check(sign($plain))');

ok($smime->setPublicKey([crt(1), crt(2)]), 'setPublicKey (two keys)');

my $encrypted;
ok($encrypted = $smime->encrypt($plain), 'encrypt');
ok($smime->isEncrypted($encrypted), 'isEncrypted');

my $decrypted;
ok($decrypted = $smime->decrypt($encrypted), 'decrypt (by sender\'s key)');
is($decrypted, $verify, '$plain eq decrypt(encrypt($plain))');

$smime->setPrivateKey(key(2), crt(2));
ok($decrypted = $smime->decrypt($encrypted), 'decrypt (by recipient\'s key)');

$smime->setPrivateKeyPkcs12(p12(2), 'Secret123');
ok($decrypted = $smime->decrypt($encrypted), 'decrypt (by recipient\'s PKCS12 key)');

1;
