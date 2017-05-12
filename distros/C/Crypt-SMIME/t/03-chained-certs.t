# -*- perl -*-
use strict;
use warnings;
use ExtUtils::PkgConfig ();
use File::Spec;
use File::Temp qw(tempfile);
use Test::More;
use Test::Exception;
use Config;

# Create the following certificate tree:
#
# + The root CA (self-signed)
# |
# `-+ An intermediate CA #1
#   |
#   `-+ An intermediate CA #2
#     |
#     `-- An user
#
# Then do the following:
#
#  1. Make a mail signed by an user private key and let it contain
#     certificates of two intermediate CAs.
#
#  2. Verify the mail with only the root CA certificate and its
#     key. Can we prove the mail is actually trustable?

my (%key, %csr, %crt);
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

    my $DEVNULL = File::Spec->devnull();

    # Create the root CA.
    do {
        my ($conf_fh, $conf_file) = tempfile(UNLINK => 1);
        print {$conf_fh} << 'EOF';
[ req ]
distinguished_name     = req_distinguished_name
attributes             = req_attributes
req_extensions         = v3_ca
prompt                 = no
[ req_distinguished_name ]
C                      = JP
ST                     = Some-State
L                      = Some-Locality
O                      = Crypt::SMIME
OU                     = The Root CA
CN                     = ROOT
[ req_attributes ]
[ v3_ca ]
basicConstraints       = CA:true
EOF
        close $conf_fh;

        (undef, $key{root}) = tempfile(UNLINK => 1);
        (undef, $csr{root}) = tempfile(UNLINK => 1);
        (undef, $crt{root}) = tempfile(UNLINK => 1);
        system(qq{$OPENSSL genrsa -out $key{root} >$DEVNULL 2>&1}) and die $!;
        system(qq{$OPENSSL req -new -key $key{root} -out $csr{root} -config $conf_file >$DEVNULL 2>&1}) and die $!;
        system(qq{$OPENSSL x509 -in $csr{root} -out $crt{root} -req -signkey $key{root} -set_serial 1 -extfile $conf_file -extensions v3_ca >$DEVNULL 2>&1}) and die;
    };

    # Create an intermediate CA #1.
    do {
        my ($conf_fh, $conf_file) = tempfile(UNLINK => 1);
        print {$conf_fh} << 'EOF';
[ req ]
distinguished_name     = req_distinguished_name
attributes             = req_attributes
req_extensions         = v3_ca
prompt                 = no
[ req_distinguished_name ]
C                      = JP
ST                     = Some-State
L                      = Some-Locality
O                      = Crypt::SMIME
OU                     = An intermediate CA No.1
CN                     = INTERMED-1
[ req_attributes ]
[ v3_ca ]
basicConstraints       = CA:true
EOF
        close $conf_fh;

        (undef, $key{intermed_1}) = tempfile(UNLINK => 1);
        (undef, $csr{intermed_1}) = tempfile(UNLINK => 1);
        (undef, $crt{intermed_1}) = tempfile(UNLINK => 1);
        system(qq{$OPENSSL genrsa -out $key{intermed_1} >$DEVNULL 2>&1}) and die $!;
        system(qq{$OPENSSL req -new -key $key{intermed_1} -out $csr{intermed_1} -config $conf_file >$DEVNULL 2>&1}) and die $!;
        system(qq{$OPENSSL x509 -in $csr{intermed_1} -out $crt{intermed_1} -req -CA $crt{root} -CAkey $key{root} -set_serial 1 -extfile $conf_file -extensions v3_ca >$DEVNULL 2>&1}) and die;
    };

    # Create an intermediate CA #2.
    do {
        my ($conf_fh, $conf_file) = tempfile(UNLINK => 1);
        print {$conf_fh} << 'EOF';
[ req ]
distinguished_name     = req_distinguished_name
attributes             = req_attributes
req_extensions         = v3_ca
prompt                 = no
[ req_distinguished_name ]
C                      = JP
ST                     = Some-State
L                      = Some-Locality
O                      = Crypt::SMIME
OU                     = An intermediate CA No.2
CN                     = INTERMED-2
[ req_attributes ]
[ v3_ca ]
basicConstraints       = CA:true
EOF
        close $conf_fh;

        (undef, $key{intermed_2}) = tempfile(UNLINK => 1);
        (undef, $csr{intermed_2}) = tempfile(UNLINK => 1);
        (undef, $crt{intermed_2}) = tempfile(UNLINK => 1);
        system(qq{$OPENSSL genrsa -out $key{intermed_2} >$DEVNULL 2>&1}) and die $!;
        system(qq{$OPENSSL req -new -key $key{intermed_2} -out $csr{intermed_2} -config $conf_file >$DEVNULL 2>&1}) and die $!;
        system(qq{$OPENSSL x509 -in $csr{intermed_2} -out $crt{intermed_2} -req -CA $crt{intermed_1} -CAkey $key{intermed_1} -set_serial 1 -extfile $conf_file -extensions v3_ca >$DEVNULL 2>&1}) and die;
    };

    # Create an user.
    do {
        my ($conf_fh, $conf_file) = tempfile(UNLINK => 1);
        print {$conf_fh} << 'EOF';
[ req ]
distinguished_name     = req_distinguished_name
attributes             = req_attributes
prompt                 = no
[ req_distinguished_name ]
C                      = JP
ST                     = Some-State
L                      = Some-Locality
O                      = Crypt::SMIME
OU                     = An user
CN                     = USER
[ req_attributes ]
EOF
        close $conf_fh;

        (undef, $key{user}) = tempfile(UNLINK => 1);
        (undef, $csr{user}) = tempfile(UNLINK => 1);
        (undef, $crt{user}) = tempfile(UNLINK => 1);
        system(qq{$OPENSSL genrsa -out $key{user} >$DEVNULL 2>&1}) and die $!;
        system(qq{$OPENSSL req -new -key $key{user} -out $csr{user} -config $conf_file >$DEVNULL 2>&1}) and die $!;
        system(qq{$OPENSSL x509 -in $csr{user} -out $crt{user} -req -CA $crt{intermed_2} -CAkey $key{intermed_2} -set_serial 1 >$DEVNULL 2>&1}) and die;
    };
};

