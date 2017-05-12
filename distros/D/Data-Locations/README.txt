                  =========================================
                    Package "Data::Locations" Version 5.5
                  =========================================


This package is available for download either from my web site at

                  http://www.engelschall.com/u/sb/download/

or from any CPAN (= "Comprehensive Perl Archive Network") mirror server:

               http://www.perl.com/CPAN/authors/id/S/ST/STBEY/


What's new in version 5.5:
--------------------------

 +  Minor bugfixes and updates


Legal issues:
-------------

This package with all its parts is

Copyright (c) 1997 - 2009 by Steffen Beyer.
All rights reserved.

This package is free software; you can use, modify and redistribute
it under the same terms as Perl itself, i.e., under the terms of
the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt"
in this distribution, respectively, for details!


Prerequisites:
--------------

Perl version 5.004 or higher, and an ANSI C compiler. (!)
                                     ^^^^^^
Note that in order to compile Perl modules which contain
C (and/or XS) code (such as this one), you always HAVE
to use the very same compiler your Perl itself was compiled
with.

Many vendors nowadays ship their operating system already
comprising a precompiled version of Perl. Many times the
compilers used to compile this version of Perl are not
available to or not usually used by the users of these
operating systems.

In such cases building this module (or any other Perl
module containing C and/or XS code) will not work. You
will either have to get the compiler which was used to
compile Perl itself (see for example the section "Compiler:"
in the output of the command "perl -V"), or to build
your own Perl with the compiler of your choice (which
also allows you to take advantage of the various compile-
time switches Perl offers).

Note that Sun Solaris and Red Hat Linux frequently were
reported to suffer from this kind of problem.

Moreover, you usually cannot build any modules under
Windows 95/98 since the Win 95/98 command shell doesn't
support the "&&" operator. You will need the Windows NT
command shell ("cmd.exe") or the "4DOS" shell to be
installed on your Windows 95/98 system first. Note that
Windows NT, Windows 2000 and Windows XP are not affected
and just work fine. I don't know about Windows Vista and
Windows 7, however.

Note that ActiveState provides precompiled binaries of
this module for their Win32 port of Perl ("ActivePerl")
on their web site, which you should be able to install
simply by typing "ppm install Data-Locations" in your
MS-DOS command shell (but note the "-" instead of "::"
in the package name!).

This also works under Windows 95/98 (!).

If your firewall prevents "ppm" from downloading
this package, you can also download it manually from
http://www.activestate.com/ppmpackages/5.005/zips/ or
http://www.activestate.com/ppmpackages/5.6/zips/.
Follow the installation instructions included in
the "zip" archive.


Note to CPAN Testers:
---------------------

After completion, version 5.5 of this module has already
been tested successfully with the following configurations:

  Perl 5.005_03  -  Windows XP SP3 & MS VC++ 6.0 (native Perl build)
  Perl 5.8.0     -  Windows XP SP3 & MS VC++ 6.0 (native Perl build)
  Perl 5.10.1    -  Windows XP SP3 & MS VC++ 6.0 (native Perl build)
  Perl 5.10.1    -  FreeBSD 7.2-STABLE


Installation:
-------------

Please see the file "INSTALL.txt" in this distribution for instructions
on how to install this package.

It is essential that you read this file since one of the special cases
described in it might apply to you, especially if you are running Perl
under Windows.


Changes over previous versions:
-------------------------------

Please refer to the file "CHANGES.txt" in this distribution for a more
detailed version history log.


Documentation:
--------------

The documentation of this package is included in POD format (= "Plain
Old Documentation") in the file "Locations.pm" in this distribution,
the human-readable markup-language standard for Perl documentation.

By building this package, this documentation will automatically be
converted into a man page, which will automatically be installed in
your Perl tree for further reference through the installation process,
where it can be accessed by the commands "man Data::Locations" (Unix)
and "perldoc Data::Locations" (Unix and Win32 alike), for example.


What does it do:
----------------

Data::Locations - magic insertion points in your data

Did you already encounter the problem that you had to produce some
data in a particular order, but that some piece of the data was still
unavailable at the point in the sequence where it belonged and where
it should have been produced?

Did you also have to resort to cumbersome and tedious measures such
as storing the first and the last part of your data separately, then
producing the missing middle part, and finally putting it all together?

In this simple case, involving only one deferred insertion, you might
still put up with this solution.

But if there is more than one deferred insertion, requiring the handling
of many fragments of data, you will probably get annoyed and frustrated.

You might even have to struggle with limitations of the file system of
your operating system, or handling so many files might considerably slow
down your application due to excessive file input/output.

And if you don't know exactly beforehand how many deferred insertions
there will be (if this depends dynamically on the data being processed),
and/or if the pieces of data you need to insert need additional (nested)
insertions themselves, things will get really tricky, messy and troublesome.

In such a case you might wonder if there wasn't an elegant solution to
this problem.

This is where the "Data::Locations" module comes in: It handles such
insertion points automatically for you, no matter how many and how deeply
nested, purely in memory, requiring no (inherently slower) file input/output
operations.

(The underlying operating system will automatically take care if the amount
of data becomes too large to be handled fully in memory, though, by swapping
out unneeded parts.)

Moreover, it also allows you to insert the same fragment of data into
SEVERAL different places.

This increases space efficiency because the same data is stored in
memory only once, but used multiple times.

Potential infinite recursion loops are detected automatically and
refused.

In order to better understand the underlying concept, think of
"Data::Locations" as virtual files with almost random access:
You can write data to them, you can say "reserve some space here
which I will fill in later", and continue writing data.

And you can of course also read from these virtual files, at any time,
in order to see the data that a given virtual file currently contains.

When you are finished filling in all the different parts of your virtual
file, you can write out its contents in flattened form to a physical, real
file this time, or process it otherwise (purely in memory, if you wish).

You can also think of "Data::Locations" as bubbles and bubbles inside
of other bubbles. You can inflate these bubbles in any arbitrary order
you like through a straw (i.e., the bubble's object reference).

Note that this module handles your data completely transparently, which
means that you can use it equally well for text AND binary data.

You might also be interested in knowing that this module and its concept
have already been heavily used in the automatic code generation of large
software projects.


Credits:
--------

Please refer to the file "CREDITS.txt" in this distribution for a list
of contributors.


Author's note:
--------------

If you have any questions, suggestions or need any assistance, please
let me know!

Please do send feedback, this is essential for improving this module
according to your needs!

I hope you will find this module useful. Enjoy!

Yours,
--
  Steffen Beyer <STBEY@cpan.org> http://www.engelschall.com/u/sb/
  "There is enough for the need of everyone in this world, but not
   for the greed of everyone." - Mohandas Karamchand "Mahatma" Gandhi
