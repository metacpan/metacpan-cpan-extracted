# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#use Test;

use strict;
use Test::More;
use Try::Tiny;
use Env::Path;

use constant USERID    => "GnuPG Test";
use constant PASSWD    => "test";
use constant UNTRUSTED => "Francis";

use AnyEvent::GnuPG;

BEGIN {
    $| = 1;
}

my @tests = (
    qw(
      version
      gen_key_test
      import_test
      import2_test
      import3_test
      export_test
      export2_test
      export_secret_test
      encrypt_test
      pipe_encrypt_test
      pipe_decrypt_test
      encrypt_sign_test
      encrypt_sym_test
      encrypt_notrust_test
      decrypt_test
      decrypt_sign_test
      decrypt_sym_test
      sign_test
      detachsign_test
      clearsign_test
      verify_sign_test
      verify_detachsign_test
      verify_clearsign_test
      multiple_recipients
      )
);

if ( defined $ENV{TESTS} ) {
    @tests = split /\s+/, $ENV{TESTS};
}

unless ( Env::Path->PATH->Whence('gpg') ) {
    plan skip_all => 'gpg needed for this module';
}
else {
    plan tests => scalar @tests;
}

my $gpg = AnyEvent::GnuPG->new( homedir => "test" );

for (@tests) {
    subtest $_ => sub {
        try {
            no strict 'refs';    ## no critic
            &$_();
            pass;
        }
        catch {
            fail;
            diag $_;
        }
      }

}

sub version {
    my @version = $gpg->version;
    ok @version;
    is shift(@version) => 1,
      'gpg v1 ok'
      or BAIL_OUT "this module works only with gpg v1";
}

sub multiple_recipients {
    die unless -s "test/file.txt";
    $gpg->encrypt(
        recipient => [ USERID, UNTRUSTED ],
        output    => "test/file.txt.gpg",
        armor     => 1,
        plaintext => "test/file.txt",
    );
    ok -s "test/file.txt.gpg";
}

sub gen_key_test {
    if ( $ENV{AUTOMATED_TESTING} ) {
        return;
    }
    diag "Generating a key - can take some time";
    $gpg->gen_key(
        passphrase => PASSWD,
        name       => USERID,
        progress   => sub {
            local $, = ', ';
            diag "progress @_" if $ENV{AUTOMATED_TESTING};
        }
    );
}

sub import_test {
    $gpg->import_keys( keys => "test/key1.pub" );
}

sub import2_test {
    $gpg->import_keys( keys => "test/key1.pub" );
}

sub import3_test {
    $gpg->import_keys( keys => [qw( test/key1.pub test/key2.pub )] );
}

sub export_test {
    $gpg->export_keys(
        keys   => USERID,
        armor  => 1,
        output => "test/key.pub",
    );
    ok -s "test/key.pub";
}

sub export2_test {
    $gpg->export_keys(
        armor  => 1,
        output => "test/keyring.pub",
    );
    ok -s "test/keyring.pub";
}

sub export_secret_test {
    $gpg->export_keys(
        secret => 1,
        armor  => 1,
        output => "test/key.sec",
    );
    ok -s "test/key.sec";
}

sub encrypt_test {
    die unless -s "test/file.txt";
    $gpg->encrypt(
        recipient => USERID,
        output    => "test/file.txt.gpg",
        armor     => 1,
        plaintext => "test/file.txt",
    );
    ok -s "test/file.txt.gpg";
}

sub pipe_encrypt_test {
    die unless -s "test/file.txt";
    open CAT, "| cat > test/pipe-file.txt.gpg" or die "can't fork: $!\n";
    $gpg->encrypt(
        recipient => USERID,
        output    => \*CAT,
        armor     => 1,
        plaintext => "test/file.txt",
    );
    close CAT;
    ok -s "test/pipe-file.txt.gpg";
}

sub encrypt_sign_test {
    die unless -s "test/file.txt";
    $gpg->encrypt(
        recipient  => USERID,
        output     => "test/file.txt.sgpg",
        armor      => 1,
        sign       => 1,
        plaintext  => "test/file.txt",
        passphrase => PASSWD,
    );
    ok -s "test/file.txt.sgpg";
}

