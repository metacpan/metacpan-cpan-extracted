#!/usr/local/bin/perl -w
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.
#
# Test dependencies on CPAN:
# http://cpandeps.cantrell.org.uk/?module=DBD::ODBC;perl=latest
#
## no critic (ProhibitMagicNumbers RequireInterpolationOfMetachars)
## no critic (RequireExtendedFormatting RequireCheckingReturnValueOfEval)
## no critic (RequireCarping ProhibitParensWithBuiltins RequireBriefOpen)
## no critic (RequireLocalizedPunctuationVars ProhibitBacktickOperators)
#  keeps reporting this even though I am not matching dots:
## no critic (RequireDotMatchAnything)
# I am not changing all these - would take too long to check each one
## no critic (RequireLineBoundaryMatching)

use strict;
BEGIN { require 5.004 }         # 5.004 is required for Win32
use Config;
use ExtUtils::MakeMaker 5.16, qw(&WriteMakefile $Verbose prompt);
use File::Basename;
use Getopt::Long;
use File::Spec;
use English qw( -no_match_vars );
use warnings;

$OUTPUT_AUTOFLUSH = 1;

print <<"EOT";

**********
\tRemember to actually *READ* the README file!
\tAnd re-read it if you have any problems.\n
**********

EOT

{
    # some useful info when debugging problems
    print "OSNAME: $OSNAME\n";
    my @envs = qw(LANG ODBCHOME LD_LIBRARY_PATH DBROOT WINDIR II_SYSTEM);
    foreach (@envs) {
        print "$_: ", ($ENV{$_} ? $ENV{$_} : ''), "\n";
    }
    print "Perl: $]\n";
    print "ExtUtils::MakeMaker: $ExtUtils::MakeMaker::VERSION\n";
}

# the following now redundant since we found constants (see end) which allows
# us to override the constants.
######
###### if INC is set on the command line ExtUtils::MakeMaker will not override it
###### or allow us to add to it so you can never find the DBI header files.
###### It is pointless to continue
###### see http://www.mail-archive.com/makemaker@perl.org/msg02680.html
###### see http://www.nntp.perl.org/group/perl.dbi.users/2008/09/msg33278.html
###### http://www.perlmonks.org/?node_id=714150
#####my $INC_argc;
#####for (my $n = 0; $n <= $#ARGV; $n++) {
#####    if ($ARGV[$n] =~ /^INC=/) {
#####        $INC_argc = $n;
#####        print "\nCannot generate successful Makefile - " .
#####            "INC is set on the command line.\n\n";
#####        prompt("Press return to see possible solutions:");
#####        print <<"EOT";
#####
#####INC has been set on the command line as: $ARGV[$n]
#####
#####and there is no way this Makefile.PL can add the path to the DBI
#####header files to INC. If you manually added INC to the command line
#####remove it. If you are building from the CPAN shell perhaps your
#####makepl_arg is set to include INC (as it is with Strawberry Perl). You
#####need to remove INC from makepl_arg with:
#####
#####cpan> o conf
#####
#####Look for makepl_arg and set makepl_arg to whatever text it is minus the INC
#####setting. You set makepl_arg with:
#####
#####cpan> o conf makepl_arg 'text of makepl_arg - INC'
#####
#####Alternatively, if you are using Strawberry perl you can just install
#####DBD::ODBC outside of the CPAN shell.
#####
#####If you cannot remove INC from the command line then you will need to hand
#####edit the generated Makefile. Search it for :
#####
##### #   MakeMaker 'CONFIGURE' Parameters:
##### #     INC => q[-I. -I/some_path/DBI]
#####
#####then add the -I/some_path/DBI to INC where it is set later in the
#####Makefile.
#####
#####EOT
#####        #exit 0;
#####    }
#####}
my %opts =
(
    ## no critic (RequireInterpolationOfMetachars)
    NAME         => 'DBD::ODBC',
    VERSION_FROM => 'ODBC.pm',
    # See note below on CONFIGURE. This used to work when we could rely on
    # CONFIGURE being after PREREQ_PM but that is not the case now so the
    # line below does nothing since 6.33 of MakeMaker.
    PREREQ_PM    => {
        "Test::Simple" => 0.90, # actually Test::More pkg in T::S dist,
        "DBI"          => 1.609 },
    clean        => { FILES => 'ODBC.xsi dbdodbc.h' },
    dist         => {
	DIST_DEFAULT => 'clean distcheck tardist',
	PREOP        => '$(MAKE) -f Makefile.old distdir',
	COMPRESS     => 'gzip -v9', SUFFIX => 'gz'
    },
    OBJECT       => '$(O_FILES)',
    DEFINE => q{},
 );
# just save the open suse guys patching the following:
if ($ENV{RPM_OPT_FLAGS}) {
    $opts{OPTIMIZE} = $ENV{RPM_OPT_FLAGS};
}

my $eumm = $ExtUtils::MakeMaker::VERSION;
$eumm =~ tr/_//d;

$opts{LICENSE} = 'perl' if $eumm >= 6.3002;
$opts{NO_META} = 1 if $eumm >= 6.10;

if ($eumm >= 5.43) {
    $opts{AUTHOR} = 'Tim Bunce, Jeff Urlwin, Martin J. Evans mailto:dbi-users@perl.org';
    $opts{ABSTRACT} = 'ODBC driver for the DBI module.';
    $opts{CAPI} = 'TRUE' if $Config{archname} =~ /-object\b/i;
    # Never set PREREQ_FATAL to true - it is flawed
    # - see http://wiki.cpantesters.org/wiki/CPANAuthorNotes
    #$opts{PREREQ_FATAL} = 1;
    # See
    # http://www.mail-archive.com/cpan-testers-discuss%40perl.org/msg00076.html
    # In ExtUtils::MakeMaker 6.32 and earlier CONFIGURE was run after PREREQ_PM
    # so we could safely require DBI::DBD here and PREREQ_PM would fail first
    # if DBI was not installed. Since 6.33 CONFIGURE is run before PREREQ_PM
    # so now the require below fails and if we do not exit 0 without generating
    # a Makefile cpan-testers will fail us if DBI is not found.
    $opts{CONFIGURE} = sub {
        eval {require DBI::DBD;};
        if ($@) {
            warn $@;
            exit 0;
        } else {
        my $dbi_arch_dir = DBI::DBD::dbd_dbi_arch_dir();
        if (exists($opts{INC})) {
            return {INC => "$opts{INC} -I$dbi_arch_dir"};
        } else {
            return {INC => "-I$dbi_arch_dir"};
        }
    }
    };
}
if ($eumm >= 5.48) {
    $opts{PREREQ_PRINT} = 1;
}

