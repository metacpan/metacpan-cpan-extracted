# CPU::x86_64::InstructionWriter

This module is an assembler for x86-64 instructions, but using a Perl API
instead of parsing assembly language, and implemented entirely in perl
rather than shelling out to gcc or nasm (which can be very slow).

It isn't finished, but is usable for some basic cases.

# INSTALLATION

You can install the latest release from CPAN:

    cpanm CPU::x86_64::InstructionWriter

or if you have a release tarball,

    cpanm CPU-x86_64-InstructionWriter-005.tar.gz

or manually build it with

    tar -xf CPU-x86_64-InstructionWriter-005.tar.gz
    cd CPU-x86_64-InstructionWriter-005
    perl Makefile.PL
    make
    make test
    make install

# DEVELOPMENT

Download or checkout the source code, then:

    dzil --authordeps | cpanm
    dzil test

To build and install a trial version, use

    V=0.005_01 dzil build
    cpanm CPU-x86_64-InstructionWriter-005_01.tar.gz
