#!/usr/bin/perl -sw
#
# @(#)$Id: Makefile.PL,v 2018.4 2018/05/11 21:24:01 jleffler Exp $
#
# Configuration script for DBD::Informix
# (Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28))
#
# Copyright 1996-99 Jonathan Leffler
# Copyright 1996    Alligator Descartes
# Copyright 2000    Informix Software Inc
# Copyright 2002-04 IBM
# Copyright 2004-18 Jonathan Leffler
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

#TABSTOP=4

use 5.008_001;
use strict;
use warnings;
use lib 'lib';
use DBD::Informix::Configure;

########################
### AUTOINSTALL CODE ###
########################

use lib 'inc';
use ExtUtils::AutoInstall (
    -version        => '0.63',
    -config         => {
        make_args   => '--hello',   # Suppress hello message from CPAN
    },
    -core           => [
        'DBI'       => "$DBD::Informix::Configure::DBI_MINVERSION",
    ],
    'High Resolution Timing' => [
        -default      => 1,         # Install Time::HiRes by default
        -tests        => [ "t/t66insert.t" ],   # Disable this test if no Time::HiRes
        'Time::HiRes' => '',
    ],
    'POD Format Testing' => [
        -default      => 1,         # Install Test::Pod by default
        -tests        => [ "t/t98pod.t" ],  # Disable this test if no Test::Pod
        'Test::Pod' => '',
    ],
);

# postamble handler; generates a string to be appended to Makefile.
# DBI::DBD::dbd_postamble() returns standardised code to generate
# Informix.xs from Informix.xsi and the template from DBI (Driver.xst).
# dbd_informix_postamble() does a similar job for ESQL/C.
# &'s are necessary on DBI::DBD::dbd_postamble and dbd_informix_postamble.
sub MY::postamble
{
    return &ExtUtils::AutoInstall::postamble .
           &DBI::DBD::dbd_postamble .
           &dbd_informix_postamble;
}

###############################
### END OF AUTOINSTALL CODE ###
###############################

# A sufficiently recent version of Perl and DBI must be installed before
# we can build the DBD module.  The code in DBI, and hence the code in
# DBD::Informix, needs the features present in Perl 5.8.1.
use Config;
use DBI::DBD;               # dbd_postamble()
use POSIX qw(strftime);
sub dbd_ix_die;

my $min_DBI_ver  = $DBD::Informix::Configure::DBI_MINVERSION;    # Minimum (mandatory) version of DBI
my $ref_DBI_ver  = $DBD::Informix::Configure::DBI_REFVERSION;    # Reference (recommended) version of DBI
my $min_Perl_ver = $DBD::Informix::Configure::PERL_MINVERSION;   # Minimum (mandatory) version of Perl
my $ref_Perl_ver = $DBD::Informix::Configure::PERL_REFVERSION;   # Reference (recommended) version of Perl

$| = 1;     # Ensure that Perl output is interleaved with test output.

# Configure for Unix vs Windows 95/NT
my $objext = $Config{obj_ext};
my $split = $Config{path_sep};
my $NTConfiguration = $Config{archname} =~ /MSWin32/;

if ($NTConfiguration)
{
    # NT configuration...
    dbd_ix_die nlws(q{
    In early 2001, there was experimental support for Windows NT.
    It has not been proved, and there was never support officially
    for XP, let alone ME, Vista, Windows 7, Windows 8, Windows 10.
    Contact the maintainers if you want help re-porting to NT.
    DBD::Informix 2015.1101 has remnants of Windows NT support in it.
    That might help you.

    Sorry!

    });
}

my $dbd_ix = "2018.1029";

# This is for development only - the code must be recompiled each day!
$dbd_ix = strftime("%Y.%m%d", localtime time) if $dbd_ix =~ m/^[:]VERSION[:]$/;

my $dbd_ix_pm_dir = "lib/DBD/Informix";

