#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Crypt::Age;
use Crypt::Age::Header;

# k49: the header parser used to read with a bare while (<$fh>), which assigns
# to the caller's global $_. Anyone decrypting inside a for (@list) loop got
# the loop variable -- and the array element it aliases -- replaced by a
# header line. Every public entry point that reaches the parser must leave $_
# exactly as the caller had it, on success and on failure.

my ($public, $secret) = Crypt::Age->generate_keypair;
my $plaintext  = "topic must survive\n";
my $ciphertext = Crypt::Age->encrypt(
    plaintext  => $plaintext,
    recipients => [$public],
);
# A header that gets past the version line and a stanza line, then fails: the
# error path must not leak a header line into $_ either.
my $broken = "age-encryption.org/v1\n-> X25519 abc\n" . ('A' x 64 . "\n") x 3;

my $dir = tempdir(CLEANUP => 1);
my $enc_file = File::Spec->catfile($dir, 'in.age');
{
    open my $fh, '>:raw', $enc_file or die "open $enc_file: $!";
    print {$fh} $ciphertext;
    close $fh or die "close $enc_file: $!";
}

my @entry_points = (
    [ 'Header->parse_from_fh' => sub {
        open my $fh, '<:raw', \$ciphertext or die $!;
        Crypt::Age::Header->parse_from_fh($fh);
    } ],
    [ 'Header->parse_from_fh (failing header)' => sub {
        open my $fh, '<:raw', \$broken or die $!;
        eval { Crypt::Age::Header->parse_from_fh($fh) };
        die "expected the stanza body to be refused, got: ".($@ || "success\n")
            unless $@ =~ m{Invalid age stanza #1 body};
    } ],
    [ 'Header->parse' => sub {
        my $offset = 0;
        Crypt::Age::Header->parse(\$ciphertext, \$offset);
    } ],
    [ 'Crypt::Age->decrypt' => sub {
        my $out = Crypt::Age->decrypt(
            ciphertext => $ciphertext,
            identities => [$secret],
        );
        die "wrong plaintext\n" unless $out eq $plaintext;
    } ],
    [ 'Crypt::Age->decrypt_file' => sub {
        my $out = File::Spec->catfile($dir, 'out.txt');
        Crypt::Age->decrypt_file(
            input      => $enc_file,
            output     => $out,
            identities => [$secret],
        );
    } ],
    [ 'Crypt::Age->decrypt_filehandle' => sub {
        open my $ifh, '<:raw', \$ciphertext or die $!;
        my $out = '';
        open my $ofh, '>:raw', \$out or die $!;
        Crypt::Age->decrypt_filehandle(
            input      => $ifh,
            output     => $ofh,
            identities => [$secret],
        );
        close $ofh;
        die "wrong plaintext\n" unless $out eq $plaintext;
    } ],
);

for my $ep (@entry_points) {
    my ($name, $call) = @$ep;

    # Plain global $_.
    {
        local $_ = 'caller topic';
        my $ok = eval { $call->(); 1 };
        ok($ok, "$name: call succeeded") or diag $@;
        is($_, 'caller topic', "$name: global \$_ unchanged");
    }

    # Inside for (@list): $_ aliases the element, so clobbering it would also
    # rewrite the caller's array.
    {
        my @list = ('first', 'second', 'third');
        my @seen;
        for (@list) {
            my $before = $_;
            eval { $call->(); 1 } or diag "$name: $@";
            push @seen, $_;
            is($_, $before, "$name: \$_ unchanged inside for (\@list) ($before)");
        }
        is_deeply(\@list, ['first', 'second', 'third'],
            "$name: array aliased by for is untouched");
        is_deeply(\@seen, ['first', 'second', 'third'],
            "$name: loop saw its own elements");
    }

    # Inside for over literals: $_ aliases a read-only value, so an assignment
    # to it would die with "Modification of a read-only value attempted".
    {
        for ('read-only') {
            my $ok = eval { $call->(); 1 };
            ok($ok, "$name: works with \$_ aliased to a read-only value")
                or diag $@;
            is($_, 'read-only', "$name: read-only \$_ unchanged");
        }
    }
}

done_testing;
