ControlX10::CM11
VERSION=2.09, 30 January 2000

Hello home automators:

The CM11A is a bi-directional X10 controller that connects to a serial
port and transmits commands via AC power line to X10 devices. This
module translates human-readable commands (eg. 'A2', 'AJ') into the
Interface Communication Protocol accepted by the CM11A. Both the send
(control output) and receive (monitor external events and status)
operations are supported by the module. The module also handles
checksums and retries failed transmissions.

You will need one of the SerialPort modules from CPAN to generate the
actual hardware commands to the port. If you are running Windows 95 or
later, you want the Win32::SerialPort module. The linux equivalent is
the Device::SerialPort module. Device::SerialPort will also run on
other POSIX Operating Systems.

This is a cross-platform module. All of the files except README.txt
are LF-only terminations. You will need a better editor than Notepad
to read them on Win32. README.txt is README with CRLF.

FILES:

    Changes		- for history lovers
    Makefile.PL		- the "starting point" for traditional reasons
    MANIFEST		- file list
    README		- this file for CPAN
    README.txt		- this file for DOS
    CM11.pm		- the reason you're reading this

    t/test1.t		- RUN ME FIRST, basic tests
    eg/eg_cm11.plx	- simple On/Off/Dim_Lamp demo

OPERATION:

The CM11 module supports four basic operations: 
1) A send command which transmits a two-byte message containing dim and
   house information and either an address or a function. Checksum and
   acknowledge handshaking is automatic.
2) A read command will check for an incoming transmission. It will also
   reset the CM11 clock if it detects a "power fail" message (0xa5).
3) A receive_buffer command is issued in response to a "data waiting"
   message (0x5a) from the CM11. The module sends "ready" (0xc3) and
   receives up to 10 bytes. It decodes the bytes as if they are commands
   coming from an external source (such as an RF keypad).
4) When the external command includes dim/bright information, that data
   as received by the receive_buffer command needs to be converted to
   percent by the dim_level_decode command.

INSTALL and TEST:

On linux and Unix, this distribution uses Makefile.PL and the "standard"
install sequence for CPAN modules:
	perl Makefile.PL
	make
	make test
	make install

On Win32, Makefile.PL creates equivalent scripts for the "make-deprived"
and follows a similar sequence.
	perl Makefile.PL
	perl test.pl
	perl install.pl

Both sequences create install files and directories. The test uses a
CM11 emulator and does not open a real serial port. You can specify an
optional PAUSE (0..5 seconds) between pages of output. The
'perl t/test1.t PAUSE' form works on all OS types. The test will indicate
if any unexpected errors occur (not ok). Some error and debug messages
are forced by the test sequence.

The "eg_cm11.plx" demo is a cross-platform version of a demo previously
post and included with MisterHouse. It expects an X10 appliance switch
at address A1. The demo will default to "COM1" on Win32 and "/dev/ttyS0"
on linux.  It also permits specifying 'perl eg_cm11.plx PORT'.

Extended X10 Preset Dim commands are now supported, if you have the
CM11 interface and a compatible (LM14A) module. You can send them
directly, like 'A1&P47' (set unit A1 to Preset level 47, i.e. 75%)

Starting in version 2.07, incoming extended data is also processed.
The first character will be the I<House Code> in the range [A..P].
The next character will be I<Z>, indicating extended data.
The remaining data will be the extended data.

Watch for updates at:

%%%% http://members.aol.com/Bbirthisel/alpha.html
%%%% http://misterhouse.net
or CPAN under authors/id/B/BB/BBIRTH or ControlX10::CM11

CPAN packaging and module documentation by Bill Birthisel.

Copyright (C) 2000, Bruce Winter. All rights reserved. This module is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.