my %opts = (
    NAME         => 'DBD::Informix',
    VERSION      => "$dbd_ix",
    EXE_FILES    => [ 'InformixTechSupport' ],
    clean        => { FILES        => "Informix.xsi esqlinfo.h t/decgen.sql t/dtgen.sql $dbd_ix_pm_dir/Defaults.pm" },
    realclean    => { FILES        => 'esql' },
    dist         => { DIST_DEFAULT => 'clean distcheck disttest tardist',
                      PREOP        => '$(MAKE) -f Makefile.old distdir',
                      COMPRESS     => 'gzip -v9',
                      SUFFIX       => 'gz'
                    },
    'PREREQ_PM'  => { 'DBI' => "$min_DBI_ver",
                      'Time::HiRes' => 0
                    },
    'PM'         => {
                      'Informix.pm'                   => '$(INST_LIBDIR)/Informix.pm',
                      "$dbd_ix_pm_dir/Configure.pm"   => '$(INST_LIBDIR)/Informix/Configure.pm',
                      "$dbd_ix_pm_dir/Defaults.pm"    => '$(INST_LIBDIR)/Informix/Defaults.pm',
                      "$dbd_ix_pm_dir/GetInfo.pm"     => '$(INST_LIBDIR)/Informix/GetInfo.pm',
                      "$dbd_ix_pm_dir/Metadata.pm"    => '$(INST_LIBDIR)/Informix/Metadata.pm',
                      "$dbd_ix_pm_dir/Summary.pm"     => '$(INST_LIBDIR)/Informix/Summary.pm',
                      "$dbd_ix_pm_dir/TechSupport.pm" => '$(INST_LIBDIR)/Informix/TechSupport.pm',
                      "$dbd_ix_pm_dir/TestHarness.pm" => '$(INST_LIBDIR)/Informix/TestHarness.pm',
                      "$dbd_ix_pm_dir/TypeInfo.pm"    => '$(INST_LIBDIR)/Informix/TypeInfo.pm',
                      "lib/Bundle/DBD/Informix.pm"    => 'blib/lib/Bundle/DBD/Informix.pm',
                    },
    # These are necessary for AIX - ifx_checkAPI must be exported,
    # and DL_FUNCS ensures boot_DBD__Informix is available.
    'DL_FUNCS'   => { 'DBD::Informix' => [] },
    'FUNCLIST'   => [qw(ifx_checkAPI)],
           );

print qq%
Configuring Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28) (aka $opts{NAME})
        You are using DBI version $DBI::VERSION and Perl version $]
Remember to actually read the README file!

%;

# See http://perldoc.perl.org/perlvar.html#%24EXECUTABLE_NAME
my $Perl = $Config{perlpath};
if ($^O ne 'VMS')
{
    $Perl .= $Config{_exe} unless $Perl =~ m/$Config{_exe}$/i;
}

# log key platform information to help me help you quickly
print "Perl:     $^X v$] @Config{qw(archname dlsrc)}\n";
print "System:   @Config{qw(myuname)}\n";

# Sometimes the 'use' commands above enforce the same restriction as
# these two lines below.
did_not_read("Perl is out of date") unless ($] >= $min_Perl_ver);
did_not_read("DBI is out of date") unless ($DBI::VERSION >= $min_DBI_ver);

# Compare installed version of DBI with version which DBD::Informix was
# last tested with.
# The required and reference versions are the same for this release.
warn "*** Ideally, you should upgrade to Perl version $ref_Perl_ver or later.\n\n"
    unless ($] >= $ref_Perl_ver);
warn "*** Ideally, you should upgrade to DBI version $ref_DBI_ver or later.\n\n"
    unless ($DBI::VERSION >= $ref_DBI_ver);

my ($ID, $esqlprog) = find_informixdir_and_esql(0);
my ($epp) = "$ID/bin/$esqlprog";

my ($infversion, $vernum) = get_esqlc_version($esqlprog);
print "Using $infversion from $ID\n";

# Check for 32-bit vs 64-bit mismatches
# Unix versions of ESQL/C use .UCx (and .HCx on old HP-UX) to indicate a
# 32-bit client, and .FCx to indicate a 64-bit client.  On Windows, .TCx
# has indicated 32-bit clients.
die "Unexpected ESQL/C version number format $infversion"
    unless $infversion =~ m/\d+\.\d+\.([A-Z])[A-Z].*$/;
my ($verletter) = $1;
my ($esql_bits) = 0;
$esql_bits = 32 if ($verletter eq 'U');
$esql_bits = 32 if ($verletter eq 'H');
$esql_bits = 64 if ($verletter eq 'F');
$esql_bits = 32 if ($verletter eq 'T');
die "Unrecognized ESQL/C 'bittiness' letter $verletter"
    unless $esql_bits != 0;
my ($perl_bits) = 8 * $Config{ptrsize};
die "Unexpected number of bits for Perl longsize ($perl_bits)"
    unless $perl_bits == 32 || $perl_bits == 64;
die "Your build will fail because Perl is a $perl_bits-bit version but ESQL/C is a $esql_bits-bit version\n"
    unless $perl_bits == $esql_bits;

