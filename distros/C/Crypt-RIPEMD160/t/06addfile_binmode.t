#!perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile);

use Crypt::RIPEMD160;
use Crypt::RIPEMD160::MAC;

# Verify that addfile() reads in binary mode.
# Without binmode, platforms with CRLF line endings (Windows) would
# translate \r\n to \n during read(), producing platform-dependent hashes.

# Write a file containing an explicit \r\n sequence in binary mode,
# then verify that addfile() produces the same hash as add() with
# the identical byte string.

my $data_with_crlf = "line1\r\nline2\r\n";

# Write the test file in binary mode so the \r bytes survive on disk
my ($fh, $filename) = tempfile(UNLINK => 1);
binmode($fh);
print $fh $data_with_crlf;
close $fh;

subtest 'RIPEMD160 addfile reads in binary mode' => sub {
    # Reference: hash the byte string directly via add()
    my $ctx_ref = Crypt::RIPEMD160->new;
    $ctx_ref->add($data_with_crlf);
    my $hex_ref = unpack("H*", $ctx_ref->digest);

    # Test: hash the same bytes via addfile()
    open my $rfh, '<', $filename or die "Cannot open $filename: $!";
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->addfile($rfh);
    my $hex = unpack("H*", $ctx->digest);
    close $rfh;

    is($hex, $hex_ref,
       'addfile produces same hash as add() for CRLF data');

    # Verify the \r bytes were actually hashed (not stripped)
    # by comparing against the hash of the LF-only version
    my $data_lf_only = "line1\nline2\n";
    my $ctx_lf = Crypt::RIPEMD160->new;
    $ctx_lf->add($data_lf_only);
    my $hex_lf = unpack("H*", $ctx_lf->digest);

    isnt($hex, $hex_lf,
         'CRLF hash differs from LF-only hash (binmode preserves \\r)');
};

subtest 'MAC addfile reads in binary mode' => sub {
    my $key = "test-key";

    # Reference: MAC the byte string directly
    my $mac_ref = Crypt::RIPEMD160::MAC->new($key);
    $mac_ref->add($data_with_crlf);
    my $hex_ref = $mac_ref->hexmac;

    # Test: MAC the same bytes via addfile()
    open my $rfh, '<', $filename or die "Cannot open $filename: $!";
    my $mac = Crypt::RIPEMD160::MAC->new($key);
    $mac->addfile($rfh);
    my $hex = $mac->hexmac;
    close $rfh;

    is($hex, $hex_ref,
       'MAC addfile produces same result as add() for CRLF data');
};

subtest 'addfile strips encoding layers' => sub {
    # Open with a text layer, verify addfile still reads raw bytes
    my ($tfh, $tfile) = tempfile(UNLINK => 1);
    binmode($tfh);
    print $tfh "hello\r\nworld\r\n";
    close $tfh;

    # Reference hash from raw bytes
    my $ctx_ref = Crypt::RIPEMD160->new;
    $ctx_ref->add("hello\r\nworld\r\n");
    my $hex_ref = unpack("H*", $ctx_ref->digest);

    # Open with :crlf layer (simulates default Windows text mode)
    open my $rfh, '<:crlf', $tfile or die "Cannot open $tfile: $!";
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->addfile($rfh);
    my $hex = unpack("H*", $ctx->digest);
    close $rfh;

    is($hex, $hex_ref,
       'addfile overrides :crlf layer via binmode');
};

done_testing;
