NAME

    Alien::TALib

SYNOPSIS

    Alien::TALib is a perl module that enables the installation of the
    technical analysis library TA-lib from "http://ta-lib.org" on the
    system and easy access by other perl modules in the methodology cited
    by Alien::Base.

    You can use it in the Build.PL file if you're using Module::Build or
    Makefile.PL file if you're using ExtUtils::MakeMaker.

                my $talib = Alien::TALib->new;
    
                my $build = Module::Build->new(
                    ...
                    extra_compiler_flags => $talib->cflags(),
                    extra_linker_flags => $talib->libs(),
                    ...
                );

VERSION

    0.10

WARNING

    This module is not supported on Windows unless running under Cygwin or
    MSYS.

    We are working to fix this soon.

METHODS

    cflags

      This method provides the compiler flags needed to use the library on
      the system.

    libs

      This method provides the linker flags needed to use the library on
      the system.

SEE ALSO

    Alien::Base

    Alien::Build

    PDL::Finance::TA

AUTHORS

    Vikas N Kumar <vikas@cpan.org>

REPOSITORY

    https://github.com/vikasnkumar/Alien-TALib.git

COPYRIGHT

    Copyright (C) 2013-2022. Vikas N Kumar <vikas@cpan.org>. All Rights
    Reserved.

LICENSE

    This is free software. YOu can redistribute it or modify it under the
    terms of Perl itself.