# Effective version number of ESQL/C.
# ESQL/C 2.90 was released in ClientSDK 2.90 (Nov 2004)
# Previous version was ESQL/C 9.53 released in ClientSDK 2.81.
# ESQL/C 2.91 was at least an internal version number.
# CSDK 3.00 was released with IDS 11.10 - so adjust conditional to 400.
# Versions of ESQL/C prior to 3.00 (IDS 11.10) are not supported.
# To simplify swathes of code below, treat the 2.90..2.99 as equivalent
# to 9.60 (a non-existent release) and 3.00..3.49 releases as equivalent
# to 9.70 (also a non-existent release), and 3.50..3.99 releases as
# equivalent to 9.75 (yet another non-existent release).  Rinse and repeat.
# CSDK 3.50 was released with IDS 11.50.
# CSDK 3.70 was released with IDS 11.70.
# CSDK 4.10 was released with IDS 12.10.
# This will be extended as necessary.
my ($effvernum) = $vernum;
$effvernum = 960 if ($vernum >= 290 && $vernum < 300);
$effvernum = 970 if ($vernum >= 300 && $vernum < 350);
$effvernum = 975 if ($vernum >= 350 && $vernum < 400);
$effvernum = 980 if ($vernum >= 400 && $vernum < 500);

dbd_ix_die "\n*** ESQL/C version $vernum is no longer supported (by IBM, HCL or DBD::Informix).\n\n"
    if ($effvernum < 960);

dbd_ix_die "\n*** Environment variable \$INFORMIXSERVER is not set and should be!\n\n"
    if (!defined $ENV{INFORMIXSERVER});

# --- Check whether Informix is installed OK for us.
my $INC1 = "-I$ID/incl/esql";

my $esql = "$esqlprog";
my $esqlc_flags = "";
my $vercode = "esqlc_v6";
my $multiconn = 1;

if ($effvernum < 100)
{
    dbd_ix_die nlws(qq{
    The ESQL/C version information found was: <<$infversion>>
    $opts{NAME} failed to find a version number ($effvernum).
    Please report this to the $opts{NAME} maintenance team.
    });
}
elsif ($effvernum < 970)
{
    # ESQL/C 2.00 was released circa 1986
    # ESQL/C 2.10 was released circa 1987
    # ESQL/C 4.00 was released circa 1988
    # ESQL/C 4.10 was released circa 1989 (and then a 'new' version 4.10 was released circa 2013)
    # ESQL/C 5.10 was released about 1999 for Y2K compliance
    # ESQL/C 5.11 may have existed; it would have been released circa 2000.
    # ESQL/C 5.20 was released circa 2002 and is still (2013) available for use with OnLine 5.20.
    # ESQL/C 6.00 was released in 1995
    # ESQL/C 7.00 was released in 1996
    # ESQL/C 7.1x was released in 1996-7.
    # ESQL/C 7.2x was released in 1997-9.  ESQL/C 7.24 was Y2K compiant.
    # ESQL/C 8.xx was for Informix XPS (versions 8.00 through 8.3x).
    # ESQL/C 9.0x and 9.10 or 9.11 were pre-releases of the ESQL/C for
    # the Informix Universal Server (IUS) - since renamed several times.
    # ESQL/C 9.12 was released as ESQL/C 9.12.
    # ESQL/C 9.13 was released in DevSDK 2.00
    # ESQL/C 9.14 was released in ClientSDK 2.01
    # ESQL/C 9.15 was released in ClientSDK 2.02
    # ESQL/C 9.16 was released in ClientSDK 2.10
    # ESQL/C 9.20 was released in ClientSDK 2.20
    # ESQL/C 9.21 was released in ClientSDK 2.30
    # ESQL/C 9.30 was released in ClientSDK 2.40
    # ESQL/C 9.40 was released in ClientSDK 2.50
    # ESQL/C 9.50 was released in ClientSDK 2.60
    # ESQL/C 9.51 was released in ClientSDK 2.70
    # ESQL/C 9.52 was released in ClientSDK 2.80
    # ESQL/C 9.53 was released in ClientSDK 2.81
    # ESQL/C 2.90 was released in ClientSDK 2.90 (IDS 10.00) (Nov 2004)
    # The ESQL/C versions above are long obsolete and no longer supported.
    dbd_ix_die nlws(qq%
        $infversion is no longer supported by $opts{NAME}
    %);
}
elsif ($effvernum >= 970 && $effvernum < 1000)
{
    # ESQL/C 3.00 was released in ClientSDK 3.00 (IDS 11.10)
    # ESQL/C 3.50 was released in ClientSDK 3.50 (IDS 11.50)
    # ESQL/C 3.70 was released in ClientSDK 3.70 (IDS 11.70)
    # ESQL/C 4.10 was released in ClientSDK 4.10 (IDS 12.10) (Mar 2013)
    # It's a bit of a misnomer to say 'new IUS types' since they are 20 years old!
    print nlws(qq%
        Beware: $opts{NAME} is not yet fully aware of all the Informix data types.

    %);

    $esqlc_flags .= set_esqlc_linkage("-shared");

    # Shadows outer $esql
    my $esql = (defined $ENV{ESQL}) ? $ENV{ESQL} : "esql";
    if ($esql =~ m%(.*/)?c4gl$%)
    {
        dbd_ix_die nlws(qq%
            $opts{NAME} no longer supports linking with Informix 4GL.
        %);
    }
}
else
{
    dbd_ix_die nlws(qq{
    $opts{NAME} does not know anything about $infversion.
    Please report this to the $opts{NAME} maintenance team.
    However, there is a fair chance that $opts{NAME} will work if
    you modify the code in Makefile.PL which contains this message
    to recognize your version.

    Please report your experiences to the $opts{NAME} maintenance team.
    });
}

