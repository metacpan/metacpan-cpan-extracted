[![testsuite](https://github.com/cpan-authors/Crypt-RIPEMD160/actions/workflows/testsuite.yml/badge.svg)](https://github.com/cpan-authors/Crypt-RIPEMD160/actions/workflows/testsuite.yml)

# NAME

Crypt::RIPEMD160 - Perl extension for the RIPEMD-160 Hash function

# SYNOPSIS

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

# DESCRIPTION

The **Crypt::RIPEMD160** module allows you to use the RIPEMD160
Message Digest algorithm from within Perl programs.

The module is based on the implementation from Antoon Bosselaers from
Katholieke Universiteit Leuven.

It inherits from [Digest::base](https://metacpan.org/pod/Digest%3A%3Abase), so it supports the standard Perl
[Digest](https://metacpan.org/pod/Digest) API including **b64digest** and **add\_bits**. It can be
loaded via `Digest->new('RIPEMD-160')`.

# METHODS

## new

    my $context = Crypt::RIPEMD160->new;

Creates and returns a new RIPEMD-160 context object. Multiple
simultaneous digest contexts can be maintained.

## reset

    $context->reset();

Reinitializes the context, discarding any accumulated data. Must be
called after **digest** before reusing the same context.  Returns
the context, so calls can be chained:

    $context->reset->add($data);

## add

    $context->add(LIST);

Appends the strings in _LIST_ to the message. `add('foo', 'bar')`,
`add('foo')` followed by `add('bar')`, and `add('foobar')` all
produce the same result.  Returns the context for method chaining:

    $context->add('foo')->add('bar');

## addfile

    $context->addfile(HANDLE);

Reads from the open file-handle in 8192 byte blocks and adds the
contents to the context. The handle can be a lexical filehandle, a
type-glob reference, or a bare name. The handle is set to binary mode
via `binmode` to prevent CRLF translation on Windows.

## digest

    my $digest = $context->digest();

Returns the final message digest as a 20-byte binary string. This is a
destructive, read-once operation: the context must be **reset** before
computing another digest.

## hexdigest

    my $string = $context->hexdigest();

Calls **digest** and returns the result as a printable string of
hexadecimal digits in five space-separated groups of eight characters.

**Note:** This format differs from the continuous hex string returned
by most [Digest](https://metacpan.org/pod/Digest) modules. For a continuous hex string, use
`unpack("H*", $context->digest())`.

## b64digest

    my $string = $context->b64digest();

Returns the digest as a base64-encoded string (without trailing padding).
This method is inherited from [Digest::base](https://metacpan.org/pod/Digest%3A%3Abase).

## clone

    my $copy = $context->clone();

Creates an independent copy of the current context, preserving all
accumulated state. Useful for computing digests of data that share a
common prefix without re-processing the shared portion.

## hash

    my $digest = Crypt::RIPEMD160->hash(SCALAR);
    my $digest = $context->hash(SCALAR);

Convenience method that performs the complete cycle (reset, add, digest)
on the supplied scalar. Can be called as a class method (creates a
temporary context) or on an existing instance (slightly more efficient).

## hexhash

    my $string = Crypt::RIPEMD160->hexhash(SCALAR);
    my $string = $context->hexhash(SCALAR);

Like **hash**, but returns the result as a hex string (same format as
**hexdigest**).

# EXAMPLES

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

# NOTE

The RIPEMD160 extension may be redistributed under the same terms as Perl.
The RIPEMD160 algorithm is published in "Fast Software Encryption, LNCS 1039,
D. Gollmann (Ed.), pp.71-82".

The basic C code implementing the algorithm is covered by the
following copyright:

> `
> /********************************************************************\
>  *
>  *      FILE:     rmd160.c
>  *
>  *      CONTENTS: A sample C-implementation of the RIPEMD-160
>  *                hash-function.
>  *      TARGET:   any computer with an ANSI C compiler
>  *
>  *      AUTHOR:   Antoon Bosselaers, ESAT-COSIC
>  *      DATE:     1 March 1996
>  *      VERSION:  1.0
>  *
>  *      Copyright (c) Katholieke Universiteit Leuven
>  *      1996, All Rights Reserved
>  *
> \********************************************************************/
> `

# RIPEMD-160 test suite results (ASCII):

`
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
`

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl you may have available.

See [https://dev.perl.org/licenses/](https://dev.perl.org/licenses/) for more information.

# AUTHOR

The RIPEMD-160 interface was written by Christian H. Geuer-Pollmann (CHGEUER)
(`geuer-pollmann@nue.et-inf.uni.siegen.de`) and Ken Neighbors (`ken@nsds.com`).

# SEE ALSO

MD5(3pm) and SHA(1).
