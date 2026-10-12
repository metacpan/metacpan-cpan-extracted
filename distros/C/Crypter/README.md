Crypter: new kind of cryptography!


# Installation

```
curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Crypter
```

# Using Crypter

## Encryct file

```
crypter --salt=Strong_Slat_Like_Next__LqEI96iqFeOvaBgzxc3wr23r3rrarM8ic7mp --input=test.txt --output=test.txt.crypted
```

Crypter will generate test.txt.crypted and test.txt.crypted.key files. test.txt.crypted.key - keyfile for uncrypting!

Slat needed only for strong keyfile generation! 

Don't use salt more longer than encrtyped information, it's unneeded!

Keep keyfiles protect!

## Uncrypting file

Put encryptedfile file and keyfile in same folder, and run uncrypter:

```
crypter -d test.txt.crypted
```
## Obfuscate

Crypted possible to add random data before each crypted symbol in file.

```
crypter --obfuscate=100 -i .. -o ..
```

Will be add between 0..99 random symbols!

Same command-line option need for decrypring!

```
crypter -d --obfuscate=100 -i ...
```

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
