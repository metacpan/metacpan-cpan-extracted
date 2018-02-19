package App::GroupSecret::Crypt;
# ABSTRACT: Collection of crypto-related subroutines

use warnings;
use strict;

our $VERSION = '0.304'; # VERSION

use Exporter qw(import);
use File::Temp;
use IPC::Open2;
use IPC::Open3;
use Symbol qw(gensym);
use namespace::clean -except => [qw(import)];

our @EXPORT_OK = qw(
    generate_secure_random_bytes
    read_openssh_public_key
    read_openssh_key_fingerprint
    decrypt_rsa
    encrypt_rsa
    decrypt_aes_256_cbc
    encrypt_aes_256_cbc
);

our $OPENSSL    = 'openssl';
our $SSH_KEYGEN = 'ssh-keygen';

sub _croak { require Carp; Carp::croak(@_) }
sub _usage { _croak("Usage: @_\n") }


sub generate_secure_random_bytes {
    my $size = shift or _usage(q{generate_secure_random_bytes($num_bytes)});

    my @cmd = ($OPENSSL, 'rand', $size);

    my $out;
    my $pid = open2($out, undef, @cmd);

    waitpid($pid, 0);
    my $status = $?;

    my $exit_code = $status >> 8;
    _croak 'Failed to generate secure random bytes' if $exit_code != 0;

    return do { local $/; <$out> };
}


sub read_openssh_public_key {
    my $filepath = shift or _usage(q{read_openssh_public_key($filepath)});

    my @cmd = ($SSH_KEYGEN, qw{-e -m PKCS8 -f}, $filepath);

    my $out;
    my $pid = open2($out, undef, @cmd);

    waitpid($pid, 0);
    my $status = $?;

    my $exit_code = $status >> 8;
    _croak 'Failed to read OpenSSH public key' if $exit_code != 0;

    return do { local $/; <$out> };
}


sub read_openssh_key_fingerprint {
    my $filepath = shift or _usage(q{read_openssh_key_fingerprint($filepath)});

    # try with the -E flag first
    my @cmd = ($SSH_KEYGEN, qw{-l -E md5 -f}, $filepath);

    my $out;
    my $err = gensym;
    my $pid = open3(undef, $out, $err, @cmd);

    waitpid($pid, 0);
    my $status = $?;

    my $exit_code = $status >> 8;
    if ($exit_code != 0) {
        my $error_str = do { local $/; <$err> };
        _croak 'Failed to read SSH2 key fingerprint' if $error_str !~ /unknown option -- E/s;

        @cmd = ($SSH_KEYGEN, qw{-l -f}, $filepath);

        undef $out;
        $pid = open2($out, undef, @cmd);

        waitpid($pid, 0);
        $status = $?;

        $exit_code = $status >> 8;
        _croak 'Failed to read SSH2 key fingerprint' if $exit_code != 0;
    }

    my $line = do { local $/; <$out> };
    chomp $line;

    my ($bits, $fingerprint, $comment, $type) = $line =~ m!^(\d+) (?:MD5:)?([^ ]+) (.*) \(([^\)]+)\)$!;

    $fingerprint =~ s/://g;

    return {
        bits        => $bits,
        fingerprint => $fingerprint,
        comment     => $comment,
        type        => lc($type),
    };
}


sub decrypt_rsa {
    my $filepath = shift or _usage(q{decrypt_rsa($filepath, $keypath)});
    my $privkey  = shift or _usage(q{decrypt_rsa($filepath, $keypath)});
    my $outfile  = shift;

    my $temp;
    if (ref $filepath eq 'SCALAR') {
        $temp = File::Temp->new(UNLINK => 1);
        print $temp $$filepath;
        close $temp;
        $filepath = $temp->filename;
    }

    my @cmd = ($OPENSSL, qw{rsautl -decrypt -oaep -in}, $filepath, '-inkey', $privkey);
    push @cmd, ('-out', $outfile) if $outfile;

    my $out;
    my $pid = open2($out, undef, @cmd);

    waitpid($pid, 0);
    my $status = $?;

    my $exit_code = $status >> 8;
    _croak 'Failed to decrypt ciphertext' if $exit_code != 0;

    return do { local $/; <$out> };
}


sub encrypt_rsa {
    my $filepath = shift or _usage(q{encrypt_rsa($filepath, $keypath)});
    my $pubkey   = shift or _usage(q{encrypt_rsa($filepath, $keypath)});
    my $outfile  = shift;

    my $temp1;
    if (ref $filepath eq 'SCALAR') {
        $temp1 = File::Temp->new(UNLINK => 1);
        print $temp1 $$filepath;
        close $temp1;
        $filepath = $temp1->filename;
    }

    my $key = read_openssh_public_key($pubkey);

    my $temp2 = File::Temp->new(UNLINK => 1);
    print $temp2 $key;
    close $temp2;
    my $keypath = $temp2->filename;

    my @cmd = ($OPENSSL, qw{rsautl -encrypt -oaep -pubin -inkey}, $keypath, '-in', $filepath);
    push @cmd, ('-out', $outfile) if $outfile;

    my $out;
    my $pid = open2($out, undef, @cmd);

    waitpid($pid, 0);
    my $status = $?;

    my $exit_code = $status >> 8;
    _croak 'Failed to encrypt plaintext' if $exit_code != 0;

    return do { local $/; <$out> };
}


