                     =====================================
                       Package "Date::Pcalc" Version 6.1
                     =====================================


This package is available for download either from my web site at

                  http://www.engelschall.com/u/sb/download/

or from any CPAN (= "Comprehensive Perl Archive Network") mirror server:

               http://www.perl.com/CPAN/authors/id/S/ST/STBEY/


Abstract:
---------

This package consists of a library written in pure Perl providing all sorts
of date calculations based on the Gregorian calendar (the one used in all
western countries today), thereby complying with all relevant norms and
standards: ISO/R 2015-1971, DIN 1355 and, to some extent, ISO 8601
(where applicable).

The package is designed as an efficient toolbox, not a bulky ready-made
application. It provides extensive documentation and examples of use,
multi-language support and special functions for business needs.

This package also features date objects (in addition to the functional
interface) with overloaded operators, and a set of modules for calculations
which take local holidays into account.

This package is meant as a drop-in replacement for "Date::Calc",
the latter of which is written in C and XS and therefore needs a
C compiler in order to build and install (which this one doesn't).

You will have to rename all references to "Date::Calc[::Object]"
and "Date::Calendar[::Year|::Profiles]" to "Date::Pcalc[::Object]"
and "Date::Pcalendar[::Year|::Profiles]", respectively, though.

Note that the modules "Date::Pcalendar[::Year|::Profiles]" depend
on "Bit::Vector", so if you wish to use these, you will need a C
compiler anyway, since "Bit::Vector" is also written in C and XS.

They are included here anyway for the sake of completeness, for
allowing to test the transcription of this module from C more
intensively (with the original and unmodified test suite from
"Date::Calc") and to facilitate the "upgrade" with "Bit::Vector",
not requiring you to install "Date::Calc" first.


What's new in version 6.1:
--------------------------

 +  United "Date::Calc" and "Date::Pcalc" into a single distribution
 +  Fixed Polish names of months and days of week (RT ticket #14159)


Legal issues:
-------------

This package with all its parts is

Copyright (c) 1995 - 2009 by Steffen Beyer.
All rights reserved.

This package is free software; you can use, modify and redistribute
it under the same terms as Perl itself, i.e., under the terms of
the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt"
in this distribution, respectively, for details!


Prerequisites:
--------------

Perl version 5.000 or higher.

Module "Carp::Clan" version 5.3 or higher.

Optionally, module "Bit::Vector" version 7.1 or newer.

If you plan to use the modules "Date::Pcalendar" or
"Date::Pcalendar::Year" from this package, you will
also need the module "Bit::Vector" version 7.1 or
newer (which needs an ANSI C compiler, however!).

Otherwise you may safely ignore the warning message
"Warning: prerequisite Bit::Vector 7.1 not found at ..."
when running "perl Makefile.PL".

Anyway, you can always install "Bit::Vector" later
at any time if you change your mind.

Note that in order to compile Perl modules which contain
C (and/or XS) code (such as Bit::Vector), you always HAVE
to use the very same compiler your Perl itself was compiled
with.

Many vendors nowadays ship their operating system already
comprising a precompiled version of Perl. Many times the
compilers used to compile this version of Perl are not
available to or not usually used by the users of these
operating systems.

In such cases building Bit::Vector (or any other Perl
module containing C and/or XS code) will not work. You
will either have to get the compiler which was used to
compile Perl itself (see for example the section "Compiler:"
in the output of the command "perl -V"), or to build
your own Perl with the compiler of your choice (which
also allows you to take advantage of the various compile-
time switches Perl offers).

Note that Sun Solaris and Red Hat Linux frequently were
reported to suffer from this kind of problem.

Moreover, you usually cannot build any such modules under
Windows 95/98 since the Win 95/98 command shell doesn't
support the "&&" operator. You will need the Windows NT
command shell ("cmd.exe") or the "4DOS" shell to be
installed on your Windows 95/98 system first. Note that
Windows NT, Windows 2000 and Windows XP are not affected
and just work fine. I don't know about Windows Vista and
Windows 7, however.

Note that ActiveState provides precompiled binaries of
Bit::Vector for their Win32 port of Perl ("ActivePerl")
on their web site, which you should be able to install
simply by typing "ppm install Bit-Vector" in your MS-DOS
command shell (but note the "-" instead of "::" in the
package name!). This also works under Windows 95/98 (!).

If your firewall prevents "ppm" from downloading
this package, you can also download it manually from
http://www.activestate.com/ppmpackages/5.005/zips/ or
http://www.activestate.com/ppmpackages/5.6/zips/.
Follow the installation instructions included in
the "zip" archive.


Note to CPAN Testers:
---------------------

After completion, version 6.1 of this module has already
been tested successfully with the following configurations:

  Perl 5.005_03  -  Windows XP SP3 & MS VC++ 6.0 (native Perl build)
  Perl 5.8.0     -  Windows XP SP3 & MS VC++ 6.0 (native Perl build)
  Perl 5.10.1    -  Windows XP SP3 & MS VC++ 6.0 (native Perl build)
  Perl 5.10.1    -  FreeBSD 7.2-STABLE


Installation:
-------------

    UNIX:                 Win32/Borland C++:      Win32/MS Visual C++:
    =====                 ==================      ====================

    % perl Makefile.PL    % perl Makefile.PL      % perl Makefile.PL
    % make                % dmake                 % nmake
    % make test           % dmake test            % nmake test
    % make install        % dmake install         % nmake install


Changes over previous versions:
-------------------------------

Please refer to the file "CHANGES.txt" in this distribution for a more
detailed version history log.


Documentation:
--------------

The documentation of this package is included in POD format (= "Plain
Old Documentation") in the files with the extension ".pod" in this
distribution, the human-readable markup-language standard for Perl
documentation.

By building this package, this documentation will automatically be
converted into man pages, which will automatically be installed in
your Perl tree for further reference through the installation process,
where they can be accessed by the commands "man Date::Pcalc" (Unix)
and "perldoc Date::Pcalc" (Unix and Win32 alike), for example.

Available man pages:

    Carp::Clan(3)
    Date::Pcalc(3)
    Date::Pcalc::Object(3)
    Date::Pcalendar(3)
    Date::Pcalendar::Profiles(3)
    Date::Pcalendar::Year(3)

If Perl is not available on your system, you can also read the ".pod"
files

    ./Pcalc.pod
    ./Pcalendar.pod
    ./lib/Carp/Clan.pod
    ./lib/Date/Pcalc/Object.pod
    ./lib/Date/Pcalendar/Profiles.pod
    ./lib/Date/Pcalendar/Year.pod

directly.


What does it do:
----------------

This package performs date calculations based on the Gregorian calendar
(the one used in all western countries today), thereby complying with
all relevant norms and standards: ISO/R 2015-1971, DIN 1355 and, to
some extent, ISO 8601 (where applicable).

See also http://www.engelschall.com/u/sb/download/Date-Calc/DIN1355/
for a scan of part of the "DIN 1355" document (in German).

The module of course handles year numbers of 2000 and above correctly
("Year 2000" or "Y2K" compliance) -- actually all year numbers from 1
to the largest positive integer representable on your system (which
is at least 32767) can be dealt with.

Note that this package projects the Gregorian calendar back until the
year 1 A.D. -- even though the Gregorian calendar was only adopted
in 1582, mostly by the Catholic European countries, in obedience to
the corresponding decree of Pope Gregory XIII in that year.

Some (mainly protestant) countries continued to use the Julian calendar
(used until then) until as late as the beginning of the 20th century.

Therefore, do *NEVER* write something like "99" when you really mean
"1999" - or you may get wrong results!

Finally, note that this package is not intended to do everything you could
ever imagine automagically :-) for you; it is rather intended to serve as a
toolbox (in the best of UNIX spirit and tradition) which should, however,
always get you where you need and want to go.

See the section "RECIPES" at the end of the manual pages for solutions
to common problems!

If nevertheless you can't figure out how to solve a particular problem,
please let me know! (See e-mail address at the bottom of this file.)

The new module "Date::Pcalc::Object" adds date objects to the (functional)
"Date::Pcalc" module (just "use Date::Pcalc::Object qw(...);" INSTEAD of
"use Date::Pcalc qw(...);"), plus built-in operators like +,+=,++,-,-=,--,
<=>,<,<=,>,>=,==,!=,cmp,lt,le,gt,ge,eq,ne,abs(),"" and true/false
testing, as well as a number of other useful methods.

The new modules "Date::Pcalendar::Year" and "Date::Pcalendar" allow you
to create calendar objects (for a single year or arbitrary (dynamic)
ranges of years, respectively) for different countries/states/locations/
companies/individuals which know about all local holidays, and which allow
you to perform calculations based on work days (rather than just days),
like calculating the difference between two dates in terms of work days,
or adding/subtracting a number of work days to/from a date to yield a
new date. The dates in the calendar are also tagged with their names,
so that you can find out the name of a given day, or search for the
date of a given holiday.


Example applications:
---------------------

Please refer to the file "EXAMPLES.txt" in this distribution for details
about the example applications in the "examples" subdirectory.


Tools:
------

Please refer to the file "TOOLS.txt" in this distribution for details
about the various tools to be found in the "tools" subdirectory.


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
