## CPE

Perl interface to [Common Platform Enumeration](https://cpe.mitre.org/specification)
identifiers, as specified by CPE version 2.3 in NIST IR 7695 and 7696.

```perl
    use CPE;

    # parse CPEs in 'URI' format:
    my $cpe = CPE->new( 'cpe:/o:linux:linux_kernel:6.2.12' );

    # or create the object directly yourself:
    my $cpe2 = CPE->new(
        part    => 'o',
        vendor  => 'linux',
        type    => 'linux_kernel',
        version => '6.2.12',
    );

    # later on you query items individually:
    say $cpe->vendor;  # 'linux'
    say $cpe->product; # 'linux_kernel'
    say $cpe->version; # '6.2.12'
```

#### Installation

    cpanm CPE

or manually:

    perl Makefile.PL
    make test
    make install

Please refer to [this module's complete documentation](https://metacpan.org/pod/CPE)
for extra information.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See [perlartistic](http://dev.perl.org/licenses/).
