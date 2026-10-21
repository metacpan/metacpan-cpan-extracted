Crypter: new kind of cryptography!


# Installation

```
curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Crypter
```

# Using Crypter

## Encryct file

## Crypting by a password

USE STRONG PASSWORDS ONLY!

```
crypter --password=... -i .. -o ..
```

```
crypter -d --password=... -i .. -o ..
```

## Pipe-line processing

USE STRONG PASSWORDS ONLY!

```
echo 'Hello World!' | crypter -p 123456 | crypter -p 123456
echo 'Hello World!' | crypter -p 123456 --obfuscate=10 | crypter -p 123456 --obfuscate=10 -d -
```

## Password Genrator

```
crypter --pwdgen
```

## Noise Generator

```
crypter --noise
```

# Credits

Crypter coded by Ivan Trunaev, Russia, Uray.

Based of XOR-algorithm and Black-Noise Generator Strong::Random, developed by Ivan Trunaev.
