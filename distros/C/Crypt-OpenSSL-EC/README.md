# Crypt-OpenSSL-EC

This is Crypt::OpenSSL::EC, an XS-wrapper around the OpenSSL EC (Elliptic
Curves) library.

## INSTALLATION

To compile and install this module type the following:

```shell
perl Makefile.PL
make
make test
make install
```

The compilation requires library named `libcrypto` and the respective C language include files. Before `Makefile.PL` calls `WriteMakefile` function, it automatically uses the following environment variables and utilities to set the initial value for the function's `LIBS` and `INC` attributes. The following variables and utilities are used in the order they are listed:

- Environment variable `OPENSSL_PREFIX`
- A pair of environment variables `OPENSSL_LIB` and `OPENSSL_INCLUDE`
- `pkg-config` utility
- Only on Windows: `LIBS` is set to `-llibeay32` or `-leay32` depending on the compiler.

The initial values may be updated to ensure the system defaults do not override the automatically set values.

### Environment variable examples

Environment variables also work on Windows systems.

Point to a directory with subdirectories named `lib` and `include` to set `LIBS` and `INC`. Library `-lcrypto` is always appended to `LIBS`.

```shell
OPENSSL_PREFIX=$HOME/opt/openssl-3.6.0 perl Makefile.PL
make
make test
make install
```

Libraries and includes are not in a common subdirectory. `LIBS` and `INC` are set with separate variables. Note that `OPENSSL_LIB` needs both the path and library name in this case.

```shell
OPENSSL_LIB="$HOME/opt/openssl/lib/3.6.0 -lcrypto" OPENSSL_INCLUDE=$HOME/opt/openssl/include/3.6.0 perl Makefile.PL
make
make test
make install
```

## DEPENDENCIES

This module requires these other modules and libraries:

* Crypt::OpenSSL::Bignum 0.04 or later
* OpenSSL 0.9.8i or later headers and libraries for compilation

To build you will also need (but may already be installed on your OS):

* make
* gcc
* ExtUtils::MakeMaker
* Test::Simple

## COPYRIGHT AND LICENCE

Copyright (C) 2012 by Mike McCauley  
Copyright (C) 2026 by Heikki Vatiainen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

Terms of Perl version 5.14.2 are:

a) the GNU General Public License as published by the Free
   Software Foundation; either version 1, or (at your option) any
   later version, or

b) the "Artistic License"