sub decrypt_aes_256_cbc {
    my $filepath = shift or _usage(q{decrypt_aes_256_cbc($ciphertext, $secret)});
    my $secret   = shift or _usage(q{decrypt_aes_256_cbc($ciphertext, $secret)});
    my $outfile  = shift;

    my $temp;
    if (ref $filepath eq 'SCALAR') {
        $temp = File::Temp->new(UNLINK => 1);
        print $temp $$filepath;
        close $temp;
        $filepath = $temp->filename;
    }

    my @cmd = ($OPENSSL, qw{aes-256-cbc -d -pass stdin -md sha256 -in}, $filepath);
    push @cmd, ('-out', $outfile) if $outfile;

    my ($in, $out);
    my $pid = open2($out, $in, @cmd);

    print $in $secret;
    close($in);

    waitpid($pid, 0);
    my $status = $?;

    my $exit_code = $status >> 8;
    _croak 'Failed to decrypt ciphertext' if $exit_code != 0;

    return do { local $/; <$out> };
}


sub encrypt_aes_256_cbc {
    my $filepath = shift or _usage(q{encrypt_aes_256_cbc($plaintext, $secret)});
    my $secret   = shift or _usage(q{encrypt_aes_256_cbc($plaintext, $secret)});
    my $outfile  = shift;

    my $temp;
    if (ref $filepath eq 'SCALAR') {
        $temp = File::Temp->new(UNLINK => 1);
        print $temp $$filepath;
        close $temp;
        $filepath = $temp->filename;
    }

    my @cmd = ($OPENSSL, qw{aes-256-cbc -pass stdin -md sha256 -in}, $filepath);
    push @cmd, ('-out', $outfile) if $outfile;

    my ($in, $out);
    my $pid = open2($out, $in, @cmd);

    print $in $secret;
    close($in);

    waitpid($pid, 0);
    my $status = $?;

    my $exit_code = $status >> 8;
    _croak 'Failed to encrypt plaintext' if $exit_code != 0;

    return do { local $/; <$out> };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GroupSecret::Crypt - Collection of crypto-related subroutines

=head1 VERSION

version 0.304

=head1 FUNCTIONS

=head2 generate_secure_random_bytes

    $bytes = generate_secure_random_bytes($num_bytes);

Get a certain number of secure random bytes.

=head2 read_openssh_public_key

    $pem_public_key = read_openssh_public_key($public_key_filepath);

Read a RFC4716 (SSH2) public key from a file, converting it to PKCS8 (PEM).

=head2 read_openssh_key_fingerprint

    $fingerprint = read_openssh_key_fingerprint($filepath);

Get the fingerprint of an OpenSSH private or public key.

=head2 decrypt_rsa

    $plaintext = decrypt_rsa($ciphertext_filepath, $private_key_filepath);
    $plaintext = decrypt_rsa(\$ciphertext, $private_key_filepath);
    decrypt_rsa($ciphertext_filepath, $private_key_filepath, $plaintext_filepath);
    decrypt_rsa(\$ciphertext, $private_key_filepath, $plaintext_filepath);

Do RSA decryption. Turn ciphertext into plaintext.

=head2 encrypt_rsa

    $ciphertext = decrypt_rsa($plaintext_filepath, $public_key_filepath);
    $ciphertext = decrypt_rsa(\$plaintext, $public_key_filepath);
    decrypt_rsa($plaintext_filepath, $public_key_filepath, $ciphertext_filepath);
    decrypt_rsa(\$plaintext, $public_key_filepath, $ciphertext_filepath);

Do RSA encryption. Turn plaintext into ciphertext.

=head2 decrypt_aes_256_cbc

    $plaintext = decrypt_aes_256_cbc($ciphertext_filepath, $secret);
    $plaintext = decrypt_aes_256_cbc(\$ciphertext, $secret);
    decrypt_aes_256_cbc($ciphertext_filepath, $secret, $plaintext_filepath);
    decrypt_aes_256_cbc(\$ciphertext, $secret, $plaintext_filepath);

Do symmetric decryption. Turn ciphertext into plaintext.

=head2 encrypt_aes_256_cbc

    $ciphertext = encrypt_aes_256_cbc($plaintext_filepath, $secret);
    $ciphertext = encrypt_aes_256_cbc(\$plaintext, $secret);
    encrypt_aes_256_cbc($plaintext_filepath, $secret, $ciphertext_filepath);
    encrypt_aes_256_cbc(\$plaintext, $secret, $ciphertext_filepath);

Do symmetric encryption. Turn plaintext into ciphertext.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/groupsecret/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Charles McGarvey.

This is free software, licensed under:

  The MIT (X11) License

=cut