# -- Configure the make process

# Define the version of ESQL/C for the object code.
# Do not use $effvernum here (tempting though it is)!
$opts{DEFINE} = " -DESQLC_VERSION=$vernum";

# Disable assertions by default; override by setting DBD_INFORMIX_ENABLE_ASSERT.
if (defined($ENV{DBD_INFORMIX_ENABLE_ASSERT}))
{
    $opts{DEFINE} .= " -DDBD_INFORMIX_ENABLE_ASSERT";
    print "** Warning ** assert macro is enabled!\n\n";
}
else
{
    print "Assert macro will be disabled!\n\n";
    $opts{DEFINE} .= " -DNDEBUG";
}

print "** Warning ** you will build $opts{NAME} for a relocatable INFORMIXDIR!\n\n"
    if (defined($ENV{DBD_INFORMIX_RELOCATABLE_INFORMIXDIR}));

$opts{INC} = " ";

Write_DBD_Informix_Defaults($ID);

# Grumble: ifx_loc_t was added to CSDK (ESQL/C) 3.00/xC3 and was not in
# 3.00.xC2.  Hence this test is more complex than I'd like.
sub check_for_ifx_loc_t
{
    my($ifx_loc_t);
    if ($effvernum >= 975)
    {
        $ifx_loc_t = "define";
    }
    elsif ($effvernum < 970)
    {
        $ifx_loc_t = "undef";
    }
    else
    {
        my $hdr = "$ID/incl/esql/locator.h";
        die "Unable to open $hdr for reading\n"
            unless open my $fh, "<$hdr";
        local $/;
        my $text =  <$fh>;
        close $fh;
        $ifx_loc_t = ($text =~ m/ifx_loc_t/m) ? "define" : "undef";
    }
    return($ifx_loc_t);
}

# The ESQL/C preprocessors do not handle conditional compilation
# of #ifdef blocks, so such code has to be handled with $include
# and $ifdef and so on.  Ugh!!!  Necessary for IUS support.
{
my $infofile = "esqlinfo.h";
unlink $infofile;
die "Unable to open $infofile for writing\n"
    unless open my $ESQLINFO, ">$infofile";
print $ESQLINFO "/*\n** File $infofile\n** Generated by $opts{NAME} $dbd_ix\n** For $infversion\n*/\n";
printf $ESQLINFO "%sdefine ESQLC_VERSION_STRING \"%s\";\n", '$', $infversion;
printf $ESQLINFO "%s%s ESQLC_BIGINT;\n", '$',
    ($effvernum >= 975 ? "define" : "undef");
my($ifx_loc_t) = check_for_ifx_loc_t();
printf $ESQLINFO "%s%s ESQLC_IFX_LOC_T;\n", '$', $ifx_loc_t;
$opts{DEFINE} .= " -DESQLC_IFX_LOC_T" if ($ifx_loc_t eq "define");
close $ESQLINFO or die "Failed to write $infofile\n";
print "$infofile written OK\n\n";
}

# Add extra definitions to compile the code under GCC if DBD_INFORMIX_DEBUG_GCC set.
# Perl configuration headers contain lots of /* inside comments (-Wno-comment)
#$opts{DEFINE} .= ' -Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align'
#       . ' -Wconversion -Wtraditional -Wcast-qual'
#       . ' -Wmissing-prototypes -Wstrict-prototypes -Wredundant-decl'
# Neither Perl (DBI) nor DBD-Informix is really ready for -Wextra.
$opts{DEFINE} .= ' -Wall -pedantic -Wextra -Wno-comment'
    if $Config{cc} eq 'gcc' and $ENV{DBD_INFORMIX_DEBUG_GCC};