sub key {
    my $who = shift;

    local $/;
    open my $fh, '<', $key{$who} or die $!;
    return scalar <$fh>;
};

sub crt {
    my $who = shift;

    local $/;
    open my $fh, '<', $crt{$who} or die $!;
    return scalar <$fh>;
}

my $plain = q{From: alice@example.org
To: bob@example.org
Subject: Crypt::SMIME test

This is a test mail. Please ignore...
};
$plain =~ s/\r?\n|\r/\r\n/g;
my $verified = q{Subject: Crypt::SMIME test

This is a test mail. Please ignore...
};
$verified =~ s/\r?\n|\r/\r\n/g;

# -----------------------------------------------------------------------------
plan tests => 8;
use_ok('Crypt::SMIME');

my $signed = do {
    my $SMIME;
    lives_ok { $SMIME = Crypt::SMIME->new } 'new';
    lives_ok { $SMIME->setPrivateKey(key('user'), crt('user')) } 'setPrivateKey(USER)';
    lives_ok { $SMIME->setPublicKey(crt('intermed_1')."\n".crt('intermed_2')) } 'setPublicKey(INTERMED-1 & INTERMED-2)';
    my $tmp;
    lives_ok { $tmp = $SMIME->sign($plain) } 'sign($plain)';
    $tmp;
};

do {
    my $SMIME = Crypt::SMIME->new;
    lives_ok { $SMIME->setPublicKey(crt('root')) } 'setPublicKey(ROOT)';
    my $checked;
    lives_ok { $checked = $SMIME->check($signed) } 'check';
    is($checked, $verified, '$verified eq check(sign($plain))');
};
