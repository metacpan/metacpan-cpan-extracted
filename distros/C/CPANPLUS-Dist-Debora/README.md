# CPANPLUS::Dist::Debora

This CPANPLUS plugin creates Debian or RPM packages from Perl distributions.
The created packages can be installed with CPANPLUS, dpkg or rpm.

    $ cpanp
    CPAN Terminal> i Some-Module --format=CPANPLUS::Dist::Debora

    $ cpan2dist --format CPANPLUS::Dist::Debora Some-Module

    $ cd ~/rpmbuild/RPMS/noarch
    $ sudo rpm -i perl-Some-Module-1.0-1.noarch.rpm

    $ cd ~/.cpanplus/5.36.1/build/XXXX
    $ sudo dpkg -i libsome-module-perl_1.0-1cpanplus_all.deb

## DEPENDENCIES

Requires Perl 5.16 and the modules CPANPLUS, CPANPLUS::Dist::Build,
Module::Pluggable, Software::License and Text::Template from CPAN.  IPC::Run
and Term::ReadLine::Gnu are recommended.

On Debian-based systems, the following packages are required:

* perl
* build-essential
* debhelper (version 12 or better)
* fakeroot
* sudo

On RPM-based systems, install the following packages:

* perl
* perl-devel and perl-generators (if available)
* rpm-build
* gcc
* make
* sudo

## INSTALLATION

Run the following commands to install the software:

    perl Makefile.PL
    make
    make test
    make install

Type the following command to see the module usage information:

    perldoc CPANPLUS::Dist::Debora

## LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
