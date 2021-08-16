# CPANPLUS::Dist::Debora

This CPANPLUS plugin creates Debian or RPM packages from Perl distributions.
The created packages can be installed with CPANPLUS, dpkg or rpm.

```
$ cpanp
CPAN Terminal> i Some-Module --format=CPANPLUS::Dist::Debora

$ cpan2dist --format CPANPLUS::Dist::Debora Some-Module

$ cd ~/rpmbuild/RPMS/noarch
$ sudo rpm -i perl-Some-Module-1.0-1.noarch.rpm

$ cd ~/.cpanplus/5.34.0/build/XXXX
$ sudo dpkg -i libsome-module-perl_1.0-1cpanplus_all.deb
```

## INSTALLATION

The [Open Build Service](https://build.opensuse.org/package/show/home:voegelas/perl-CPANPLUS-Dist-Debora) provides binary and source packages.

Run the following commands to install the software manually:

```
perl Makefile.PL
make
make test
make install
```

## DEPENDENCIES

Requires Perl 5.16 and the modules CPANPLUS, CPANPLUS::Dist::Build,
Module::Pluggable, Software::License and Text::Template from CPAN.  IPC::Run
and Term::ReadLine::Gnu are recommended.

On Debian-based systems, install the packages "perl", "build-essential",
"debhelper", "fakeroot" and "sudo".  The minimum supported debhelper version is
12.

On RPM-based systems, install the packages "perl", "rpm-build", "gcc", "make",
"sudo" and, if available, "perl-generators".

## SUPPORT AND DOCUMENTATION

Type "perldoc CPANPLUS::Dist::Debora" to see the module usage information.

If you want to hack on the source, install [Dist::Zilla](https://dzil.org/) and
grab the latest version using the command:

```
git clone https://gitlab.com/voegelas/cpanplus-dist-debora.git
```

## LICENSE AND COPYRIGHT

Copyright 2021 Andreas Vögele

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