sub encrypt_sym_test {
    die unless -s "test/file.txt";
    $gpg->encrypt(
        output     => "test/file.txt.cipher",
        armor      => 1,
        plaintext  => "test/file.txt",
        symmetric  => 1,
        passphrase => PASSWD,
    );
    ok -s "test/file.txt.cipher";
}

sub encrypt_notrust_test {
    die unless -s "test/file.txt";
    $gpg->encrypt(
        recipient  => UNTRUSTED,
        output     => "test/file.txt.dist.gpg",
        armor      => 1,
        sign       => 1,
        plaintext  => "test/file.txt",
        passphrase => PASSWD,
    );
    ok -s "test/file.txt.dist.gpg";
}

sub sign_test {
    die unless -s "test/file.txt";
    $gpg->sign(
        recipient  => USERID,
        output     => "test/file.txt.sig",
        armor      => 1,
        plaintext  => "test/file.txt",
        passphrase => PASSWD,
    );
    ok -s "test/file.txt.sig";
}

sub detachsign_test {
    die unless -s "test/file.txt";
    $gpg->sign(
        recipient     => USERID,
        output        => "test/file.txt.asc",
        "detach-sign" => 1,
        armor         => 1,
        plaintext     => "test/file.txt",
        passphrase    => PASSWD,
    );
    ok -s "test/file.txt.asc";
}

sub clearsign_test {
    die unless -s "test/file.txt";
    $gpg->clearsign(
        output     => "test/file.txt.clear",
        armor      => 1,
        plaintext  => "test/file.txt",
        passphrase => PASSWD,
    );
    ok -s "test/file.txt.clear";
}

sub decrypt_test {
    die unless -s "test/file.txt.gpg";
    $gpg->decrypt(
        output     => "test/file.txt.plain",
        ciphertext => "test/file.txt.gpg",
        passphrase => PASSWD,
    );
    ok -s "test/file.txt.plain";
}

sub pipe_decrypt_test {
    die unless -s "test/file.txt.gpg";
    open CAT, "cat test/file.txt.gpg|" or die "can't fork: $!\n";
    $gpg->decrypt(
        output     => "test/file.txt.plain",
        ciphertext => \*CAT,
        passphrase => PASSWD,
    );
    close CAT;
    ok -s "test/file.txt.plain";
}

sub decrypt_sign_test {
    die unless -s "test/file.txt.sgpg";
    $gpg->decrypt(
        output     => "test/file.txt.plain2",
        ciphertext => "test/file.txt.sgpg",
        passphrase => PASSWD,
    );
    ok -s "test/file.txt.plain2";
}

sub decrypt_sym_test {
    die unless -s "test/file.txt.cipher";
    $gpg->decrypt(
        output     => "test/file.txt.plain3",
        ciphertext => "test/file.txt.cipher",
        symmetric  => 1,
        passphrase => PASSWD,
    );
    ok -s "test/file.txt.plain3";
}

sub verify_sign_test {
    die unless -s "test/file.txt.sig";
    $gpg->verify( signature => "test/file.txt.sig" );
}

sub verify_detachsign_test {
    die unless -s "test/file.txt.asc";
    die unless -s "test/file.txt";
    $gpg->verify(
        signature => "test/file.txt.asc",
        file      => "test/file.txt",
    );
}

sub verify_clearsign_test {
    die unless -s "test/file.txt.clear";
    $gpg->verify( signature => "test/file.txt.clear" );
}

sub encrypt_from_fh_test {
    die unless -s "test/file.txt";
    open( FH, "test/file.txt" ) or die "error opening file: $!\n";
    $gpg->encrypt(
        recipient => UNTRUSTED,
        output    => "test/file-fh.txt.gpg",
        armor     => 1,
        plaintext => \*FH,
    );
    close FH;
    ok -s "test/file-fh.txt.gpg";
}

sub encrypt_to_fh_test {
    die unless -s "test/file.txt";
    open( FH, ">test/file-fho.txt.gpg" ) or die "error opening file: $!\n";
    $gpg->encrypt(
        recipient => UNTRUSTED,
        output    => \*FH,
        armor     => 1,
        plaintext => "test/file.txt",
    );
    close FH;
    ok -s "test/file-fho.txt.gpg";
}