# Workaround Informix bug B08223 (aka B14937, and other numbers too)
# AIX localedef31.h defines a loc_t and is used by some system headers.
# Informix locator.h also defines a loc_t.  The workaround is to prevent
# the localedef31.h declaration from being included.
if ($Config{osname} eq 'aix' && !defined $ENV{DBD_INFORMIX_AIX_NO_LOCALEDEF})
{
    $opts{DEFINE} .= " -D__H_LOCALEDEF";
    print nlws('
        Classically, on AIX (only) it has been necessary to define
        -D__H_LOCALEDEF on the command line to avoid the problem with
        loc_t being defined in both ESQL/C header locator.h and the AIX
        system header localedef31.h.  Some newer versions of CSDK may
        require this define to be absent.  The configuration has just
        added the define, so if you get compilation errors related to
        loc_t, reconfigure with $DBD_INFORMIX_AIX_NO_LOCALEDEF set to 1
        in your environment.  This should suppress the -D__H_LOCALEDEF
        and allow things to work OK.  If you use this, and especially
        if neither mechanism works, please let the maintenance team
        know all the details, especially the version of CSDK.
    ');
}

my $objects = "Informix.o dbdimp.o dbdattr.o sqltoken.o";
$objects .= " sqltype.o ixblob.o odbctype.o kludge.o link.o esqlcver.o $vercode.o";
$objects .= " eprintf.o" if defined $ENV{DBD_INFORMIX_USE_EPRINTF_CODE};
if (defined $ENV{DBD_INFORMIX_AUXILLIARY_OBJECT_FILES})
{
    my ($list) = $ENV{DBD_INFORMIX_AUXILLIARY_OBJECT_FILES};
    $objects .= " $list";
    print 'Using auxilliary object files from $DBD_INFORMIX_AUXILLIARY_OBJECT_FILES:';
    $list =~ s/^\s+//;
    $list =~ s/\s+$//gm;
    $list =~ s/\s+/\t\n/gm;
    print "\n\t$list\n\n";
}
# Map object file names on non-Unix platforms
$objects =~ s/\.o\w/$objext/g if ($objext ne ".o");

# Need to pick up the DBI headers.  The DBI headers might be in
# $INSTALLARCHLIB rather than $INSTALLSITEARCH.  This is the case under
# Debian, according to Roderick Schertler <roderick@argon.org>, 1999-09.
# May also, or instead, need -I\$(SITEARCHEXP)/auto/DBI; this was
# reported by Joachim Schrod <jschrod@acm.org> in January 1998 on AIX.
# And on 2002-07-03, Roderick Schertler also reported that we may need
# INSTALLVENDORARCH sometimes (Debian again), and gave the join/map
# formulation without listing SITEARCHEXP.  On my Solaris 7 box with my
# build of Perl 5.8.0, INSTALLVENDORARCH is empty, and SITEARCHEXP is
# the same as INSTALLSITEARCH, but that doesn't do any harm.
#
# ??Should we use $Config{installarchlib} etc, and check for what exists?
# ??Can we sensibly check for uniqueness of directory names?
my $INC2 = join ' ', map { "-I\$($_)/auto/DBI" }
            qw (INSTALLARCHLIB INSTALLSITEARCH INSTALLVENDORARCH SITEARCHEXP);

# Can we find the auto/DBI directory anywhere in @INC?
my $INC3 = join ' ', map { -d "$_/auto/DBI" && "-I$_/auto/DBI" || "" } @INC;

$opts{INC} .= " $INC1 $INC2 $INC3";
$opts{OBJECT} = $objects;

##############################
# - Start of ESQLTEST code - #
##############################

my $unsuccessful_test = qq%
The test program esqltest compiled successfully (which is good).
However, it did not run successfully (which is bad).

If the esqltest program did not produce any output:
    This suggests that there is a problem with the ESQL/C runtime
    environment, or with the database permissions (in which case, you
    should have seen diagnostics from the esqltest program itself).
    Consider whether the shared library path environment variable (eg
    LD_LIBRARY_PATH or SHLIB_PATH) is set correctly.

If the esqltest program did produce some output:
    This suggests that you do not have enough permissions in your
    Informix environment.  You really need DBA (at least RESOURCE)
    level privileges on the database you are using.

If you might be having problems with ESQL/C, try to compile and run
the simple ESQL/C program esqlbasic.ec, which has no Perl related
code in it at all -- it is a pure ESQL/C program:

        esql -o esqlbasic esqlbasic.ec && esqlbasic

If you cannot get that to work, then the problem is with ESQL/C
and not with $opts{NAME} per se, and you need to get your ESQL/C
installation fixed so that you can compile and run the esqlbasic
program successfully.

Make sure you read the whole README file before asking the DBI/DBD
community for help!
%;

# Remove leading and trailing white space
# Michael Lieman <michael.lieman@bankofamerica.com>
# Günther Seifert <guenther-h.seifert@t-systems.com>
sub trim
{
    my($str) = @_;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return($str);
}

if ($ENV{DBD_INFORMIX_NO_ESQLTEST})
{
    print nlws(qq%
        Because DBD_INFORMIX_NO_ESQLTEST is set in your environment, you
        have chosen not to run the test which verifies that your ESQL/C
        setup will allow DBD::Informix to compile and the tests to run.  If
        you run into *ANY* problems, you must verify that the esqltest
        program can be compiled and run successfully before you even think
        of asking for help.  Also make sure you read the whole README
        file before asking the DBI/DBD community for help!\n
        %);
}
else
{
    # Check that the ESQL/C program esqltest can be compiled and run OK.
    # NB: test does not need any Perl headers (but don't pollute esqlperl.h
    #     with anything that needs a Perl header).
    # Remove this code if you run into irresolvable problems with shared
    # memory connections after you've read the README.olipcshm file.
    # On Unix, it is conceivable that someone who uses C Shell (or equivalent)
    # will run into problems because of the environment setting on the command
    # line.  Possible cure: ensure that $SHELL=/bin/ksh or /bin/sh.
    # There have also been problems on HP-UX 10.20 with environment setting
    # on the command line which may affect this test and/or the main build.
    print "Testing whether your Informix test environment will work...\n";
    my $EX = "";
    my $RM = "rm -f";
    my $EQ = "$esql";

    $opts{DEFINE} =~ s/^\s+//;
    my $sx = $ENV{DBD_INFORMIX_DEBUG_ESQLTEST} ? 1 : 0;
    my @ccflags = split / +/, trim($Config{ccflags});
    my @cppflags = split / +/, trim($opts{DEFINE});
    my @ldflags = split / +/, trim($Config{ldflags});
    if ($sx)
    {
        my($v);
        print "C and C preprocessor flags - used in object compilations\n";
        foreach $v (@ccflags)  { print "ccflag  = <<$v>>\n"; }
        foreach $v (@cppflags) { print "cppflag = <<$v>>\n"; }
    }

    execute_command($sx, "Failed to compile esqltest.ec to esqltest$objext\n",
                    [ "$EQ", "-c", @ccflags, @cppflags, "esqltest.ec" ]);
    execute_command($sx, "Failed to compile $vercode.ec to $vercode$objext\n",
                    [ "$EQ", "-c", @ccflags, @cppflags, "$vercode.ec" ]);
    execute_command($sx, "Failed to link test program esqltest\n",
                    [ "$EQ", "-o", "esqltest", @ldflags, "esqltest$objext", "$vercode$objext" ]);
    execute_command($sx, "Failed to remove compilation debris\n",
                    [ "$RM esqltest$objext esqltest.c $vercode.c $vercode$objext" ])
        unless ($sx);
    execute_command($sx, $unsuccessful_test, [ "./esqltest" ]);
    execute_command($sx, "Failed to remove esqltest$EX program\n",
                    [ "$RM esqltest$EX" ])
        unless ($sx);
}

##############################
# -- End of ESQLTEST code -- #
##############################

###########################################################################
# In theory, the best way to get the library linked reliably is to use the script that
# comes with ESQL/C.  It knows which libraries are needed, etc.  The lists
# could change from release to release.  It is better not try second-guessing it;
# it will fail, and sooner rather than later.
#
# However, Perl also knows how to link libraries reliably, and it may have
# different views on how to do it.  This has given rise to extraordinary
# contortions in this script.  However, life is simpler in 2018 than it
# was in 1996; there are fewer Unix variants around and they are easier
# to manage.  Also, all 21st Century versions of ESQL/C support -libs, so
# we're going to use it everywhere, rather than as a fallback.

print "Determining which Informix libraries etc to use...\n";

my $esqlscript = (-f $esql) ? $esql : "$ID/bin/esql";
# Note the double backslash to get \s to the subordinate Perl.
my $libs = `$Perl -pe 's/^\\s*exec/echo/' $esqlscript | sh -s -- -o pseudonym $esqlc_flags dbd::ix.o`
    || die "Couldn't execute $esqlscript to determine the ESQL/C libraries\n";
$libs =~ s/\n/ /gm;
$libs =~ s/^.* dbd::ix.o / /;
# Remove -L directives for Informix libraries (we add them anyway later).
$libs =~ s%\s+-L\s*$ID/lib\s+% %;
$libs =~ s%\s+-L\s*$ID/lib/esql\s+% %;
$libs =~ s%-o\s+pseudonym\s+% %;
if ($ENV{DBD_INFORMIX_RELOCATABLE_INFORMIXDIR})
{
    # Specify that SHLIB_PATH is OK at runtime
    $libs = "+s $libs" if ($Config{osname} eq "hpux");
}
else
{
    my(@libs) = split ' ', $libs;
    my(@names) = map_informix_lib_names(@libs);
    $libs = join ' ', @names;
}

print "... We are going to use the Informix library list:\n";
split_print($libs, 70, '*  ');
print "\n";

# Override default version of $opts{LD}
$opts{dynamic_lib} =
    { OTHERLDFLAGS => "-L$ID/lib -L$ID/lib/esql $libs"};
$opts{LD} = "$Config{ld}";

print "\n";

# On Solaris, setting -R flags allows DBD::Informix to be used in
# CGI scripts or cron tasks more easily.
${$opts{dynamic_lib}}{OTHERLDFLAGS} .= " -R$ID/lib -R$ID/lib/esql"
    if ($Config{osname} eq 'solaris');

# On Solaris, the GCC-specific flags -z ignore, -z combreloc or -z lazyload
# can cause trouble - raise a warning.
my($lazy) = qr/\b-z\s*(ignore|lazyload|combreloc)\b/;
warn nlws(qq%WARNING: The flags -z ignore (in particular), -z combreloc and -z lazyload
have caused problems on some platforms - notably Solaris - and are set by your Perl.
Look at Notes/environment.variables for more information.\n\n%)
    if ($Config{cccdlflags} =~ m/$lazy/ ||
        $Config{lddlflags} =~ m/$lazy/ ||
        $Config{ccflags}   =~ m/$lazy/);

# Probably cause for being thrown out of The Perl Institute, but TMTOWTDI!
system "$Perl t/dtgen.pl > t/dtgen.sql";
system "$Perl t/decgen.pl > t/decgen.sql";

# Manually maintained META.yml
$opts{NO_META} = 1;

WriteMakefile(%opts);

# Cleanly exit from the Makefile-build process

exit 0;

#-------------------------------------------------------------------------
# Subroutines used in code above.
#-------------------------------------------------------------------------

sub dbd_ix_die
{
    exit 0 if $ENV{AUTOMATED_TESTING};  # So CPAN testers do not complain
    my($msg) = @_;
    warn $msg;
    my($line) = "+" . "-" x 72 . "+";
    print "\n$line\n";
    system "$Perl -V";    # Generate 'perl -V' output; it is forgotten too often.
    print "$line\n\n";
    print "Farewell!\n";
    exit 1;
}

# Tell the user that they did not read the README file and why
# we think they didn't read it.
sub did_not_read
{
    dbd_ix_die "\n*** You didn't read the README file!\n@_\n\n";
}

# Define a postamble function for the makefile which briefs MAKE on how to
# compile ESQL/C source code.  It gives .ec rules (and files) precedence
# over .c files with the same name by zapping and reorganizing the entire
# suffix list.  The .SUFFIXES list was copied from the MakeMaker constants
# section (circa 1998).  It contains all the extensions that DBD::Informix
# needs (and a few C++ strays) but isn't complete by 2002 standards.  It's
# a pity that changing this list cannot be handled more cleanly.
# Beware: some of this is Makefile where leading tabs are really needed.

sub dbd_informix_postamble
{
    my ($p1, $p2, $p3, $p4);

    $p1 =
        "
        # ESQL/C compilation rules
        ESQL       = $esql
        ESQLCFLAGS = $esqlc_flags
        .SUFFIXES:
        .SUFFIXES: .ec .xs .c .C .cpp .cxx .cc $objext .sh

        .ec$objext:";

    $p2 = q%
        \t$(ESQL_CC) -c $(ESQLCFLAGS) $(ESQLFLAGS) $*.ec
        \t$(RM_F) $*.c

        # Cribbed from the definition of CCCMD (MakeMaker const_cccmd) and the
        # rules for compiling object files (MakeMakerc_o) in the Makefile.
        # There should be a cleaner way to do this, too.
        # May need fixing if the corresponding rules change.
        # NB: UFLAGS is a DBD::Informix addition - it is for user-flags and should
        #     not be set by the Makefile.  The user can add a flag on the make line
        #     with "make UFLAGS=-Dxyz".
        UFLAGS =
        ESQLFLAGS = $(UFLAGS) $(INC) $(CCFLAGS) $(OPTIMIZE) \
        \t$(PERLTYPE) $(LARGE) $(SPLIT) $(DEFINE_VERSION) \
        \t$(XS_DEFINE_VERSION) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE)
        %;

    $p3 = q%
    ESQL_CC     = $(ESQL)
    %;

    $p4 = '
        MAP_LINKCMD = $(ESQL_CC)

        # Need to move the esql script created locally (in case the next build
        # uses a version of ESQL/C which does not need the custom esql script).
        clean::
        \t-[ -f esql ] && mv esql esql.old

        # $(O_FILES) omits the ESQL/C object files - this does not.
        $(OBJECT): $(H_FILES)

        ';

    $p1 = nlws("$p1$p2$p3$p4");
    $p1 =~ s/\n\\t/\n\t/gmo;
    return($p1);
}

