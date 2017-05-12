# $Id: Keys.pm,v 1.10 2001/08/28 23:31:09 btrott Exp $

package Crypt::Keys;
use strict;

use vars qw( $VERSION );
$VERSION = '0.06';

use Crypt::Keys::ErrorHandler;
use base qw( Crypt::Keys::ErrorHandler );

sub read {
    my $class = shift;
    my %param = @_;
    my $file = $param{Filename} or
        return $class->error("Filename is required");
    local *FH;
    open FH, $file
        or return $class->error("Error opening $file: $!");
    my $blob; do { local $/; $blob = <FH> };
    close FH or warn "Error closing $file: $!";
    my($format);
    unless ($format = $param{Format}) {
        $format = $class->detect(Content => $blob);
        $format = $format->{Format} if $format;
    }
    return $class->error("Undefined file format") unless $format;
    my $key_class = join '::', __PACKAGE__, $format;
    eval "use $key_class;";
    return $class->error("Unsupported format $format: $@") if $@;
    my $data = $key_class->deserialize(Content => $blob, @_) or return;
    {
        Data => $data,
        Format => $format,
    };
}

sub write {
    my $class = shift;
    my %param = @_;
    my $file = $param{Filename} or
        return $class->error("Filename is required");
    my $format = $param{Format} || $param{Data}->{Format} || 
        return $class->error("Format is required");
    my $key_class = join '::', __PACKAGE__, $format;
    eval "use $key_class;";
    return $class->error("Unsupported format $format: $@") if $@;
    my $data = delete $param{Data};
    my $blob = $key_class->serialize(@_, Data => $data->{Data});
    local *FH;
    open FH, ">$file" or return $class->error("Error opening $file: $!");
    print FH $blob;
    close FH or warn "Error closing $file: $!";
    1;
}

sub fingerprint {
    my $class = shift;
    my %param = @_;
    my($key);
    unless ($key = $param{Key}) {
        $key = $class->read(@_);
    }
    my $format = $param{Format} || "Hex";
    my $fp_class = join '::', __PACKAGE__, "FingerPrint::$format";
    eval "use $fp_class;";
    return $class->error("Unsupported fingerprint format $format: $@") if $@;
    $fp_class->encode( $key->fingerprint_raw );
}

sub detect {
    my $class = shift;
    my %param = @_;
    my $content;
    unless ($content = $param{Content}) {
        my $file = $param{Filename} or
            return $class->error("Need either 'Content' or 'Filename'");
        local *FH;
        open FH, $file or
            return $class->error("Opening '$file' failed: $!");
        CORE::read(FH, $content, 150);
        close FH;
    }
    my $type = _get_type($content);
    { Format => $type->[0], Description => $type->[1] };
}

