use Test::More tests => 16;
use strict;
use warnings;
use Crypt::Keyczar::Crypter;
use Crypt::Keyczar::Encrypter;
use Crypt::Keyczar::Signer;
use Crypt::Keyczar::Verifier;
use Crypt::Keyczar::Util;
use FindBin;


sub JAVA_OPT          { "-classpath $FindBin::Bin/compat-java/gson.jar:$FindBin::Bin/compat-java/log4j.jar:$FindBin::Bin/compat-java/keyczar.jar:$FindBin::Bin/compat-java" }
sub PATH_JAVA_ENCRYPT_CLASS { "$FindBin::Bin/compat-java/TestEncrypt.class" }


my $KEYSET = "$FindBin::Bin/data/compat-java-sign";
my $signer = Crypt::Keyczar::Signer->new($KEYSET);
ok($signer);
my $sign = $signer->sign("This is some test data");
ok(Crypt::Keyczar::Util::encode($sign) eq 'AGLONb623KRxtE7FZoVS0iIph0fhD5T-Cw');

my $verifier = Crypt::Keyczar::Verifier->new($KEYSET);
ok($verifier->verify("This is some test data", $sign));
ok(!$verifier->verify("Wrong string", $sign));

SKIP: {
    skip "TestEncrypt.class not found", 12 if !have_java_encrypt();

    test_java_encrypt_to_perl_decrypt();
    test_perl_encrypt_to_java_decrypt();
    test_java_sign_to_perl_verify();
    test_perl_sign_to_java_verify();
}


sub test_java_encrypt_to_perl_decrypt {
    my $ct;
    my $key;

    $key = "$FindBin::Bin/compat-java/crypt-aes";
    $ct = encrypt_java($key, 'Hello World!');
    is(decrypt_perl($key, $ct), 'Hello World!', 'AES encrypt Java, decrypt Perl');

    $key = "$FindBin::Bin/compat-java/crypt-rsa-pub";
    $ct = encrypt_java($key, 'Hello World!');
    $key = "$FindBin::Bin/compat-java/crypt-rsa";
    is(decrypt_perl($key, $ct), 'Hello World!', 'RSA (pub/priv) encrypt Java, decrypt Perl');
}

sub test_perl_encrypt_to_java_decrypt {
    my $ct;
    my $key;

    $key = "$FindBin::Bin/compat-java/crypt-aes";
    $ct = encrypt_perl($key, 'Hello World!');
    is(decrypt_java($key, $ct), 'Hello World!', 'AES encrypt Perl, decrypt Java');

    $key = "$FindBin::Bin/compat-java/crypt-rsa-pub";
    $ct = encrypt_perl($key, 'Hello World!');
    $key = "$FindBin::Bin/compat-java/crypt-rsa";
    is(decrypt_java($key, $ct), 'Hello World!', 'RSA (pub/priv) encrypt Perl, decrypt Java');
}


sub test_java_sign_to_perl_verify {
    my $mac;
    my $key;

    $key = "$FindBin::Bin/compat-java/sign-hmac";
    $mac = sign_java($key, 'Hello World!');
    ok(verify_perl($key, 'Hello World!', $mac), 'HMAC sign Java, verify Perl');

    $key = "$FindBin::Bin/compat-java/sign-dsa";
    $mac = sign_java($key, 'Hello World!');
    $key = "$FindBin::Bin/compat-java/sign-dsa-pub";
    ok(verify_perl($key, 'Hello World!', $mac), 'DSA sign Java, verify Perl');

    $key = "$FindBin::Bin/compat-java/sign-rsa";
    $mac = sign_java($key, 'Hello World!');
    $key = "$FindBin::Bin/compat-java/sign-rsa-pub";
    ok(verify_perl($key, 'Hello World!', $mac), 'RSA sign private Java, verify public Perl');

    $key = "$FindBin::Bin/compat-java/sign-rsa";
    $mac = sign_java($key, 'Hello World!');
    $key = "$FindBin::Bin/compat-java/sign-rsa";
    ok(verify_perl($key, 'Hello World!', $mac), 'RSA sign private Java, verify private Perl');
}


sub test_perl_sign_to_java_verify {
    my $mac;
    my $key;

    $key = "$FindBin::Bin/compat-java/sign-hmac";
    $mac = sign_perl($key, 'Hello World!');
    ok(verify_java($key, 'Hello World!', $mac), 'HMAC sign Perl, verify Java');

    $key = "$FindBin::Bin/compat-java/sign-dsa";
    $mac = sign_perl($key, 'Hello World!');
    $key = "$FindBin::Bin/compat-java/sign-dsa-pub";
    ok(verify_java($key, 'Hello World!', $mac), 'DSA sign Perl, verify Java');

    $key = "$FindBin::Bin/compat-java/sign-rsa";
    $mac = sign_perl($key, 'Hello World!');
    $key = "$FindBin::Bin/compat-java/sign-rsa-pub";
    ok(verify_java($key, 'Hello World!', $mac), 'RSA sign private Perl, verify public Java');

    $key = "$FindBin::Bin/compat-java/sign-rsa";
    $mac = sign_perl($key, 'Hello World!');
    $key = "$FindBin::Bin/compat-java/sign-rsa";
    ok(verify_java($key, 'Hello World!', $mac), 'RSA sign private Perl, verify private Java');
}



sub have_java_encrypt { return -e PATH_JAVA_ENCRYPT_CLASS }

sub run_java_test {
    my ($class, $key, $input, $args) = @_;

    my $run_java = sprintf q{%s %s %s %s '%s' %s},
        'java', JAVA_OPT, $class, $key, $input, $args ? "'$args'" : '';
    my $output = `$run_java 2> /dev/null`;
    chomp $output;
    return $output;
}


sub encrypt_java {
    my ($key, $msg) = @_;
    return run_java_test('TestEncrypt', $key, $msg);
}


sub decrypt_java {
    my ($key, $msg) = @_;
    return run_java_test('TestDecrypt', $key, $msg);
}


sub sign_java {
    my ($key, $msg) = @_;
    return run_java_test('TestSign', $key, $msg);
}


sub verify_java {
    my ($key, $msg, $mac) = @_;
    my $rc = run_java_test('TestVerify', $key, $msg, $mac);
    return $rc eq 'ok';
}


sub encrypt_perl {
    my ($key, $msg) = @_;
    my $c = Crypt::Keyczar::Encrypter->new($key);
    return Crypt::Keyczar::Util::encode($c->encrypt($msg));
}


sub decrypt_perl {
    my ($key, $msg) = @_;
    my $c = Crypt::Keyczar::Crypter->new($key);
    return $c->decrypt(Crypt::Keyczar::Util::decode($msg));
}


sub sign_perl {
    my ($key, $msg) = @_;
    my $s = Crypt::Keyczar::Signer->new($key);
    return Crypt::Keyczar::Util::encode($s->sign($msg));
}


sub verify_perl {
    my ($key, $msg, $mac) = @_;
    my $s = Crypt::Keyczar::Verifier->new($key);
    return $s->verify($msg, Crypt::Keyczar::Util::decode($mac));
}
