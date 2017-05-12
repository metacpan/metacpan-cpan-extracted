#
# MakeMaker file for the DB2 Administrative API
#
# $Id: Makefile.PL,v 165.2 2009/04/22 14:01:32 biersma Exp $
#

use Config;
use ExtUtils::MakeMaker;
use strict;

#
# DB2_VERSION will be 8.2, 9.1, 9.5, 9.7
#
# NOTE: support for V7.2 and V8.1 has been dropped in release 3.1; use
#       the older 3.0 release if you use theose older DB2 releases.
#
my $db2_version = $ENV{DB2_VERSION} || do {
    #
    # Exit with zero status to avoid warnings from CPAN testers
    #
    warn "Environment variable 'DB2_VERSION' not set\n";
    exit(0);
};

my ($db2_version_enum, @defines, %extra_args);

#
# Determine version enum
#
if ($db2_version =~ /^V8\.2/) {
    $db2_version_enum = 'db2Version822'; # Use 820 if running w/o FixPaks
} elsif ($db2_version =~ /^V9\.1/) {
    $db2_version_enum = 'db2Version900';
} elsif ($db2_version =~ /^V9\.5/) {
    $db2_version_enum = 'db2Version950';
} elsif ($db2_version =~ /^V9\.7/) {
    $db2_version_enum = 'db2Version970';
} else {
    die "Unsupported DB2 version '$db2_version'\n";
}
push @defines, "-DDB2_VERSION_ENUM=$db2_version_enum";

#
# Determine path.  We look at the following environment variables:
# - DB2PATH (common for Windows)
# - DB2DIR
# - DB2_HOME
# After that, we fall back to platform defaults (guesses)
#
# All this can be overridden by DB2_PREFIX for Morgan Stanley hacks,
# see below.
#
my $db2_path;
foreach my $env_var (qw(DB2PATH DB2DIR DB2_HOME)) {
    next unless (defined $ENV{$env_var} && -d $ENV{$env_var});
    print "Using \$$env_var to set DB2 location\n";
    $db2_path = $ENV{$env_var};
    last;
}
unless (defined $db2_path) {
    if ($db2_version =~ /^V8\./) {
        if ($^O eq 'linux' || $^O eq 'solaris') {
            $db2_path = "/opt/IBM/db2/V8.1";
        } elsif ($^O eq 'aix') {
            $db2_path = "/usr/opt/db2_08_01";
        }  else {
            die "unexpected V8.2 platform '$^O'";
        }
    } elsif ($db2_version =~ /^V9\.([157])/) {
        my $sub_release = $1;   # 1, 5 or 7
        if ($^O eq 'linux') {
            $db2_path = "/opt/ibm/db2/V9.$sub_release";
        } elsif ($^O eq 'solaris') {
            $db2_path = "/opt/IBM/db2/V9.$sub_release";
        } elsif ($^O eq 'aix') {
            $db2_path = "/usr/opt/db2_09_0$sub_release";
        } elsif ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
            $db2_path = "C:\\ibm\\sqllib";
        } elsif ($^O eq 'cygwin') {
            $db2_path = "/cygdrive/c/ibm/sqllib";
        } else {
            die "unexpected V9.$sub_release platform '$^O'";
        }
    } else {
        die "Unsupported DB2 version '$db2_version'\n";
    }
}