{
    my %MAGIC;
    sub _get_type {
        my($content) = @_;
        my $type;
        for my $key (keys %MAGIC) {
            my $ref = $MAGIC{$key};
            my @checks = @{ $ref }[1..$#$ref];
            for my $re (@checks) {
                $type = $key, last if $content =~ /$re/;
            }
        }
        $type ? $MAGIC{$type}->[0] : undef;
    }

    %MAGIC = (
        rsa => [
               [ 'Private::RSA::PEM',
                 'RSA Private Key, PEM-encoded' ],
               '^-----BEGIN RSA PRIVATE KEY-----'
        ],

        dsa => [
               [ 'Private::DSA::PEM',
                 'DSA Private Key, PEM-encoded' ],
               '^-----BEGIN DSA PRIVATE KEY-----',
        ],

        dsa2 => [
               [ 'Private::DSA::SSH2',
                 'DSA Private Key, SSH2-encoded' ],
               '^---- BEGIN SSH2 ENCRYPTED PRIVATE KEY ----',
        ],

        rsa1 => [
               [ 'Private::RSA::SSH1',
                 'RSA Private Key, SSH1-encoded' ],
               '^SSH PRIVATE KEY FILE FORMAT 1\.1',
        ],

        rsapub1 => [
               [ 'Public::RSA::SSH1',
                 'RSA Public Key, SSH1-encoded' ],
               '^\d{3,4}\s+\d{2}\s+\d+'
        ],

        rsapubos => [
               [ 'Public::RSA::OpenSSH',
                 'RSA Public Key, OpenSSH-encoded' ],
               '^ssh-rsa\s+'
        ],

        dsapubos => [
               [ 'Public::DSA::OpenSSH',
                 'DSA Public Key, OpenSSH-encoded' ],
               '^ssh-dss\s+'
        ],
    );
}

1;
__END__

=head1 NAME

Crypt::Keys - On-disk management of public and private keyfiles

=head1 SYNOPSIS

    use Crypt::Keys;
    my $key_data = Crypt::Keys->read( Filename => $key_file );

    Crypt::Keys->write(
                    Filename   => $key_file,
                    Passphrase => 'foo',
                    Data       => $key_data,
              );

    my $key_type = Crypt::Keys->detect( Content => $key_content );

=head1 DESCRIPTION

I<Crypt::Keys> is an on-disk key management system for public and
private keyfiles. The goal of the module is to be able to read
and write crypto keys in any encoding (eg. PEM, SSH, etc.). It can
be used as a front-end for key management, but it does not contain
implementations of any of the assymetric cryptography algorithms
represented by the keys that it manages. In other words, you can use
it to read and write your DSA/RSA/etc. keys, but it does not generate
new keys or encrypt/sign data.

I<Crypt::Keys> is useful for authors of the modules that implement
those algorithms, however, because it provides all of the backend
storage mechanisms to get the keys in and out of the filesystem.
There are many key encodings for common key algorithms; I<Crypt::Keys>
ensures that the authors of the implementation do not have to
worry about the myriad formats but only about the algorithms.

=head1 USAGE

=head2 $key_data = Crypt::Keys->read( %args )

Reads a key from disk. If you specify a format/encoding for the key
(see below), I<Crypt::Keys> will try to read the file using that
encoding. Otherwise I<Crypt::Keys> will detect the type of the file
and use the appropriate encoding plugin automatically.

I<%args> can include:

=over 4

=item Format

Specifies the format of the keyfile, ie. the class to be used when
decoding the keyfile. Possible formats are: C<Private::DSA::PEM>,
C<Public::RSA::SSH1>, etc.

This argument is optional; if not specified I<read> will look at
the beginning of the file to determine its format, then will
automatically use the correct class to decode that format.

=item Filename

The path to the key file. This argument is required.

=item Passphrase

If the keyfile is encrypted, a passphrase will be needed in order
to decrypt it. Specify that passphrase here.

This argument is optional; if the keyfile is encrypted, and you
do not provide a passphrase, I<read> will return C<undef>, and
I<errstr> will be set accordingly (see below).

=back

Returns a reference to a hash containing these keys:

=over 4

=item Data

The key data. The contents of I<Data> vary depending on the type
of key.

=item Format

The name of the class used to decode the keyfile.

=back

If an error occurs while reading/decoding the keyfile, I<read>
returns C<undef>, and you should call I<errstr> to determine the
source of the error (see I<ERROR HANDLING>, below).

=head2 Crypt::Keys->write( %args )

Encodes and writes key data to a keyfile, encrypting it if
requested.

I<%args> can include:

=over 4

=item * Filename

The path to the file where the encoded key should be written.

This argument is required.

=item * Data

The key data to be written. This should be a reference to a hash
containing the keys described above in the return value from
I<read>. In fact, the argument to I<Data> should look exactly
like the return value from I<read>.

This argument is required.

=item * Passphrase

If you wish to encrypt the contents of the key before storing them
on disk, you can do so by specifying a passphrase.

This argument is optional.

=item * Format

Specifies the format in which the key should be encoded.

This argument is optional if the key was read in from disk using
I<read>; in that case, if I<Format> is unspecified the key will be
written to disk in the same format in which it was read.

=item * Comment

A comment for the key.

This argument is optional.

=back

I<write> returns true on success, and C<undef> on failure; in the
latter case you should use I<errstr> to determine what went wrong
(see I<ERROR HANDLING>, below).

=head2 Crypt::Keys->detect( %args )

Detects the format in which a key is encoded (eg. PEM), and the type
of key that is encoded (eg. DSA).

I<%args> can contain:

=over 4

=item * Content

A scalar string of the encoded key contents, or at least part of the key
contents; if the string contains only part of the contents, the piece
must be taken from the beginning of the encoded key.

This argument is optional; if not provided, I<Filename> must be provided.

=item * Filename

The path to a file on disk containing the encoded key contents.

This argument is optional; if not provided, I<Content> must be provided.

=back

Returns a hash reference containing these keys:

=over 4

=item * Format

The format of the key, in the form of the name of the class that
provides the encoding/decoding for that format. For example,
C<Private::DSA::PEM> for a PEM-encoded private DSA key. This is
the same I<Format> that can be passed to I<read> and I<write>.

=item * Description

A textual description of the keyfile.

=back

On failure I<detect> returns C<undef>.

=head1 ERROR HANDLING

If an error occurs while reading/writing/detecting a keyfile, the
method you called will return C<undef>. You should then call the
method I<errstr> to determine the error:

    Crypt::Keys->errstr

For example, if you try to read an encrypted keyfile and you do
not give a passphrase:

    my $key = Crypt::Keys->read( Filename => $key_file )
        or die "Could not read key file: ", Crypt::Keys->errstr;

=head1 AUTHOR & COPYRIGHT

Benjamin Trott, ben@rhumba.pair.com

Except where otherwise noted, Crypt::Keys is Copyright 2001
Benjamin Trott. All rights reserved. Crypt::Keys is free software;
you may redistribute it and/or modify it under the same terms as
Perl itself.

=cut
