# ***************************************************************************
# Copyright (c) 2015 SAP SE or an SAP affiliate company. All rights reserved.
# ***************************************************************************
# Makefile.PL for SQL Anywhere DBD driver

use ExtUtils::MakeMaker;
use Getopt::Long;
use File::Copy;

require 5.004;

use strict;

# This DBI must be installed before we can build a DBD.
# For those not using Dynamic loading this means building a
# new static perl in the DBI directory by saying 'make perl'
# and then using _that_ perl to make this one.
use DBI;
use DBI::DBD; # DBD creation tools
use Config;
if( $Config{osname} eq "MSWin32" ) {
    eval 'use Win32::Registry;';
}

my $dbi_dir      = dbd_dbi_dir();
my $dbi_arch_dir = dbd_dbi_arch_dir();
my $os = $^O;
my $osvers = $Config{osvers};
my $osarch = $Config{archname};
my $max_sqlanywhere_ver = 15;
my $min_sqlanywhere_ver = 10;
my $perl_bitness = $Config{ptrsize} * 8;
my $threaded = $Config{useithreads};

my $threadext = '';
$threadext = '_r' if $threaded;

$osvers =~ s/^\s*(\d+\.\d+).*/$1/;	# drop sub-sub-version: 2.5.1 -> 2.5

my $so_ext = 'so';
$so_ext = 'dll' if $os eq 'MSWin32';
$so_ext = 'dylib' if $os eq 'darwin';
$so_ext = 'sl' if $os eq 'hpux' && $osarch =~ /^PA-RISC/;

my %opts = (
    NAME => 'DBD::SQLAnywhere',
    VERSION_FROM => 'SQLAnywhere.pm',
    OBJECT => 'SQLAnywhere.o dbdimp.o sacapidll.o',
    clean => {	FILES=> 'SQLAnywhere.xsi' },
    dist  => {	DIST_DEFAULT	=> 'clean distcheck disttest ci tardist',
		PREOP		=> '$(MAKE) -f Makefile.old distdir',
		COMPRESS	=> 'gzip -v9', SUFFIX => 'gz',
    },
    PM => { 'SQLAnywhere.pm' => '$(INST_LIBDIR)/SQLAnywhere.pm',
	    'lib/DBD/SQLAnywhere/GetInfo.pm' => 'blib/lib/DBD/SQLAnywhere/GetInfo.pm' },

    CONFIGURE_REQUIRES => { "DBI" => "1.51" },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{AUTHOR} = 'John Smirnios (john.smirnios@sap.com), Tim Bunce';
    $opts{ABSTRACT} = 'SQL Anywhere DBD driver';
    $opts{PREREQ_PM} = { DBI => 1.51, 'Test::Simple' => 0.41 };
    $opts{CAPI} = 'TRUE' if $Config{archname} =~ /-object\b/i;
}

$opts{LINKTYPE} = 'static' if $Config{dlsrc} =~ /dl_none/;

# Options (rarely needed)
$::opt_g = '';	# enable debugging (-g for compiler and linker)

GetOptions(qw(g!))
	or die "Invalid arguments";

$::opt_g &&= '-g';	# convert to actual string

# --- Introduction

print "\nConfiguring DBD::SQLAnywhere ...\n";
my $is_gcc;
if( "$Config{cc}" eq "gcc" ||
    "$Config{gccversion}" ne "" ) {
    $is_gcc = 1;
    printf( "Using GNU compiler\n" ); 
} else {
    $is_gcc = 0;
    printf( "Using non-GNU compiler %s\n", $Config{cc} ); 
}

my $perllib;
$perllib = $Config{libperl};
if( $Config{osname} ne "MSWin32" ) {
    $perllib =~ s/^lib//;
}
$perllib =~ s/\..*//;

# On UNIX platforms, leave the perllib symbols unresolved and
# get them from the perl executable at runtime. Libperl.a is not
# built as relocatable code so linking against it now will leave
# relocations in a shared object which is forbidden on some
# platforms.
$opts{CCFLAGS} = $Config{ccflags};
my $sysliblist;
if( $Config{osname} eq "MSWin32" ) {
    $sysliblist .= " -l${perllib}";
#    $opts{CCFLAGS} =~ s/-O1//;
     $opts{CCFLAGS} =~ s/-Gf\s*/-GF /;
} elsif( "$Config{osname}" eq "solaris" ) {
    $sysliblist .= " -lsocket -lnsl -lm -lc";
    if( $is_gcc ) {
#	$opts{dynamic_lib}{OTHERLDFLAGS} .= " -Wl,-z,defs";
    } else {
	$opts{CCFLAGS} .= " -xCC -g";
#	$opts{dynamic_lib}{OTHERLDFLAGS} .= " -z defs";
    }
} elsif( "$Config{osname}" eq "hpux" ) {
    if( ! $is_gcc ) {
	$opts{CCFLAGS} =~ s/-Aa\s*//;
    }
} elsif( "$Config{osname}" eq "aix" ) {
    if( ! $is_gcc ) {
	$opts{CCFLAGS} .= " -qcpluscmt"
    }
} 

if( $is_gcc ) {
#    $opts{dynamic_lib}{OTHERLDFLAGS} .= ' -shared';
}

$opts{LIBS} = [ $sysliblist ];
$opts{DEFINE} .= " -D_SACAPI_VERSION=2";
if( $Config{osname} eq "MSWin32" ) {
    $opts{INC}  .= qq( -I"$dbi_arch_dir" );
    $opts{DEFINE} .= ' -DWINNT -D_CRT_SECURE_NO_DEPRECATE';
# The following doesn't work if ActivePerl was built with MinGW (gcc)
# It was added so that a manifest would be added to the DLL when building with VS2005 but it
# doesn't seem to be needed anymore.
#    $opts{LD} = "\$(PERL) dolink.pl \$@";
} else {
    $opts{INC}  .= "-I$dbi_arch_dir ";
    $opts{DEFINE} .= ' -DUNIX';
}
#$opts{OPTIMIZE}="-Zi";
#$opts{dynamic_lib}{OTHERLDFLAGS} .= ' -debug';
#$opts{CCFLAGS} =~ s/-Ox //;

# uncomment log key platform information to help me help you quickly
print "System: perl$] @Config{qw(myuname archname dlsrc)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";

WriteMakefile(%opts);

exit 0;

sub MY::postamble {
    return( dbd_postamble(@_) );
}

__END__