sub split_print
{
    my($libs, $width, $leader) = @_;
    my $leadlen = length($leader);
    my $linelen = $leadlen;
    my $line = $leader;
    foreach my $name (split ' ', $libs)
    {
        my($namelen) = length($name) + 1;
        if ($linelen + $namelen > $width)
        {
            print "$line\n";
            $line = $leader;
            $linelen = $leadlen;
        }
        $line .= " $name";
        $linelen += $namelen;
    }
    print "$line\n";
}

# nlws - no leading white space.
# Strip leading white space from lines in a string, to allow quoted
# strings to be indented in source but printed without indentation.
sub nlws
{
    my($string) = @_;
    $string =~ s/^\s+//o;
    $string =~ s/\n\s+/\n/gmo;
    return $string;
}

# Execute a command, logging it if $sx is set, and dying with given
# message if command fails.
# JL 2005-07-25: you get better debugging information if you print in
# the parent process.
sub execute_command
{
    my ($sx, $msg, $cmd) = @_;
    if ($sx)
    {
        print "execute_command: @$cmd\n";
        foreach my $arg (@$cmd) { print "+ec+ <<$arg>>\n" }
    }
    if (my $pid = fork)
    {
        # Parent - wait for child to die
        while (wait != $pid && wait != -1)
            {}
        die $msg if ($? != 0);
    }
    else
    {
        # Child - exec the command!
        exec @$cmd;
    }
}

