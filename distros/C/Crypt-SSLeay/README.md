# Crypt::SSLeay - OpenSSL support for LWP

## Do you need Crypt::SSLeay?

Since version 6.02, [LWP](https://metacpan.org/pod/LWP) depends on [LWP::Protocol::https](https://metacpan.org/pod/LWP::Protocol::https) which pulls in [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL) which is then automatically used by [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) unless you explicitly override it. So, you might no longer need `Crypt::SSLeay`. `IO::Socket::SSL` is preferable anyway because it allows hostname verification which `Crypt::SSLeay` does not support.

At this point, `Crypt::SSLeay` is maintained to support existing software that already depends on it. However, it is possible that your software does not really depend on `Crypt::SSLeay`, only on the ability of `LWP::UserAgent` to communicate with sites over SSL/TLS.

If you have both `Crypt::SSLeay` and `IO::Socket::SSL` installed, and would like to force `LWP::UserAgent` to use `Crypt::SSLeay`, you can use:

    use Net::HTTPS;
    $Net::HTTPS::SSL_SOCKET_CLASS = 'Net::SSL';
    use LWP::UserAgent;

or

    local $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'Net::SSL';
    use LWP::UserAgent;

or

    use Net::SSL;
    use LWP::UserAgent;

## OpenSSL Heartbleed Bug

`perl Makefile.PL` will show a warning if the version of OpenSSL against which you are building `Crypt::SSLeay` seems vulnerable to the [Heartbleed Bug](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-0160). See my blog post [Is a strong caution about Heartbleed worth the disruption to distributions with a declared dependency on Crypt::SSLeay?](http://blog.nu42.com/2014/04/is-strong-caution-about-heartbleed.html) for the reasoning behind this.

## Synopsis

    use Net::SSL;
    use LWP::UserAgent;

    my $ua  = LWP::UserAgent->new(
        ssl_opts => { verify_hostname => 0 },
    );

    my $response = $ua->get('https://www.example.com/');
    print $response->content, "\n";

## Description

This Perl module provides support for the HTTPS protocol under LWP, to allow an `LWP::UserAgent` object to perform GET, HEAD and POST requests.  Please see [LWP](https://metacpan.org/pod/LWP) for more information on POST requests.

The `Crypt::SSLeay` package provides `Net::SSL`, which is loaded by `LWP::Protocol::https` for https requests and provides the necessary SSL glue.

This distribution also makes following deprecated modules available:

    Crypt::SSLeay::CTX
    Crypt::SSLeay::Conn
    Crypt::SSLeay::X509

Work on Crypt::SSLeay has been continued only to provide https support for the LWP (libwww-perl) libraries.

## Environment Variables

The following environment variables change the way `Crypt::SSLeay` and `Net::SSL` behave.

### Specify SSL Socket Class

    $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS}

can be used to instruct `LWP::UserAgent` to use `Net::SSL` for HTTPS support rather than `IO::Socket::SSL`.

### Proxy Support

    $ENV{HTTPS_PROXY} = 'http://proxy_hostname_or_ip:port';

### Proxy Basic Authentication

    $ENV{HTTPS_PROXY_USERNAME} = 'username';
    $ENV{HTTPS_PROXY_PASSWORD} = 'password';

### SSL Diagnostics and Debugging

    $ENV{HTTPS_DEBUG} = 1;

### Default SSL Version

    $ENV{HTTPS_VERSION} = '3';

### Client Certificate Support

    $ENV{HTTPS_CERT_FILE} = 'certs/notacacert.pem';
    $ENV{HTTPS_KEY_FILE}  = 'certs/notacakeynopass.pem';

### CA cert peer verification

    $ENV{HTTPS_CA_FILE}   = 'certs/ca-bundle.crt';
    $ENV{HTTPS_CA_DIR}    = 'certs/';

### Client PKCS12 cert support

    $ENV{HTTPS_PKCS12_FILE}     = 'certs/pkcs12.pkcs12';
    $ENV{HTTPS_PKCS12_PASSWORD} = 'PKCS12_PASSWORD';

## Installation

### OpenSSL

You must have OpenSSL installed before compiling this module. You can get the latest OpenSSL package from [OpenSSL.org](https://www.openssl.org/source/). We no longer support pre-2000 versions of OpenSSL.

If you are building OpenSSL from source, please follow the directions included in the source package.

### Crypt::SSLeay via Makefile.PL

`Makefile.PL` accepts the following command line arguments:


#### incpath

Path to OpenSSL headers. Can also be specified via `$ENV{OPENSSL_INCLUDE}`. If the command line argument is provided, it overrides any value specified via the environment variable. Of course, you can ignore both the command line argument and the environment variable, and just add the path to your compiler specific environment variable such as `CPATH` or `INCLUDE` etc.

#### libpath

Path to OpenSSL libraries. Can also be specified via `$ENV{OPENSSL_LIB}`. If the command line argument is provided, it overrides any value specified by the environment variable. Of course, you can ignore both the command line argument and the environment variable and just add the path to your compiler specific environment variable such as `LIBRARY_PATH` or `LIB` etc.

#### live-tests

Use `--live-tests` to request tests that try to connect to an external web site, and "--no-live_tests" to prevent such tests from running. If you run `Makefile.PL` interactively, and this argument is not specified on the command line, you will be prompted for a value.

Default is false.


#### static

Boolean. Default is false. TODO: How is this even supposed to work?

#### verbose

Boolean. Default is false. If you pass `--verbose` on the command line, both "Devel::CheckLib" and "ExtUtils::CBuilder" instances will be configured to echo what they are doing.

If everything builds OK, but you get failures when during tests, ensure that `LD_LIBRARY_PATH`is pointing to the location where the correct shared libraries are located.

### Crypt::SSLeay

The latest `Crypt::SSLeay` can be found at your nearest CPAN, as well as on [metacpan](https://metacpan.org/dist/Crypt::SSLeay).

Once you have downloaded and extracted it, `Crypt::SSLeay` installs easily using the standard build process:

    perl Makefile.PL
    make
    make test
    make install

Alternatively, you can use [cpanm](https://metacpan.org/pod/App::cpanminus):

    cpanm Crypt::SSLeay

If you have OpenSSL headers and libraries in nonstandard locations, you can use

    $ perl Makefile.PL --incpath=... --libpath=...

If you would like to use "cpanm" with such custom locations, you can do

    $ OPENSSL_INCLUDE=... OPENSSL_LIB=... cpanm Crypt::SSLeay

or, on Windows,

    > set OPENSSL_INCLUDE=...
    > set OPENSSL_LIB=...
    > cpanm Crypt::SSLeay

If you are on Windows, and using a MinGW distribution bundled with ActiveState Perl or Strawberry Perl, you would use `dmake` rather than `make`. If you are using Microsoft's build tools, you would use `nmake`.

For unattended (batch) installations, to be absolutely certain that Makefile.PL does not prompt for questions on STDIN, set the environment variable `PERL_MM_USE_DEFAULT=1` as with any CPAN module built using `ExtUtils::MakeMaker`.

#### VMS

I do not have any experience with VMS. If OpenSSL headers and libraries are not in standard locations searched by your build system by default, please set things up so that they are. If you have generic instructions on how to do it, please open a ticket on RT with the information so I can add it to this document.

## Proxy Support

`LWP::UserAgent` and `Crypt::SSLeay` have their own versions of proxy support.  Please read these sections to see which one is appropriate.

### `LWP::UserAgent` proxy support

`LWP::UserAgent` has its own methods of proxying which may work for you and is likely to be incompatible with `Crypt::SSLeay` proxy support. To use `LWP::UserAgent` proxy support, try something like:

    my $ua = LWP::UserAgent->new;
    $ua->proxy([qw( https http )], "$proxy_ip:$proxy_port");

At the time of this writing, libwww v5.6 seems to proxy https requests fine with an Apache mod_proxy server. It sends a line like:

    GET https://www.example.com HTTP/1.1

to the proxy server, which is not the `CONNECT` request that some proxies would expect, so this may not work with other proxy servers than mod_proxy.  The `CONNECT` method is used by `Crypt::SSLeay`'s internal proxy support.

### `Crypt::SSLeay` proxy support

For native `Crypt::SSLeay` proxy support of https requests, you need to set the environment variable `HTTPS_PROXY` to your proxy server and port, as in:

    # proxy support
    $ENV{HTTPS_PROXY} = 'http://proxy_hostname_or_ip:port';
    $ENV{HTTPS_PROXY} = '127.0.0.1:8080';

Use of the `HTTPS_PROXY` environment variable in this way is similar to `LWP::UserAgent->env_proxy()` usage, but calling that method will likely override or break the `Crypt::SSLeay` support, so do not mix the two.

Basic authentication credentials to the proxy server can be provided this way:

    # proxy_basic_auth
    $ENV{HTTPS_PROXY_USERNAME} = 'username';
    $ENV{HTTPS_PROXY_PASSWORD} = 'password';

For an example of LWP scripting with `Crypt::SSLeay` native proxy support, please look at the `eg/lwp-ssl-test` script in the `Crypt::SSLeay` distribution.

## Client Certificate Support

Client certificates are supported. PEM encoded certificate and private key files may be used like this:

    $ENV{HTTPS_CERT_FILE} = 'certs/notacacert.pem';
    $ENV{HTTPS_KEY_FILE}  = 'certs/notacakeynopass.pem';

You may test your files with the `eg/net-ssl-test` program, bundled with the distribution, by issuing a command like:

    perl eg/net-ssl-test -cert=certs/notacacert.pem \
        -key=certs/notacakeynopass.pem -d GET $HOST_NAME

Additionally, if you would like to tell the client where the CA file is, you may set these.

        $ENV{HTTPS_CA_FILE} = "some_file";
        $ENV{HTTPS_CA_DIR}  = "some_dir";

Note that, if specified, `$ENV{HTTPS_CA_FILE}` must point to the actual certificate file. That is, `$ENV{HTTPS_CA_DIR}` is *not* the path where `$ENV{HTTPS_CA_FILE}` is located.

For certificates in `$ENV{HTTPS_CA_DIR}` to be picked up, follow the instructions on http://www.openssl.org/docs/ssl/SSL_CTX_load_verify_locations.html.

There is no sample CA cert file at this time for testing, but you may configure `eg/net-ssl-test` to use your CA cert with the -CAfile option.  (TODO: then what is the ./certs directory in the distribution?)

### Creating a test certificate

To create simple test certificates with OpenSSL, you may run the following command:

    openssl req -config /usr/local/openssl/openssl.cnf \
        -new -days 365 -newkey rsa:1024 -x509 \
        -keyout notacakey.pem -out notacacert.pem

To remove the pass phrase from the key file, run:

    openssl rsa -in notacakey.pem -out notacakeynopass.pem

### PKCS12 support

The directives for enabling use of PKCS12 certificates is:

    $ENV{HTTPS_PKCS12_FILE}     = 'certs/pkcs12.pkcs12';
    $ENV{HTTPS_PKCS12_PASSWORD} = 'PKCS12_PASSWORD';

Use of this type of certificate takes precedence over previous certificate settings described. (TODO: unclear? Meaning "the presence of this type of certificate"?)

## SSL versions

`Crypt::SSLeay` tries very hard to connect to *any* SSL web server accomodating servers that are buggy, old or simply not standards-compliant.  To this effect, this module will try SSL connections in this order:

*   SSL v23 : should allow v2 and v3 servers to pick their best type

*   SSL v3 :  best connection type

*   SSL v2 :  old connection type

Unfortunately, some servers seem not to handle a reconnect to SSL v3 after a failed connect of SSL v23 is tried, so you may set before using LWP or `Net::SSL`:

    $ENV{HTTPS_VERSION} = 3;

to force a version 3 SSL connection first. At this time, only a version 2 SSL connection will be tried after this, as the connection attempt order remains unchanged by this setting.

## Acknowledgements

many thanks to the following individuals who helped improve Crypt-SSLeay:

* _Gisle Aas_ for writing this module and many others including libwww, for Perl. The web will never be the same :)

* _Ben Laurie_ deserves kudos for his excellent patches for better error handling, SSL information inspection, and random seeding.

* _Dongqiang Bai_ for host name resolution fix when using a proxy.

* _Stuart Horner_ of Core Communications, Inc. who found the need for building `--shared` OpenSSL libraries.

* _Pavel Hlavnicka_ for a patch for freeing memory when using a pkcs12 file, and for inspiring more robust `read()` behavior.

* _James Woodyatt_ is a champ for finding a ridiculous memory leak that has been the bane of many a `Crypt::SSLeay` user.

* _Bryan Hart_ for his patch adding proxy support, and thanks to _Tobias Manthey_ for submitting another approach.

* _Alex Rhomberg_ for Alpha linux ccc patch.

* _Tobias Manthey_ for his patches for client certificate support.

* _Daisuke Kuroda_ for adding PKCS12 certificate support.

* _Gamid Isayev_ for CA cert support and insights into error messaging.

* _Jeff Long_ for working through a tricky CA cert SSLClientVerify issue.

* _Chip Turner_ for a patch to build under perl 5.8.0.

* _Joshua Chamas_ for the time he spent maintaining the module.

* _Jeff Lavallee_ for help with alarms on read failures (CPAN bug #12444).

* _Guenter Knauf_ for significant improvements in configuring things in Win32 and Netware lands and Jan Dubois for various suggestions for improvements.

and _many others_ who provided bug reports, suggestions, fixes and patches.

If you have reported a bug or provided feedback, and you would like to be mentioned by name in this section, please file request on [rt.cpan.org](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-SSLeay).

###	TODO: Update acknowledgements list.

## See Also

*   `Net::SSL`

    If you have downloaded this distribution as of a dependency of
    another distribution, it's probably due to this module (which is
    included in this distribution).

*   `Net::SSLeay`

    [Net::SSLeay](https://metacpan.org/pod/Net::SSLeay) provides access to the OpenSSL API directly from Perl.

*   [OpenSSL binary packages for Windows](http://www.openssl.org/related/binaries.html)

*   [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL)

*   [Building OpenSSL on 64-bit Windows 8.1 Pro using SDK tools](http://blog.nu42.com/2014/04/building-openssl-101g-on-64-bit-windows).

## Support

*   For use of `Crypt::SSLeay` & `Net::SSL` with Perl's LWP, please send email to [libwww@perl.org](mailto:libwww@perl.org).

*   For OpenSSL or general SSL support, including issues associated with building and installing OpenSSL on your system, please email the OpenSSL users mailing list at [openssl-users@openssl.org](mailto:openssl-users@openssl.org). See http://www.openssl.org/support/community.html for other mailing lists and archives.

*   Please report all bugs on [rt.cpan.org](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-SSLeay).

## Authors

This module was originally written by Gisle Aas, and was subsequently maintained by Joshua Chamas, David Landgren, brian d foy, and A. Sinan Unur.

## Copyright

Copyright &copy; 2010-2014 A. Sinan Unur

Copyright &copy; 2006-2007 David Landgren

Copyright &copy; 1999-2003 Joshua Chamas

Copyright &copy; 1998 Gisle Aas

## License

This program is free software; you can redistribute it and/or modify it under the terms of [Artistic License 2.0](http://www.perlfoundation.org/artistic_license_2_0).

