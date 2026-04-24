package Crypt::RIPEMD160;

use strict;
use warnings;

our $VERSION = '0.14';

use XSLoader;
XSLoader::load('Crypt::RIPEMD160', $VERSION);

use base 'Digest::base';

#package RIPEMD160; # Package-Definition like in Crypt::IDEA

#use strict;
use Carp;

sub addfile
{
    no strict 'refs';
    my ($self, $handle) = @_;
    my ($package, $file, $line) = caller;
    my ($data);

    if (!ref($handle)) {
	$handle = $package . "::" . $handle unless ($handle =~ /(\:\:|\')/);
    }
    binmode($handle);
    my $n;
    while ($n = read($handle, $data, 8192)) {
	$self->add($data);
    }
    croak "addfile read failed: $!" unless defined $n;
    return $self;
}

sub hexdigest
{
    my ($self) = shift;
    my ($tmp);

    $tmp = unpack("H*", ($self->digest()));
    return(substr($tmp, 0,8) . " " . substr($tmp, 8,8) . " " .
	   substr($tmp,16,8) . " " . substr($tmp,24,8) . " " .
	   substr($tmp,32,8));
}

sub hash
{
    my($self, $data) = @_;

    if (ref($self)) {
	$self->reset();
    } else {
	$self = Crypt::RIPEMD160->new;
    }
    $self->add($data);
    $self->digest();
}

sub hexhash
{
    my($self, $data) = @_;

    if (ref($self)) {
	$self->reset();
    } else {
	$self = Crypt::RIPEMD160->new;
    }
    $self->add($data);
    $self->hexdigest();
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=for markdown [![testsuite](https://github.com/cpan-authors/Crypt-RIPEMD160/actions/workflows/testsuite.yml/badge.svg)](https://github.com/cpan-authors/Crypt-RIPEMD160/actions/workflows/testsuite.yml)

=head1 NAME

Crypt::RIPEMD160 - Perl extension for the RIPEMD-160 Hash function

=head1 SYNOPSIS

    use Crypt::RIPEMD160;
    
    $context = Crypt::RIPEMD160->new;
    $context->reset();
    
    $context->add(LIST);
    $context->addfile(HANDLE);

    $digest = $context->digest();
    $string = $context->hexdigest();
    $string = $context->b64digest();

    $copy = $context->clone();

    $digest = Crypt::RIPEMD160->hash(SCALAR);
    $string = Crypt::RIPEMD160->hexhash(SCALAR);

    # Via the Digest module
    use Digest;
    $context = Digest->new('RIPEMD-160');

=head1 DESCRIPTION

The B<Crypt::RIPEMD160> module allows you to use the RIPEMD160
Message Digest algorithm from within Perl programs.

The module is based on the implementation from Antoon Bosselaers from
Katholieke Universiteit Leuven.

It inherits from L<Digest::base>, so it supports the standard Perl
L<Digest> API including B<b64digest> and B<add_bits>. It can be
loaded via C<< Digest->new('RIPEMD-160') >>.

=head1 METHODS

=head2 new

    my $context = Crypt::RIPEMD160->new;

Creates and returns a new RIPEMD-160 context object. Multiple
simultaneous digest contexts can be maintained.

=head2 reset

    $context->reset();

Reinitializes the context, discarding any accumulated data. Must be
called after B<digest> before reusing the same context.  Returns
the context, so calls can be chained:

    $context->reset->add($data);

=head2 add

    $context->add(LIST);

Appends the strings in I<LIST> to the message. C<add('foo', 'bar')>,
C<add('foo')> followed by C<add('bar')>, and C<add('foobar')> all
produce the same result.  Returns the context for method chaining:

    $context->add('foo')->add('bar');

=head2 addfile

    $context->addfile(HANDLE);

Reads from the open file-handle in 8192 byte blocks and adds the
contents to the context. The handle can be a lexical filehandle, a
type-glob reference, or a bare name. The handle is set to binary mode
via C<binmode> to prevent CRLF translation on Windows.

=head2 digest

    my $digest = $context->digest();

Returns the final message digest as a 20-byte binary string. This is a
destructive, read-once operation: the context must be B<reset> before
computing another digest.

=head2 hexdigest

    my $string = $context->hexdigest();

Calls B<digest> and returns the result as a printable string of
hexadecimal digits in five space-separated groups of eight characters.

B<Note:> This format differs from the continuous hex string returned
by most L<Digest> modules. For a continuous hex string, use
C<< unpack("H*", $context->digest()) >>.

=head2 b64digest

    my $string = $context->b64digest();

Returns the digest as a base64-encoded string (without trailing padding).
This method is inherited from L<Digest::base>.

=head2 clone

    my $copy = $context->clone();

Creates an independent copy of the current context, preserving all
accumulated state. Useful for computing digests of data that share a
common prefix without re-processing the shared portion.

=head2 hash

    my $digest = Crypt::RIPEMD160->hash(SCALAR);
    my $digest = $context->hash(SCALAR);

Convenience method that performs the complete cycle (reset, add, digest)
on the supplied scalar. Can be called as a class method (creates a
temporary context) or on an existing instance (slightly more efficient).

=head2 hexhash

    my $string = Crypt::RIPEMD160->hexhash(SCALAR);
    my $string = $context->hexhash(SCALAR);

Like B<hash>, but returns the result as a hex string (same format as
B<hexdigest>).

=head1 EXAMPLES

    use Crypt::RIPEMD160;
    
    $ripemd160 = Crypt::RIPEMD160->new;
    $ripemd160->add('foo', 'bar');
    $ripemd160->add('baz');
    $digest = $ripemd160->digest();
    
    print("Digest is " . unpack("H*", $digest) . "\n");

The above example would print out the message

    Digest is f137cb536c05ec2bc97e73327937b6e81d3a4cc9

provided that the implementation is working correctly.

Remembering the Perl motto ("There's more than one way to do it"), the
following should all give the same result:

    use Crypt::RIPEMD160;
    $ripemd160 = Crypt::RIPEMD160->new;

    open(my $fh, '<', '/etc/passwd')
        or die "Can't open /etc/passwd: $!\n";

    seek($fh, 0, 0);
    $ripemd160->reset;
    $ripemd160->addfile($fh);
    $d = $ripemd160->hexdigest;
    print "addfile (lexical filehandle) = $d\n";

    seek($fh, 0, 0);
    $ripemd160->reset;
    while (<$fh>)
    {
        $ripemd160->add($_);
    }
    $d = $ripemd160->hexdigest;
    print "Line at a time = $d\n";

    seek($fh, 0, 0);
    $ripemd160->reset;
    $ripemd160->add(<$fh>);
    $d = $ripemd160->hexdigest;
    print "All lines at once = $d\n";

    seek($fh, 0, 0);
    $ripemd160->reset;
    while (read($fh, $data, int(rand(128)) + 1))
    {
        $ripemd160->add($data);
    }
    $d = $ripemd160->hexdigest;
    print "Random chunks = $d\n";

    seek($fh, 0, 0);
    $ripemd160->reset;
    local $/;
    $data = <$fh>;
    $d = $ripemd160->hexhash($data);
    print "Single string = $d\n";

    close($fh);

=head1 NOTE

The RIPEMD160 extension may be redistributed under the same terms as Perl.
The RIPEMD160 algorithm is published in "Fast Software Encryption, LNCS 1039,
D. Gollmann (Ed.), pp.71-82".

The basic C code implementing the algorithm is covered by the
following copyright:

=over 1

C<
/********************************************************************\
 *
 *      FILE:     rmd160.c
 *
 *      CONTENTS: A sample C-implementation of the RIPEMD-160
 *                hash-function.
 *      TARGET:   any computer with an ANSI C compiler
 *
 *      AUTHOR:   Antoon Bosselaers, ESAT-COSIC
 *      DATE:     1 March 1996
 *      VERSION:  1.0
 *
 *      Copyright (c) Katholieke Universiteit Leuven
 *      1996, All Rights Reserved
 *
\********************************************************************/
>

=back

=head1 RIPEMD-160 test suite results (ASCII):

C<
* message: "" (empty string)
  hashcode: 9c1185a5c5e9fc54612808977ee8f548b2258d31
* message: "a"
  hashcode: 0bdc9d2d256b3ee9daae347be6f4dc835a467ffe
* message: "abc"
  hashcode: 8eb208f7e05d987a9b044a8e98c6b087f15a0bfc
* message: "message digest"
  hashcode: 5d0689ef49d2fae572b881b123a85ffa21595f36
* message: "abcdefghijklmnopqrstuvwxyz"
  hashcode: f71c27109c692c1b56bbdceb5b9d2865b3708dbc
* message: "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
  hashcode: 12a053384a9c0c88e405a06c27dcf49ada62eb2b
* message: "A...Za...z0...9"
  hashcode: b0e20b6e3116640286ed3a87a5713079b21f5189
* message: 8 times "1234567890"
  hashcode: 9b752e45573d4b39f4dbd3323cab82bf63326bfb
* message: 1 million times "a"
  hashcode: 52783243c1697bdbe16d37f97f68f08325dc1528
>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl you may have available.

See L<https://dev.perl.org/licenses/> for more information.

=head1 AUTHOR

The RIPEMD-160 interface was written by Christian H. Geuer-Pollmann (CHGEUER)
(C<geuer-pollmann@nue.et-inf.uni.siegen.de>) and Ken Neighbors (C<ken@nsds.com>).

=head1 SEE ALSO

MD5(3pm) and SHA(1).

=cut