sub set_esqlc_linkage
{
    my ($def_link) = @_;
    my $env_link = $ENV{DBD_INFORMIX_ESQLC_LINKAGE};
    print "** Using $env_link from DBD_INFORMIX_ESQLC_LINKAGE environment variable.\n\n"
        if (defined $env_link);
    return (defined $env_link) ? $env_link : $def_link;
}

sub Write_DBD_Informix_Defaults
{
    my($ixd) = @_;
    my $defaults = "$dbd_ix_pm_dir/Defaults.pm";
    open DEFAULTS, ">$defaults"
        or die "Cannot create $defaults ($!)";

    print DEFAULTS <<'EOF';
#   Default Environment Variables for Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28)
#
#   Copyright 2002-03 IBM
#   Copyright 2004-10 Jonathan Leffler
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

{
    package DBD::Informix::Defaults;

    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT = qw(default_INFORMIXDIR default_INFORMIXSERVER);
    $VERSION = "2018.1029";
    $VERSION = "0.97002" if ($VERSION =~ m%[:]VERSION[:]%);

EOF

    print DEFAULTS "\tsub default_INFORMIXDIR\n\t{\n\t\treturn '$ixd';\n\t}\n";
    print DEFAULTS "\tsub default_INFORMIXSERVER\n\t{\n\t\treturn '$ENV{INFORMIXSERVER}';\n\t}\n";
    print DEFAULTS <<'EOF';
    1;
}

__END__

=head1 NAME

DBD::Informix::Defaults - Default values for INFORMIXDIR and INFORMIXSERVER

=head1 SYNOPSIS

use DBD::Informix::Defaults;

=head1 DESCRIPTION

This module was generated automatically by DBD::Informix
(Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28)).
It records the default values of INFORMIXDIR and INFORMIXSERVER
that were in use when DBD::Informix was built.
You can edit the returned values if you need to,
but worry about where the Informix libraries are loaded from.

