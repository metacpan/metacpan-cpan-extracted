# NAME

Dancer2::Plugin::Passphrase - Passphrases and Passwords as objects for Dancer2

# SYNOPSIS

This plugin manages the hashing of passwords for Dancer2 apps, allowing 
developers to follow cryptography best practices without having to 
become a cryptography expert.

It uses the bcrypt algorithm as the default, while also supporting any
hashing function provided by [Digest](https://metacpan.org/pod/Digest) 

# MORE INFORMATION

## Purpose

The aim of this module is to help you store new passwords in a secure manner, 
whilst still being able to verify and upgrade older passwords.

Cryptography is a vast and complex field. Many people try to roll their own 
methods for securing user data, but succeed only in coming up with 
a system that has little real security.

This plugin provides a simple way of managing that complexity, allowing 
developers to follow crypto best practice without having to become an expert.

## Rationale

The module defaults to hashing passwords using the bcrypt algorithm, returning them
in RFC 2307 format.

RFC 2307 describes an encoding system for passphrase hashes, as used in the "userPassword"
attribute in LDAP databases. It encodes hashes as ASCII text, and supports several 
passphrase schemes by starting the encoding with an alphanumeric scheme identifier enclosed 
in braces.

RFC 2307 only specifies the `MD5`, and `SHA` schemes - however in real-world usage,
schemes that are salted are widely supported, and are thus provided by this module.

Bcrypt is an adaptive hashing algorithm that is designed to resist brute 
force attacks by including a cost (aka work factor). This cost increases 
the computational effort it takes to compute the hash.

SHA and MD5 are designed to be fast, and modern machines compute a billion 
hashes a second. With computers getting faster every day, brute forcing 
SHA hashes is a very real problem that cannot be easily solved.

Increasing the cost of generating a bcrypt hash is a trivial way to make 
brute forcing ineffective. With a low cost setting, bcrypt is just as secure 
as a more traditional SHA+salt scheme, and just as fast. Increasing the cost
as computers become more powerful keeps you one step ahead

For a more detailed description of why bcrypt is preferred, see this article: 
[http://codahale.com/how-to-safely-store-a-password/](http://codahale.com/how-to-safely-store-a-password/)

## Common Mistakes

Common mistakes people make when creating their own solution. If any of these 
seem familiar, you should probably be using this module

- Passwords are stored as plain text for a reason

    There is never a valid reason to store a password as plain text.
    Passwords should be reset and not emailed to customers when they forget.
    Support people should be able to login as a user without knowing the users password.
    No-one except the user should know the password - that is the point of authentication.

- No-one will ever guess our super secret algorithm!

    Unless you're a cryptography expert with many years spent studying 
    super-complex maths, your algorithm is almost certainly not as secure 
    as you think. Just because it's hard for you to break doesn't mean
    it's difficult for a computer.

- Our application-wide salt is "Sup3r\_S3cret\_L0ng\_Word" - No-one will ever guess that.

    This is common misunderstanding of what a salt is meant to do. The purpose of a 
    salt is to make sure the same password doesn't always generate the same hash.
    A fresh salt needs to be created each time you hash a password. It isn't meant 
    to be a secret key.

- We generate our random salt using `rand`.

    `rand` isn't actually random, it's a non-unform pseudo-random number generator, 
    and not suitable for cryptographic applications. Whilst this module also defaults to 
    a PRNG, it is better than the one provided by `rand`. Using a true RNG is a config
    option away, but is not the default as it it could potentially block output if the
    system does not have enough entropy to generate a truly random number

- We use `md5(pass.salt)`, and the salt is from `/dev/random`

    MD5 has been broken for many years. Commodity hardware can find a 
    hash collision in seconds, meaning an attacker can easily generate 
    the correct MD5 hash without using the correct password.

- We use `sha(pass.salt)`, and the salt is from `/dev/random`

    SHA isn't quite as broken as MD5, but it shares the same theoretical 
    weaknesses. Even without hash collisions, it is vulnerable to brute forcing.
    Modern hardware is so powerful it can try around a billion hashes a second. 
    That means every 7 chracter password in the range \[A-Za-z0-9\] can be cracked 
    in one hour on your average desktop computer.

- If the only way to break the hash is to brute-force it, it's secure enough

    It is unlikely that your database will be hacked and your hashes brute forced.
    However, in the event that it does happen, or SHA512 is broken, using this module
    gives you an easy way to change to a different algorithm, while still allowing
    you to validate old passphrases
