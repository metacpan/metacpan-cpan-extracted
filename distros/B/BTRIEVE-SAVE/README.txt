BTRIEVE::SAVE (Dump file support for Pervasive's BTRIEVE and sql.2000
file formats.)
VERSION=0.35, 10 February 2000

This is a cross-platform module. All of the files except README.txt
are LF-only terminations. You will need a better editor than Notepad
to read them on Win32. README.txt is README with CRLF.

DESCRIPTION:

BTRIEVE::SAVE can read and write Pervasive's dump files. It does not
provide direct access to the Btrieve api. Users will probably want to
have at least the equivalent of Pervasive's butil -save -stat and
-load available to make much use of it, although these are not required.

FILES:

    Changes		- for history lovers
    Makefile.PL		- the "starting point" for traditional reasons
    MANIFEST		- file list
    README		- this file for CPAN
    README.txt		- this file for DOS
    SAVE.pm		- the reason you're reading this

    t			- test directory
    t/test1.t           - basic test of simple read-write.
    A bunch of reference files.
    t/f1ref.rdb         - rdb file                
    t/f1ref.sav         - save equivalent         
    t/f1ref.std         - config file             
    t/f1rdbref.err      - error file in rdb format

    t/f2ref.rdb         - another rdb file                
    t/f2ref.sav		- save equivalent         
    t/f2ref.std		- config file             
    t/f2savref.err	- error file in rdb format

    eg			- example directory
    eg/README           - more details of make_save.pl
    eg/loctitle.dat     - save file
    eg/loctitle.std     - config file
    eg/make_save.pl     - script to add a new index
	                  (used for fancy sorting).


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
small sample input file and creates outputs in various formats. You can
specify an optional PAUSE (0..5 seconds) between pages of output. The
'perl t/test1.pl PAUSE' form works on all OS types. The test will
indicate if any unexpected errors occur (not ok).

Once you have installed, you can check if Perl can find it. Change to
some other directory and execute from the command line:

            perl -e "use BTRIEVE::SAVE"

No response that means everything is OK! If you get an error like
* Can't locate method "use" via package BTRIEVE::SAVE *, then Perl is not
able to find SAVE.pm--double check that the file copied it into the
right place during the install.

NOTES:

Please let us know if you run into any difficulties using BTRIEVE::SAVE --
We'd be happy to try to help. Also, please contact us if you notice any
bugs, or if you would like to suggest an improvement/enhancement. Email
addresses are listed at the bottom of this page. Lane is the most
interested in making this work: he might be your best initial bet.

We have not tested this on Win32 yet, let us know if there are problems
on installation or use.

The module is provided in standard CPAN distribution format. Additional
documentation is created during the installation (html and man formats).

Download the latest version from CPAN at 

	http://www.cpan.org/modules/by-module/BTRIEVE

or at your local CPAN ftp mirror.

The home page is at http://btrieve.sourceforge.net/

AUTHORS:

    Chuck Bearden cbearden@rice.edu
    Bill Birthisel wcbirthisel@alum.mit.edu
    Derek Lane dereklane@pobox.com
    Charles McFadden chuck@vims.edu
    Ed Summers esummers@odu.edu


COPYRIGHT

Copyright (C) 2000, Bearden, Birthisel, Lane, McFadden, and Summers.
All rights reserved. This module is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.
Portions Copyright (C) 1999,2000, Duke University, Lane.