#
# This deals with a Morgan Stanley specific setup, where we install
# DB2 in a non-standard location and then make /opt/IBM/xxx link to
# it.  If $ENV{DB2_PREFIX} is set and resolves to a directory, use that
# as the db2path for compilation/installation.
#
# We also do some horrible link-time tricks.  Don't try this at home...
#
if ($ENV{DB2_PREFIX}) {
    $db2_path = $ENV{DB2_PREFIX};
    die "DB2_PREFIX path '$db2_path' invalid" unless (-d $db2_path);

    #
    # For DB2 V9.x, we have 'lib32' and 'lib64' but no 'lib'.
    #
    my $lib_pf = 'lib';
    if ($Config{use64bitall}) { # 64-bit perl
        $lib_pf = 'lib64';
    } else {                    # 32-bit perl
        if ($ENV{ID_EXEC} eq 'ia32.linux.2.6.glibc.2.3' ||
            $ENV{ID_EXEC} eq 'x86_64.linux.2.6.glibc.2.3' ||
            $ENV{ID_EXEC} eq 'x86_64.linux.2.6.glibc.2.5') {
            $extra_args{CCFLAGS} = '-m32';
            $lib_pf = 'lib32';
        } elsif ($ENV{ID_EXEC} eq 'sun4.sunos64.5.10') {
            $lib_pf = 'lib32';
        }
    }

    my $sysliblist = "-L$db2_path/$lib_pf -ldb2";
    my @db2libs = qw(db2install db2g11n db2locale db2osse
                     db2genreg db2trcapi db2dascmn db2osse_db2);
    if ( $Config{osname} =~ /linux/i ) {
        $extra_args{LDDLFLAGS} =
          "-shared -Wl,--enable-new-dtags -Wl,-rpath $db2_path/$lib_pf";
        if ($Config{use64bitall}) {     # 64-bit perl
        } elsif ($ENV{ID_EXEC} eq 'ia32.linux.2.6.glibc.2.3' ||
                 $ENV{ID_EXEC} eq 'x86_64.linux.2.6.glibc.2.3' ||
                 $ENV{ID_EXEC} eq 'x86_64.linux.2.6.glibc.2.5') {
            $extra_args{LDDLFLAGS} .= ' -m32';
        } else {
            $sysliblist .= ' -L/tmp -lcxa';     # Setup in Makefile.inner
        }
    } elsif ( $Config{osname} =~ /solaris/i ) {
        #$sysliblist = "-R$db2_path/lib $sysliblist";
    }
    $sysliblist .= ' ' .join(' ', map {"-l$_"} @db2libs);
    $extra_args{LIBS} = [ $sysliblist ];
}

#
# In version 8.2 (but not above), use the V8.2 version db2DbDirXXX
# functions to access the database directory.
#
if ($db2_version eq 'V8.2') {
    push @defines, "-DADMIN_API_HAVE_DB2DBDIR_V8";
}

#
# In version 9.1 and above, use the V9 version of the db2DbDirInfo
# structure and support XML for import/export
#
if ($db2_version ge 'V9.1') {
    push @defines, "-DADMIN_API_HAVE_DB2DBDIR_V9";
    push @defines, "-DADMIN_API_HAVE_EXPORT_XML";
    push @defines, "-DADMIN_API_HAVE_IMPORT_XML";
}

#
# In version 9.5 and above, use the LongActionString for import
# and load; support XML for load.
#
if ($db2_version ge 'V9.5') {
    push @defines, "-DADMIN_API_HAVE_IMPORT_LONG_ACTION";
    push @defines, "-DADMIN_API_HAVE_LOAD_LONG_ACTION";
    push @defines, "-DADMIN_API_HAVE_LOAD_XML";
}

#
# Platform/bit-ness issues:
# - On Unix, link to libdb2.so; on Windows, link to db2cli and db2api.
# - Use one of lib64/lib32/lib
#
my $libs = "-L$db2_path/lib -ldb2";  # Default
if ($^O eq 'MSWin32') {  # 32-bit Windows
    $libs = "-L\"$db2_path\\lib\" -ldb2cli -ldb2api";
} elsif ($^O eq 'MSWin64') {    # 64-bit Windows
    $libs = "-L\"$db2_path\\lib64\" -ldb2cli -ldb2api";
} elsif ($^O eq 'cygwin') {
    my $libdir = ($Config{use64bitall}) ? 'lib64' : 'lib32';
    $libs = "-L$db2_path/$libdir -ldb2cli -ldb2api";
} else {                        # Unix
    my $libdir = ($Config{use64bitall}) ? 'lib64' : 'lib32';
    if (-d "$db2_path/$libdir") {
        $libs = "-L$db2_path/$libdir -ldb2";
    }
}
#print "XXX: have libs '$libs'\n";


#
# The module depends on a heper file to translate constant names (like
# SQLMA_APPLICATIONS_ALL) to numeric values.  DB2 does not maintain
# binary compatibility for these values across major release, so we
# have to parse the include files at the current location and generate
# the file locally.
#
# Instead of passing in the base directory (which may contain blanks)
# as a parameter, force it through an environment variable.
#
$ENV{DB2PATH} = $db2_path;
if ($^O =~ /^MSWin/) {
    system("perl", "util\\parse_constants.pl");
} else {
    system("./util/parse_constants.pl");
}

WriteMakefile('NAME'         => 'DB2::Admin',
              'VERSION_FROM' => 'lib/DB2/Admin.pm',
              'PREREQ_PM'    => { 'Params::Validate' => '0.87',
                                  'Test::Simple'     => '0.62',
                                },
              'INC'          => "-I$db2_path/include",
              'LIBS'         => $libs,
              'DEFINE'       => "@defines",
              %extra_args,
             );