my $opt_g = 0;                  # build debug
my $opt_o = q{};                # odbc home overrides ODBCHOME
my $opt_u = undef;              # build unicode version
my $opt_e = undef;              # easysoft
my $opt_x = undef;              # prefer unixODBC over iODBC
my $opt_w = undef;              # enable -Wall (gcc only)

my @options = ("g!" => \$opt_g,
               "o=s" => \$opt_o,
               "u!" => \$opt_u,
               "e!" => \$opt_e,
               "x!" => \$opt_x,
               "w!" => \$opt_w);
my %options = @options;
Getopt::Long::GetOptions(@options) or die "Invalid arguments\n";

print "Command line options:\n",
    (map {"  $_ = " . (defined(${$options{$_}}) ? ${$options{$_}} : 'undef') . "\n"} keys %options), "\n";
if (($ENV{LANG} || q{}) =~ m/utf-?8/i) {
    print <<"EOT";

Your LANG environment variable is set to "$ENV{LANG}"\a
This is known to cause problems in some perl installations - even stopping
this Makefile.PL from running without errors. If you have problems please
try re-running with LANG unset or with the utf part of LANG removed.

EOT
    sleep 4;
}

if ($Config{useithreads}) {
    print <<'EOT';
You are using a Perl configured with threading enabled.
Please read the warnings in DBI about this.

EOT
    if ($OSNAME ne 'MSWin32') {
        print <<'EOT';
You should also be aware that on non-Windows platforms ODBC drivers come
in two forms, thread-safe and non-thread-safe drivers and you may need
to make sure you are using the right one.

EOT
    }
    # see rt 46944 for why the following was suggested to be commented
    # out which I rejected as PERL_MM_USE_DEFAULT can be used
    prompt("Press return to continue...");
}
print "Overriding ODBC Directory with command line option: $opt_o\n"
    if $opt_o ;
if ($opt_g) {
   print "Setting debug options!\n";
   if ($OSNAME eq 'MSWin32') {
      $opts{OPTIMIZE} = '/Zi';
   } else {
      $opts{OPTIMIZE} = '-g -O0';
   }
}
if ($opt_w) {
    $opts{CCFLAGS} = '-Wint-to-pointer-cast -fno-strict-aliasing -Wall -Werror=format-security';
}
if (defined($opt_u) && $opt_u) {
    $opts{DEFINE} .= ' -DWITH_UNICODE';
    require 5.008001;
}

my @known_drivers = sort { $a cmp $b } (
	'Microsoft ODBC',
	'unixodbc',
	'iodbc',
	'empress',
	'intersolve',
	'sapdb',
	'adabas',
	'udbc',
	'solid',
	'informix',
    'ingrescli', ## clach04 Ingres CLI name?
	);
my $odbchome_specified;
$odbchome_specified = 1 if defined($opt_o) || defined($ENV{ODBCHOME});

