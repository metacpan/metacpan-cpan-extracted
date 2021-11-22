# NAME

Crypt::OpenSSL::PKCS12 - Perl extension to OpenSSL's PKCS12 API.

# SYNOPSIS

    use Crypt::OpenSSL::PKCS12;

    my $pass   = "your password";
    my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file('cert.p12');

    print $pkcs12->certificate($pass);
    print $pkcs12->private_key($pass);

    if ($pkcs12->mac_ok($pass)) {
    ...

    # Creating a file
    $pkcs12->create('test-cert.pem', 'test-key.pem', $pass, 'out.p12', 'friendly name');


    # Creating a string
    my $pksc12_data = $pkcs12->create_as_string('test-cert.pem', 'test-key.pem', $pass, 'friendly name');

# VERSION

This documentation describes version 1.9

# DESCRIPTION

PKCS12 is a file format for storing cryptography objects as a single file or string. PKCS12 is commonly used to bundle a private key with its X.509 certificate or to bundle all the members of a chain of trust.

This distribution implements a subset of OpenSSL's PKCS12 API.

# SUBROUTINES/METHODS

- new( )
- new\_from\_string( `$string` )
- new\_from\_file( `$filename` )

    Create a new Crypt::OpenSSL::PKCS12 instance.

- certificate( \[`$pass`\] )

    Get the Base64 representation of the certificate.

- private\_key( \[`$pass`\] )

    Get the Base64 representation of the private key.

- as\_string( \[`$pass`\] )

    Get the binary represenation as a string.

- mac\_ok( \[`$pass`\] )

    Verifiy the certificates Message Authentication Code

- changepass( `$old`, `$new` )

    Change a certificate's password.

- create( `$cert`, `$key`, `$pass`, `$output_file`, `$friendly_name` )

    Create a new PKCS12 certificate. $cert & $key may either be strings or filenames.

    `$friendly_name` is optional.

- create\_as\_string( `$cert`, `$key`, `$pass`, `$friendly_name` )

    Create a new PKCS12 certificate string. $cert & $key may either be strings or filenames.

    `$friendly_name` is optional.

    Returns a string holding the PKCS12 certicate.

# EXPORTS

None by default.

On request:

- `NOKEYS`
- `NOCERTS`
- `INFO`
- `CLCERTS`
- `CACERTS`

# DIAGNOSTICS

No diagnostics are documented at this time

# CONFIGURATION AND ENVIRONMENT

No special environment or configuration is required.

# DEPENDENCIES

This distribution has the following dependencies

- An installation of OpenSSL, version 1.X.X
- Perl 5.8

# SEE ALSO

- OpenSSL(1) ([HTTP version with OpenSSL.org](https://www.openssl.org/docs/man1.1.1/man1/openssl.html))
- [Crypt::OpenSSL::X509](https://metacpan.org/pod/Crypt::OpenSSL::X509)
- [Crypt::OpenSSL::RSA](https://metacpan.org/pod/Crypt::OpenSSL::RSA)
- [Crypt::OpenSSL::Bignum](https://metacpan.org/pod/Crypt::OpenSSL::Bignum)
- [OpenSSL.org](https://www.openssl.org/)
- [Wikipedia: PKCS12](https://en.wikipedia.org/wiki/PKCS_12)
- [RFC:7292: "PKCS #12: Personal Information Exchange Syntax v1.1"](https://datatracker.ietf.org/doc/html/rfc7292)

# INCOMPATIBILITIES

Currently the library only supports OpenSSL 1.X.X

The library has not been tested with OpenSSL 3.X.X and is not expected to work with this version at this time

# BUGS AND LIMITATIONS

Please see the [GitHub repository](https://github.com/dsully/perl-crypt-openssl-pkcs12/issues) for known issues.

# AUTHOR

- Dan Sully, <daniel@cpan.org>

Current maintainer

- jonasbn

# CONTRIBUTORS

In alphabetical order, contributors, bug reporters and all

- @mmuehlenhoff
- @sectokia
- @SmartCodeMaker
- Alexandr Ciornii, @chorny
- Christopher Hoskin, @mans0954
- Daisuke Murase, @typester
- Darko Prelec, @dprelec
- David Steinbrunner, @dsteinbrunner
- Giuseppe Di Terlizzi, @giterlizzi
- H.Merijn Brand, @tux
- Hakim, @osfameron
- J. Nick Koston, @bdraco
- James Rouzier, @jrouzierinverse
- jonasbn. @jonasbn
- Kelson, @kelson42
- Lance Wicks, @lancew
- Leonid Antonenkov
- Masayuki Matsuki, @songmu
- Mikołaj Zalewski
- Shoichi Kaji
- Slaven Rezić
- Todd Rinaldo, @toddr

# LICENSE AND COPYRIGHT

Copyright 2004-2021 by Dan Sully

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