EOF

    if (defined($ENV{DBD_INFORMIX_RELOCATABLE_INFORMIXDIR}))
    {
        print DEFAULTS "Because $opts{NAME} was built with a relocatable INFORMIXDIR,\n";
        print DEFAULTS "if you edit INFORMIXDIR here, you will need to worry about\n";
        print DEFAULTS "how the shared libraries are located, which is hard, in general,\n";
        print DEFAULTS "because the mechanisms vary from platform to platform.\n\n";
    }
    else
    {
        print DEFAULTS "Because $opts{NAME} was built without a relocatable INFORMIXDIR,\n";
        print DEFAULTS "if you edit INFORMIXDIR here, you will need to keep the libraries\n";
        print DEFAULTS "in the original location because those path names are hard-linked.\n\n";
    }

    print DEFAULTS qq'The recorded default values are:\n\n';
    print DEFAULTS qq'    INFORMIXDIR    = "$ENV{INFORMIXDIR}"\n';
    print DEFAULTS qq'    INFORMIXSERVER = "$ENV{INFORMIXSERVER}"\n\n';

    if ($effvernum < 600)
    {
        print DEFAULTS "NB: although you are using $infversion,\n";
        print DEFAULTS "DBD::Informix needs this module to set a default value for INFORMIXSERVER,\n";
        print DEFAULTS "but you will not normally set it in your environment,\n";
        print DEFAULTS "despite the comments below.\n\n";
    }
    print DEFAULTS <<'EOF';
You will seldom if ever have cause to use this module directly.
You should seldom have cause to use it indirectly either because
you will always set INFORMIXDIR and INFORMIXSERVER in the
environment before using DBD::Informix.

This module increases the chances of DBD::Informix working
with Apache and mod_perl without attention modifying the Apache configuration.

=head1 AUTHOR

Jonathan Leffler

=cut
EOF

    close DEFAULTS or die;
    print "$defaults written OK\n";
}

__END__