#
# create the dbdodbc.h file with all the required includes per driver or
# driver manager
#
my $sqlhfh;
open($sqlhfh, q/>/, 'dbdodbc.h') || die "Can't open dbdodbc.h: $!\n";
print {$sqlhfh}
    qq{/* Do not edit this file. It is automatically written by Makefile.PL.\n};
print {$sqlhfh} qq{   Any changes made here will be lost. \n*/\n\n};
print {$sqlhfh} qq{#undef WORD /* from perly.y */\n};

if ($OSNAME eq 'MSWin32') {
    my $extrainc = q{};
    $extrainc = ";$Config{incpath}\\mfc" if $Config{cc} eq 'bcc32';
    $opts{SKIP} = ['processPL'];
    if (!defined($opt_u) || $opt_u) {
	$opts{DEFINE}  .= " -DWITH_UNICODE";
	require 5.008001;
    }
    # stop all those strcpy etc warnings:
    $opts{DEFINE} .= " -D_CRT_SECURE_NO_DEPRECATE";
    $opts{INC}  = "$extrainc";
    $opts{LIBS} = ["ODBC32.LIB"];
    $opts{macro}->{EXTRALIB} = 'ODBC32.LIB';
    print {$sqlhfh} "#include <windows.h>\n";
    print {$sqlhfh} <<'EOT';
#ifdef WIN32
# ifndef _WIN64
#  ifndef SQLLEN
#   define SQLLEN          SQLINTEGER
#  endif
#  ifndef SQLULEN
#   define SQLULEN         SQLUINTEGER
#  endif
#  ifndef SQLSETPOSIROW
#   define SQLSETPOSIROW   SQLUSMALLINT
#  endif
# endif
#endif
EOT
    print {$sqlhfh}
        "#include <sql.h>\n#include <sqltypes.h>\n#include <sqlext.h>\n";
} elsif ($opt_e) {
    my $odbchome = "/usr/local/easysoft/unixODBC";
    my $odbclibdir = "/usr/local/easysoft/unixODBC/lib";
    my $odbcincdir = "/usr/local/easysoft/unixODBC/include";
    $opts{INC} = "-I. -I$odbcincdir";
    $opts{DEFINE} .= "-DSIZEOF_LONG=8 -DBUILD_REAL_64_BIT_MODE";

    my $soext = $Config{so};      # extension for share objects
    my $dlext = $Config{dlext};   # extension for dynamically loaded modules
    my $arext = $Config{lib_ext}; # this is _a now, library extension

    my @libs = glob "$odbclibdir/libodbc.*";
    my @ilibs = grep { /\.($soext|$dlext|a)$/ } @libs;
    if (scalar(@ilibs) == 0) {
        die "Cannot find unixODBC";
    }
    my $ilibpath = $ilibs[0]; # if both .so and .a, pick based on LINKTYPE?
    my $ilibname = basename($ilibpath);
    if ($ilibname =~ /^odbc/) { # no "lib" prefix
        $opts{LIBS} = q{};
        $opts{dynamic_lib} = { OTHERLDFLAGS => "$ilibpath" };
    }
    else {
        # remove lib prefix and .so suffix so "-l" style link can be used
        $ilibname =~ s/^lib(odbc.*?)\.\w+$/$1/;
        $opts{LIBS} = "-L$odbclibdir -l$ilibname";
        warn "Warning: LD_LIBRARY_PATH doesn't include $odbclibdir\n"
            unless (exists($ENV{LD_LIBRARY_PATH}) &&
                        ($ENV{LD_LIBRARY_PATH} =~ /\Q$odbclibdir/));
    }
    print {$sqlhfh} qq{#include <sql.h>\n};
    print {$sqlhfh} qq{#include <sqlucode.h>\n};
    print {$sqlhfh} qq{#include <sqltypes.h>\n};
    print {$sqlhfh} qq{#include <sqlext.h>\n};
} else {

    my $myodbc = q{};
    my $myodbc_version = -1;

    # cannot believe the following still works as $odbchome is checked later
    # to be a directory - so commented out - there are other ways to do
    # this anyway
    # for Adabas
    #$ENV{ODBCHOME} = $ENV{DBROOT}
    #    if $ENV{DBROOT} && -f "$ENV{DBROOT}/lib/odbclib.a";

    print "Overriding ODBC Directory with command line option: $opt_o\n"
        if $opt_o ;
    my $odbchome= $opt_o || $ENV{ODBCHOME};
    my ($odbcincdir, $odbclibdir);
    $odbchome = VMS::Filespec::unixify($odbchome) if $OSNAME eq 'VMS';


    # if we haven't got odbchome set try and find a driver, driver manager.
    if (!$odbchome) {
        if ($ENV{WINDIR} && $OSNAME eq 'cygwin') {
            ## per patches from Teun Burgers
            #my $tmp_odbchome = $ENV{WINDIR};
            #$tmp_odbchome =~ s/^([A-Za-z]):*$/\/\/$1/;
            #$tmp_odbchome =~ s/\\/\//g;
            #$odbchome = $tmp_odbchome if (-e "$tmp_odbchome/odbc.ini")
            chomp($odbchome = `cygpath \$WINDIR`);
        } elsif (-f '/opt/sapdb/interfaces/odbc/lib/libsqlod.a') {
            $odbchome = '/opt/sapdb/interfaces/odbc/';
        }
    }
    if ($OSNAME eq 'cygwin'){   #Trade cygwin as MSWin.
        my $extrainc = q{};
        $extrainc = ";$Config{incpath}\\mfc" if $Config{cc} eq 'bcc32';
        $opts{SKIP} = ['processPL'];
        if (!defined($opt_u) || $opt_u) {
            $opts{DEFINE}  .= " -DWITH_UNICODE";
            require 5.008001;
        }
        $opts{INC}  = "$extrainc";
        $opts{LIBS} = ["ODBC32.LIB"];
        $opts{macro}->{EXTRALIB} = 'ODBC32.LIB';
        print {$sqlhfh} "#include <windows.h>\n";
        print {$sqlhfh}
            "#include <sql.h>\n#include <sqltypes.h>\n#include <sqlext.h>\n";
    } elsif ($OSNAME !~ /MSWin/  ) {
        # look for Ingres' driver manager first on the basis of if you
        # have ingres you probably want to use it. Also Ingres ships with
        # libs that look like unixODBC/iODBC
        if ($ENV{II_SYSTEM}) {
            my $home = File::Spec->catdir($ENV{II_SYSTEM}, 'ingres');
            my $inc = File::Spec->catdir($home, 'files');
            if ((-f File::Spec->catfile($inc, 'sql.h')) &&
                     (-f File::Spec->catfile($home, 'bin', 'iiodbcadmin'))) {
                $odbchome = File::Spec->catdir($ENV{II_SYSTEM}, 'ingres');
                $odbclibdir = File::Spec->catdir($odbchome, 'lib');
                $odbcincdir = $inc;
                $myodbc = 'ingrescli';
            }
        }
        # try and find unixODBC's odbc_config binary
        if (!$myodbc) {
            ($myodbc, $myodbc_version, $odbchome, $odbcincdir, $odbclibdir) =
                unixodbc_config($odbchome);
        }
        if (!$myodbc) {
            # try and find iODBC's iodbc_config binary
            ($myodbc, $myodbc_version, $odbchome,
             $odbcincdir, $odbclibdir) = iodbc_config($odbchome);
        }

        if (!$odbchome) {
            print "odbc_config not found - " .
                "ok, there are other things I can do\n";

            print "Still trying to guess ODBCHOME - looking for headers now\n";
            $odbchome = find_dm_hdr_files();
        }
    }

    unless ($odbchome) {
	print <<'EOT';

The DBD::ODBC module needs to link with an ODBC 'Driver Manager'.
(The Driver Manager, in turn, needs one or more database specific ODBC
drivers. The DBD::ODBC module does _not_ include any ODBC drivers!)

You need to indicate where your ODBC Driver Manager is installed.
You can do this by:

o setting the ODBCHOME environment variable
o running 'perl Makefile.PL -o odbcdir'
o adding path to odbc_config/iodbc_config to PATH

If you do not have an ODBC Driver Manager you should try to get hold of
the unixODBC packages for your system or build it from source (see
http://www.unixodbc.org). If you install driver manager packages you
need to include the "XXX-dev" package which includes the C header files.
EOT
        # stop cpan testers from reporting a failure when a driver manager
        # library is not installed. Do not know if Devel::CheckLib (when
        # it is released) is going to help here.
        # see http://www.mail-archive.com/cpan-testers-discuss%40perl.org/msg00043.html
        exit 0;
    }
    die "odbc home ($odbchome) does not refer to a directory.\n"
        unless -d $odbchome;
    warn "Using ODBCHOME $odbchome\n";

    # $odbcincdir and $odbclibdir will only be set at this point if we
    # found odbc_config/iodbc_config - otherwise we only have a $odbchome
    # either from -o, ODBCHOME or by finding sql*.h header files somewhere.
    if (!$odbcincdir) {
        $odbcincdir = File::Spec->catdir($odbchome, 'include');
    }
    if (!$odbclibdir) {
        $odbclibdir = File::Spec->catdir($odbchome, 'lib');
    }

    $opts{INC}  = "-I.";

    # cygwin patch
    $opts{INC}  .= " -I/usr/include/w32api" if $OSNAME eq 'cygwin';

    # TO_DO all this needs to move until later
#    my $lib_d1 = "$odbchome/lib";
#    my $lib_d2 = "$odbchome/dlls";
#    my $libs   = "odbc";
#    $opts{LIBS} = " -L$lib_d1 -R$lib_d1 -L$lib_d2 -R$lib_d2 -l$libs";

    my $soext = $Config{so};      # extension for share objects
    my $dlext = $Config{dlext};   # extension for dynamically loaded modules
    my $arext = $Config{lib_ext}; # this is _a now, library extension

    # fix to avoid foo..ext on many systems.
    $arext =~ s/^\.//;

    # Try to work out which driver manager is being used.
    #
    # NOTE: if $myodbc is already set we found a driver manager config binary
    # above and have already set $odbchome, $odbcincdir and $odbclibdir.
    #
    # NOTE: we look for iodbc first because both it and unixODBC supply a
    # libodbc.xx but only iodbc supplies a libiodbc.xx. As a result the only
    # reliable way of telling one from the other is to look for libiodbc.xx
    # first.
    # NOTE: -x says we prefer unixODBC over iODBC
    # This is to cater for those insane situations when someone had libiodbc
    # and unixODBC binary packages installed but unixODBC dev package
    # e.g. some people on Debian/Ubuntu
    #
    # PERL_DBD_ODBC_PREFER_UNIXODBC  added for Caelum/Rafael for automated
    # installs/upgrades from cpan clients
    if (!$myodbc && ($opt_x || $ENV{PERL_DBD_ODBC_PREFER_UNIXODBC})) {
        ($myodbc, $odbclibdir) = find_unixodbc($odbchome);
    } else {
        ($myodbc, $odbclibdir) = find_iodbc($odbchome) if !$myodbc;

        ($myodbc, $odbclibdir) = find_unixodbc($odbchome) if !$myodbc;
    }

    $myodbc = 'Microsoft ODBC'
        if (!$myodbc &&
                (-e "$odbchome/system/odbc32.dll" or
                     -e "$odbchome/system32/odbc32.dll" or
                         -e "$odbchome/odbc32.dll"));

    $myodbc = 'empress'
        if !$myodbc && glob "$odbchome/lib/libempodbc.*";

    $myodbc = 'intersolve'
        if !$myodbc && -f "$odbchome/include/qeodbc.h";

    $myodbc = 'sapdb'
        if !$myodbc && -f "$odbchome/lib/libsqlod.$arext";

    $myodbc = 'adabas'
        if (!$myodbc &&
                $ENV{DBROOT} &&
                    ($odbchome eq $ENV{DBROOT}) &&
                        -f "$odbchome/lib/odbclib.$arext");

    $myodbc = 'udbc'
        if !$myodbc && -f "$odbchome/lib/libudbc.$arext";

    $myodbc = 'solid'
        if !$myodbc && -f "$odbchome/lib/libsolcli.$dlext";

    # JL 2002-12-16: This test is accurate on Unix (Solaris 7) with IBM
    # Informix ClientSDK 2.80.UC1, which includes IBM Informix CLI
    # v3.81.000, an ODBC 3.x driver.
	# NB: The correct value for $ODBCHOME is $INFORMIXDIR.
    $myodbc = 'informix'
        if !$myodbc && -f "$odbchome/lib/cli/libifcli.$dlext";

    if (!$myodbc) {
	local($LIST_SEPARATOR) = ", ";
	my($list) = "@known_drivers";
	$list =~ s/^(.{30,70})\s/$1\n\t/gmo;
        die qq{I cannot find an ODBC driver manager that I recognize.\n...And I know about these drivers:\n$list\n};
    }

    warn "\nThis looks like a $myodbc type of driver manager.\n";

    # some specific checks for incompatibilities
    if (defined($opt_u) && $opt_u) {
        if (-e File::Spec->catfile($odbcincdir, 'sql.h')) {
            my $fh;
            open($fh, q/</, "$odbchome/include/sql.h") or
                die "Failed to open $odbchome/include/sql.h - $!";
            my @lines = <$fh>;
            my @found = grep {/iODBC driver manager/i} @lines;
            if (scalar(@found)) {
                die "\n\nDBD::ODBC does not support unicode with iODBC and this looks like iODBC. The iODBC driver manager expects wide characters to be 4 bytes long and DBD::ODBC wants wide characters to be UTF16.\nEither\no) Rerun without the -u switch\no) complain to the producer of your ODBC driver manager\no) get another ODBC driver manager (like unixODBC).\n\n";
            }
            close $fh or warn "Failed to close sql.h - $!";
        }
    }

    if ($myodbc eq 'Microsoft ODBC') {
        print "\nBuilding for Microsoft under Cygwin\n";
        $opts{LIBS} = "-L/usr/lib/w32api -lodbc32";
        print {$sqlhfh} "#include <windows.h>\n";
        print {$sqlhfh} "#include <sql.h>\n";
        print {$sqlhfh} "#include <sqltypes.h>\n";
        print {$sqlhfh} "#include <sqlext.h>\n";
        print {$sqlhfh} "#undef WIN32\n";
        $opts{dynamic_lib} = {OTHERLDFLAGS => "-lodbc32"};
    } elsif ($myodbc eq 'ingrescli') {
        $opts{INC} .= " -I$odbcincdir";
        $opts{LIBS} = "-L$odbclibdir -liiodbc.1";
        print {$sqlhfh}
            qq{typedef void* PTR;\n#include <sql.h>\n#include <sqlext.h>\n};
    } elsif ($myodbc eq 'iodbc') {
        my @libs = glob "$odbclibdir/*iodbc*.*";
        my @ilibs = grep { /\.($dlext|$soext|$arext)/ } @libs;
        if (scalar(@ilibs) == 0) {
            die "That's odd, I can't see any iodbc libs in $odbclibdir. " .
                "This is all I found:\n" . join(q{,}, @libs) . "\n" .
                "Perhaps you need to install the iODBC development " .
                "package, often called libiodbc-dev.";
        }
        # Note: we use DEFINE not INC for iODBC so we don't get its config.h
        my $ilibpath = $ilibs[0]; # if both .so and .a, pick based on LINKTYPE?
        my $ilibname = basename($ilibpath);
        $opts{DEFINE} .= " -I$odbcincdir";
        if ($ilibname =~ /^iodbc/) { # no "lib" prefix
            $opts{LIBS} = q{};
            $opts{dynamic_lib} = { OTHERLDFLAGS => "$ilibpath" };
        }
        else {
            # remove lib prefix and .so suffix so "-l" style link can be used
            $ilibname =~ s/^lib(iodbc.*?)\.\w+$/$1/;
            $opts{LIBS} = "-L$odbclibdir -l$ilibname";
            warn "Warning: LD_LIBRARY_PATH doesn't include $odbchome/lib\n"
                if (!defined($ENV{LD_LIBRARY_PATH})) ||
                    ($ENV{LD_LIBRARY_PATH} =~ /\Q$odbclibdir/);
        }
        if (-x "$odbchome/bin/iodbc-config") {
            my $cf = `$odbchome/bin/iodbc-config --cflags 2>&1`;
            if ($cf =~ /\-I/) {
                chomp $cf;
                $cf =~ s/\n//g;
                print qq/Adding iodbc_config --cflags "$cf" to CC line\n/;
                $opts{DEFINE} .= " $cf";
            }
        }
        print {$sqlhfh} qq{#include <sqlext.h>\n};
        print {$sqlhfh} qq{#include <sql.h>\n};
        print {$sqlhfh} qq{#include <sqltypes.h>\n};
    }
    elsif ($myodbc eq 'unixodbc') {
        # if we find odbcinst, output useful info about this version of unixODBC
        # and store unixODBC version
        print "Looking for odbcinst\n";
        if (-x "$odbchome/bin/odbcinst") {
            print "  Found odbcinst in $odbchome/bin\n";
            my $j = `$odbchome/bin/odbcinst -j 2>&1`;
            print "  odbcinst -j reports:\n\n$j\n" if $j;
            if ($j =~ /^unixODBC ([\d\.]+).*/ ) {
                $myodbc_version = $1;
            }
            print "Please note these files as they are where you define your ODBC drivers and data sources.\n\n";
        } else {
            print "  odbcinst not found - ok, I can deal with that.\n";
        }
        # if we find odbc_config add --cflags output to CC line
        print "Looking for odbc_config to get cflags\n";
        if (-x "$odbchome/bin/odbc_config") {
            #my @args = qw(--prefix --include-prefix --lib-prefix --version --odbcversion);
            #for my $oca (@args) {
            #    my $c = `$odbchome/bin/odbc_config $oca 2>&1`;
            #    chomp $c;
            #    if ($c) {
            #        print "odbc_config $oca = $c\n";
            #    }
            #}
            #print "\n";
            my $cf = `$odbchome/bin/odbc_config --cflags 2>&1`;
            if ($cf =~ /\-D/) {
                chomp $cf;
                $cf =~ s/\n//g;
                print qq/Adding odbc_config --cflags "$cf" to CC line\n/;
                $opts{DEFINE} .= " $cf";
            }
        } else {
            print "  odbc_config not found - ok\n";
        }
        my ($ilibpath, $ilibname, @ilibs);
        my @libs = glob "$odbclibdir/libodbc.*";
        # prefer dynamic linking
        if (@ilibs = grep /\.($soext)/, @libs) {
            # remove any shared object version off the end e.g. libodbc.so.2
            $ilibpath = $ilibs[0];
            $ilibpath =~ s/(.*\.$soext).*$/$1/;
            $ilibname = basename($ilibpath);
            $ilibname =~ s/^lib(odbc.*)\.\w+$/$1/;
            $opts{LIBS} = "-L$odbclibdir -l$ilibname";
            warn "Warning: LD_LIBRARY_PATH=", ($ENV{LD_LIBRARY_PATH} ? $ENV{LD_LIBRARY_PATH} : ""), " doesn't include $odbclibdir\n"
                unless (exists($ENV{LD_LIBRARY_PATH}) &&
                            ($ENV{LD_LIBRARY_PATH} =~ /\Q$odbclibdir/));
        } elsif (@ilibs = grep /\.($dlext)/, @libs) {
            $ilibpath = $ilibs[0];
            $ilibpath =~ s/(.*\.$dlext).*$/$1/;
            $ilibname = basename($ilibpath);
            $ilibname =~ s/^lib(odbc.*)\.\w+$/$1/;
            $opts{LIBS} = "-L$odbclibdir -l$ilibname";
        } elsif (@ilibs = grep /\.($arext)$/, @libs) {
            $ilibpath = $ilibs[0];
            $ilibname = basename($ilibpath);
            #$opts{LINKTYPE} = 'static';
            #$opts{linkext} = {LINKTYPE => 'static'};
            $opts{dynamic_lib} = { OTHERLDFLAGS => "$ilibpath" };
            # you can build against a static unixODBC lib but it still needs
            # to dynamically load (dl_open) drivers so we need libltdl:
            $opts{LIBS} = "-lltdl";
        } else {
            die "That's odd, I can't see any unixodbc libs in $odbchome.\n" .
                "This is all I found:\n" . join(q{,}, @libs) . "\n" .
                "Perhaps you need to install the unixODBC development " .
                "package, often called unixodbc-dev.\n";
        }

        $opts{DEFINE} .= " -I$odbcincdir";
        print {$sqlhfh} qq{#include <sql.h>\n};
        print {$sqlhfh} qq{#include <sqlucode.h>\n};
        print {$sqlhfh} qq{#include <sqltypes.h>\n};
        print {$sqlhfh} qq{#include <sqlext.h>\n};
    }
    elsif ($myodbc eq 'intersolve') {
  	print {$sqlhfh} qq{#include <qeodbc.h>\n};
	if (-f "$odbcincdir/sql.h") {
	    print "You seem to have the official header files.\n";
	    $opts{INC} .= " -I$odbcincdir";
	    print {$sqlhfh} qq{#include <sql.h>\n#include <sqltypes.h>\n#include <sqlext.h>\n};
	}
	else {
	    # This is common on Solaris
	    print "You don't seem to have the official header files,\n";
	    print "so I'll use the iODBC ones instead.\n";
	    $opts{INC} .= " -I$odbcincdir -Iiodbcsrc";
	    print {$sqlhfh} qq{#include <isql.h> \n#include <isqlext.h>\n};
	}
    }
    elsif ($myodbc eq 'empress') {
	$opts{INC} .= " -I$odbcincdir";
	print {$sqlhfh} qq{#include <odbcsys.h>\n};
	print {$sqlhfh} qq{#include <sql.h>\n#include <sqlext.h>\n};
	$opts{LIBS} = "-L$odbclibdir -R$odbclibdir -lempodbc";
    }
    elsif ($myodbc eq 'sapdb') {
	print {$sqlhfh} "#include <WINDOWS.H>\n";
	print {$sqlhfh} "#include <sql.h>\n";
	print {$sqlhfh} "#include <sqlext.h>\n";
	print {$sqlhfh} "#define HENV SQLHENV\n";
	print {$sqlhfh} "#define HDBC SQLHDBC\n";
	print {$sqlhfh} "#define HSTMT SQLHSTMT\n";
	print {$sqlhfh} "#define DBD_ODBC_NO_SQLDRIVERCONNECT\n";
	print {$sqlhfh} qq{#define DBD_ODBC_NO_DATASOURCES\n};

	$opts{INC} .= " -I$odbchome/incl";
	$opts{LDFROM} = "\$(OBJECT) $odbchome/lib/libsqlod.a";
    }
    elsif ($myodbc eq 'adabas') {
	print {$sqlhfh} "#define FAR \n#define EXPORT \n#define CALLBACK \n";
	print {$sqlhfh} "#include <WINDOWS.H>\n";
	print {$sqlhfh} "#include <sql.h>\n";
	print {$sqlhfh} "#include <sqlext.h>\n";
	$opts{INC} .= " -I$odbchome/incl";
	$opts{LIBS} = "-L$odbclibdir -lsqlrte -lsqlptc";
	$opts{LDFROM} = "\$(OBJECT) $odbclibdir/odbclib.a";
    }
    elsif ($myodbc eq 'udbc') {
        print {$sqlhfh} qq{#include <libudbc.h>\n};
        $opts{INC} .= " -I$odbcincdir";
        $opts{LIBS} = "-L$odbclibdir -R$odbclibdir -ludbc";
    }
    elsif ($myodbc eq 'solid') {
        $opts{INC} .= " -I$odbcincdir";
        $opts{LIBS} = "-L$odbclibdir -lsolcli";
	# Solid does not support DataSources
	print {$sqlhfh} qq{#define DBD_ODBC_NO_DATASOURCES\n};
	# Solid does not support DataSources
	print {$sqlhfh} qq{#define DBD_ODBC_NO_SQLDRIVERCONNECT\n};
        print {$sqlhfh} qq{#include <cli0cli.h>\n};
    }
    elsif ($myodbc eq 'informix') {
        # JL 2002-12-16: See comments above for environment details.
        $opts{INC}  = "-I$odbchome/incl/cli $opts{INC}";
        $opts{LIBS} = "-L$odbchome/lib/cli -lifcli -lifdmr";
        $opts{DEFINE} .= " -DNO_WIN32"; # Applies to Unix only, of course
        print {$sqlhfh} qq{#include <stddef.h>\n};
        print {$sqlhfh} qq{#include <infxcli.h>\n};
    }
    else {
	print <<'EOT';
*** WARNING ***
Unknown driver or driver manager. Using default build process.
This will almost certainly fail at some point.
In which case you will need to edit/hack the Makefile.PL
to suit your needs. (Specifically to locate your odbc
library and header files.)
EOT
	print {$sqlhfh} qq{#include <sql.h> \n#include <sqlext.h>\n};
    }
}
print {$sqlhfh} qq{\n};
print {$sqlhfh} qq{#include "fixup_c.h"\n};
print {$sqlhfh} qq{\n};
close($sqlhfh) or die "Failed to close dbdodbc.h - $!";

print "\n";

if ($OSNAME eq 'darwin') {
    $opts{LD} = $Config{ld} . ' -framework CoreFoundation';
    # some older versions of darwin had a problem with iODBC which leads to
    # Symbol not found: _SQLGetPrivateProfileString
    # SQLGetPrivateProfileString is in libiodbcinst.a
    my $osver = `uname -r`;
    if ($osver && ($osver =~ /^8/)) {
        $opts{LIBS} .= ' -L/usr/lib -liodbcinst';
    }
}


my $rv = WriteMakefile(%opts);

local($WARNING)=0;
print "Warning: not all required environment variables are set.\n"
	unless ($ENV{DBI_DSN} && $ENV{DBI_USER} && $ENV{DBI_PASS});
print "Warning: DBI_DSN ($ENV{DBI_DSN}) doesn't start with 'dbi:ODBC:'\n"
	if ($ENV{DBI_DSN} && $ENV{DBI_DSN} !~ m/^dbi:ODBC:/);
print "\n";
if (!exists($ENV{DBI_DSN}) ||
                 !exists($ENV{DBI_USER}) ||
                     !exists($ENV{DBI_PASS})) {
    print "Warning: Will not be able to run tests as you have not defined\n",
        "all of DBI_DSN, DBI_USER and DBI_PASS environment variables.\n";
} else {
    print <<"EOT";
The DBD::ODBC tests will use these values for the database connection:
    DBI_DSN=$ENV{DBI_DSN}     e.g. dbi:ODBC:demo
    DBI_USER=$ENV{DBI_USER}
    DBI_PASS=$ENV{DBI_PASS}
EOT
}

#
# find the files in @files in $path returning 1 if they all exist, 0 otherwise
#
sub files_exist
{
    my ($path, @files) = @_;
    my $found = 1;

    foreach my $file (@files) {
        my $f = File::Spec->catfile($path, $file);
        if (! -f $f) {
            $found = 0;
            last;
        }
    }
    return $found;
}

#
# Try and find out from odbc_config where unixODBC is
#
sub unixodbc_config
{
    my $odbchome = shift;       # may not be set

    print "Looking for odbc_config in : ", ($odbchome ? $odbchome : "nowhere"), "\n";
    my ($inc, $lib, $home, $configbin, $odbc_config_v);

    # unixODBC - would have liked to use odbc_config but it did not
    # exist until 2.2.11 and it was broken wrt --cflags in 2.2.11/2.2.12
    # i.e. --cflags did not include -I/xxx/yyy
    if ($odbchome) {
        $configbin = "$odbchome/bin/odbc_config";
        print "Looking for odbc_config at $configbin\n";
        $odbc_config_v = `$configbin --version 2>&1`;
    }
    if (!defined($odbc_config_v) || ($odbc_config_v !~ /^(\d\.)+/)) {
        print "Looking for odbc_config in (PATH) $ENV{PATH}\n";
        $configbin = 'odbc_config';
        $odbc_config_v = `$configbin --version 2>/dev/null`;
        if (!defined($odbc_config_v) || ($odbc_config_v !~ /^(\d\.)+/)) {
            print "  odbc_config not found\n";
            return;
        }
        if ($odbchome) {
            my $warning = <<"EOT";

***** WARNING *****
You provided ODBCHOME ($odbchome)
which has no odbc_config (not unusual for older unixODBCs)
but we've found an odbc_config on your PATH. It is unlikely the
odbc_config specifications are going to match your specified ODBCHOME
so this script is going to ignore your specified ODBCHOME. If you don't
like this do something  to remove odbc_config from your PATH or ensure
there is an odbc_config in your provided ODBCHOME.

EOT
            warn $warning;
            prompt("Press return to continue...");
        }
    }
    print "  Found odbc_config (via $configbin) version $odbc_config_v\n";

    my @hdrstofind = ('sql.h', 'sqlext.h', 'sqltypes.h');
    push @hdrstofind, 'sqlucode.h' if $opt_u;

    $home = `$configbin --prefix 2>&1`;
    chomp $home;
    if (!defined($home)) {
        print "  cannot find --prefix from odbc_config\n";
        return;
    }
    print "  odbc_config reports --prefix=$home\n";

    # if we cannot find the --prefix dir someone perhaps someone has built
    # it in one place and moved it to another. Try path to odbc_config
    if (! -e "$home") {
        my $ocp = `which $configbin`;
        if ($ocp) {
            chomp $ocp;
            if ($ocp =~ /$configbin$/) {
                $ocp =~ s/bin\/$configbin$//;
                $home = $ocp;
            }
        }
    }

    $inc = `$configbin --include-prefix`;
    chomp $inc;
    print "  odbc_config reports --include-prefix=$inc\n";

    $lib = `$configbin --lib-prefix`;
    chomp $lib;
    print "  odbc_config reports --lib-prefix=$lib\n";

    my $found_hdrs = 0;
    # try with --include-prefix
    if (defined($inc) && (-e $inc) && files_exist($inc, @hdrstofind)) {
        print "  ODBC INC dir set to $inc via odbc_config\n";
        $found_hdrs++;
    }
    if (!$found_hdrs && (-e "$home")) {
        # try with --prefix + include
        $inc = File::Spec->catdir($home, 'include');
        if ((-e "$inc") && files_exist($inc, @hdrstofind)) {
            print "  ODBC INC dir set to $inc via odbc_config\n";
            $found_hdrs++;
        }
    }
#    if (!$found_hdrs) {
#        my $ocp = `which $configbin`;
#        if ($ocp) {
#            chomp $ocp;
#            if ($ocp =~ /$configbin$/) {
#                $ocp =~ s/bin\/$configbin$//;
#                $inc = File::Spec->catdir($ocp, 'include');
#                if ((-e "$inc") && files_exist($inc, @hdrstofind)) {
#                    print "  ODBC INC dir set to $inc from path to $configbin\n";
#                    $found_hdrs++;
#                }
#            }
#        }
#    }
    if (!$found_hdrs) {
        print "  but cannot find header files " . join(',', @hdrstofind) .
            " in that path so ignoring\n";
        print "NOTE: Have you installed the unixodbc-dev package\n";
        return;
    }

    my $found_libdir = 0;

    if (-e "$lib") { # try with --lib-prefix
        print "  ODBC LIB dir set to $lib via odbc_config\n";
        $found_libdir++;
    }
    if (!$found_libdir && -e "$home") {
        # try with --prefix + lib
        $lib = File::Spec->catdir($home, 'lib');
        if (-e "$lib") {
            print "  ODBC LIB dir set to $lib from odbc_config\n";
            $found_libdir++;
        }
    }
#    if (!$found_libdir) {
#        my $ocp = `which $configbin`;
#        if ($ocp) {
#            chomp $ocp;
#            if ($ocp =~ /$configbin$/) {
#                $ocp =~ s/bin\/$configbin$//;
#                $lib = File::Spec->catdir($ocp, 'lib');
#                if (-e "$lib") {
#                    print "Found lib dir $lib from path to $configbin";
#                    $found_libdir++;
#                }
#            }
#        }
#    }
    if (!$lib) {
        print "  but cannot find lib dir so ignoring\n";
        return;
    }

    return ('unixodbc', $odbc_config_v, $home, $inc, $lib);
}

#
# Try and find out from iodbc_config where iODBC is
#
sub iodbc_config
{
    my $odbchome = shift;       # may not be set

    my ($home, $inc, $lib, $configbin, $iodbc_config_v);

    if ($odbchome) {
        $configbin = "$odbchome/bin/iodbc-config";
        print "Looking for iodbc-config at $configbin\n";
        $iodbc_config_v = `$configbin --version 2>&1`;
    }
    if (!defined($iodbc_config_v) || ($iodbc_config_v !~ /^(\d\.)+/)) {
        print "Looking for iodbc-config in PATH $ENV{PATH}\n";
        $configbin = 'iodbc-config';
        $iodbc_config_v = `$configbin --version 2>/dev/null`;
        if (!defined($iodbc_config_v) || ($iodbc_config_v !~ /^(\d\.)+/)) {
            print "  iodbc_config not found\n";
            return;
        }
    }
    print "  Found iodbc-config (via $configbin) version $iodbc_config_v\n";

    my $iodbc_ini = `$configbin --odbcini 2>&1`;
    print "  ODBC data sources should be added to $iodbc_ini\n"
        if ($iodbc_ini);

    my $iodbc_instini = `$configbin --odbcinstini 2>&1`;
    print "  ODBC drivers should be added to $iodbc_instini\n"
        if ($iodbc_instini);

    my @hdrstofind = ('sql.h', 'sqlext.h', 'sqltypes.h');
    push @hdrstofind, 'sqlucode.h' if $opt_u;

    $home = `$configbin --prefix 2>&1`;
    if (!defined($home)) {
        print "  cannot find --prefix from iodbc_config\n";
        return;
    }
    chomp $home;
    print "  iodbc-config reports --prefix=$home\n";

    $inc = File::Spec->catdir($home, 'include');
    $lib = File::Spec->catdir($home, 'lib');

    my $found_hdrs = 0;
    if ((defined($inc)) && (-e $inc) && files_exist($inc, @hdrstofind)) {
        print "  ODBC INC dir set to $inc from iodbc-config\n";
        $found_hdrs++;
    } elsif (-e $home) {
        # try with --prefix + include
        $inc = File::Spec->catdir($home, 'include');
        if (defined($inc) && (-e $inc) && files_exist($inc, @hdrstofind)) {
            print "  ODBC INC dir set to $inc from iodbc_config\n";
            $found_hdrs++;
        }
    }
    if (!$found_hdrs) {
        print "  but cannot find header files " . join(',', @hdrstofind) .
            " in that path so ignoring\n";
        print "NOTE: Have you installed the libiodbc-dev package.\n";
        return;
    }

    if (-e $lib) {
        print "  ODBC LIB dir set to $lib from iodbc_config/lib\n";
    } else {
        print "  but cannot find liob dir so ignoring\n";
        return;
    }

    return ('iodbc', $iodbc_config_v, $home, $inc, $lib);
}

#
# Try and find ODBC driver manager header files in general areas
#
sub find_dm_hdr_files
{
    my ($home, $inc, $lib);

    my @hdrstofind = ('sql.h', 'sqlext.h', 'sqltypes.h');
    push @hdrstofind, 'sqlucode.h' if $opt_u;

    my @paths = ('/usr', '/usr/local', '/usr/pkg',
                 '/usr/local/easysoft/unixODBC');
    unshift @paths, $opt_o if $opt_o;
    unshift @paths, $ENV{ODBCHOME} if $ENV{ODBCHOME};

    foreach my $dir(@paths) {
        my $path = File::Spec->catdir($dir, 'include');
        print "  trying $path\n";
        if (files_exist($path, @hdrstofind)) {
            print "  Found " . join(', ', @hdrstofind) . " in $path\n";
            $home = $dir;
            return $home;
        }
    }
    print <<'EOT';

I cannot find driver manager header files. Perhaps you need to install the
unixodbc-dev package or the iodbc-dev package

EOT
    return;
}

sub find_iodbc
{
    my $home = shift;           # will be specified odbc home or one we've found

    my @dirs;
    # start with specified dir if there was one
    push @dirs, "$home/lib" if defined($opt_o) || defined($ENV{ODBCHOME});

    # look in perl's libspath as it is more likely to be compatible
    # (e.g., a lib64 dir)
    push @dirs, split(' ', $Config{libspath});
    # add found odbc home if not added already
    if (defined($opt_o) || defined($ENV{ODBCHOME})) {
        push @dirs, "$home";
        push @dirs, "$home/lib";
    }
    for my $d(@dirs) {
        print "  Looking for iODBC libs in $d\n";
        my @found;
        if (@found = glob "$d/libiodbc*") {
            print "    Found iODBC libs ", join(",", @found), " in $d\n";
            return ('iodbc', $d);
        }
    }
    return;
}

sub find_unixodbc
{
    my $home = shift;           # will be specified odbc home or one we've found

    my @dirs;
    # start with specified dir if there was one
    push @dirs, "$home/lib" if defined($opt_o) || defined($ENV{ODBCHOME});

    # look in perl's libspath as it is more likely to be compatible
    # (e.g., a lib64 dir)
    push @dirs, split(' ', $Config{libspath});
    # add found odbc home if not added already
    push @dirs, "$home/lib" if !defined($opt_o) && !defined($ENV{ODBCHOME});
    # for debian/ubuntu 12 thanks to Maestro(Geoff Darling, mitsi)  for finding:
    push @dirs, "/usr/lib/i386-linux-gnu/";

    for my $d(@dirs) {
        my @found;
        print "  Looking for unixODBC libs in $d\n";
        if (@found = glob "$d/libodbc*") {
            print "    Found unixODBC libs ", join(",", @found), " in $d\n";
            return ('unixodbc', $d);
        }
    }
    return;
}

# Following generates
# Useless use of private variable in void context at Makefile.PL
# but is required
no warnings 'void';
$rv;

# ====================================================================

package MY;

use strict;
use Config;
use English;

sub postamble {
    return DBI::DBD::dbd_postamble(@_);
}

sub const_cccmd {
    my $self = shift;
    local($_) = $self->SUPER::const_cccmd(@_);

    # inject the defined local ODBC before default include to ensure
    # the ODBC driver we want is first
    if ($OSNAME ne 'MSWin32') {
        s/-c/-c \$\(DEFINE\)/;
    }
    $_;
}
sub MY::post_constants {
    my ($self) = shift;

    '
# make Changes file available as installed pod docs "perldoc DBD::ODBC::Changes"
inst_libdbdodbc = ' . File::Spec->catdir($self->{INST_LIB}, 'DBD/ODBC') . '
changes_pm = ' . File::Spec->catfile($self->{INST_LIB}, 'DBD/ODBC', 'Changes.pm') . '

# make FAQ file available as installed pod docs "perldoc DBD::ODBC::FAQ"
inst_libdbdodbc = ' . File::Spec->catdir($self->{INST_LIB}, 'DBD/ODBC') . '
faq_pm = ' . File::Spec->catfile($self->{INST_LIB}, 'DBD/ODBC', 'FAQ.pm') . '

# make TO_DO file available as installed pod docs "perldoc DBD::ODBC::TO_DO"
inst_libdbdodbc = ' . File::Spec->catdir($self->{INST_LIB}, 'DBD/ODBC') . '
todo_pm = ' . File::Spec->catfile($self->{INST_LIB}, 'DBD/ODBC', 'TO_DO.pm') . '

config :: $(changes_pm) $(faq_pm) $(todo_pm)
	@$(NOOP)

$(changes_pm): Changes
	$(NOECHO) $(MKPATH) $(inst_libdbdodbc)
	$(NOECHO) $(RM_F) $(changes_pm)
	$(CP) Changes $(changes_pm)

$(faq_pm): FAQ
	$(NOECHO) $(MKPATH) $(inst_libdbdodbc)
	$(NOECHO) $(RM_F) $(faq_pm)
	$(CP) FAQ $(faq_pm)

$(todo_pm): TO_DO
	$(NOECHO) $(MKPATH) $(inst_libdbdodbc)
	$(NOECHO) $(RM_F) $(todo_pm)
	$(CP) TO_DO $(todo_pm)
';

}

sub constants {
    my $self = shift;
    require DBI::DBD;

    # The problem with stawberry perl is it sets INC on the command line
    # and that overrides INC in this Makefile unless we set it here.
    my $old_constants = $self->SUPER::constants();
    my $new_constants;
    foreach my $line ( split(/\n/, $old_constants) ) {
        if ( $line =~ /^INC = .*strawberry.*/ ) {
            print qq(Strawberry Perl found; adjusting the INC variable;\n);
            $line = $line . q( -I) .  DBI::DBD::dbd_dbi_arch_dir();
            print qq(INC is now $line\n);
        }
        $new_constants .= $line . qq(\n);
    }
    return $new_constants;
}

# end.
