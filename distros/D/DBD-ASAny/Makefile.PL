# Makefile.PL for Adaptive Server Anywhere DBD driver

use ExtUtils::MakeMaker;
use Getopt::Long;

require 5.004;

use strict;

# This DBI must be installed before we can build a DBD.
# For those not using Dynamic loading this means building a
# new static perl in the DBI directory by saying 'make perl'
# and then using _that_ perl to make this one.
use DBI;
use DBI::DBD;	# DBD creation tools
use Config;
if( $Config{osname} eq "MSWin32" ) {
    eval 'use Win32::Registry;';
}

my $dbi_dir      = dbd_dbi_dir();
my $dbi_arch_dir = dbd_dbi_arch_dir();
my $os = $^O;
my $osvers = $Config{osvers};
my $max_asa_ver = 9;
my $min_asa_ver = 6;
my $perl_bitness = $Config{ptrsize} * 8;
$osvers =~ s/^\s*(\d+\.\d+).*/$1/;	# drop sub-sub-version: 2.5.1 -> 2.5

my %opts = (
    NAME => 'DBD::ASAny',
    VERSION_FROM => 'ASAny.pm',
    OBJECT => 'ASAny.o dbdimp.o',
    clean => {	FILES=> 'ASAny.xsi' },
    dist  => {	DIST_DEFAULT	=> 'clean distcheck disttest ci tardist',
		PREOP		=> '$(MAKE) -f Makefile.old distdir',
		COMPRESS	=> 'gzip -v9', SUFFIX => 'gz',
    },
);
if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{AUTHOR} = 'Tim Bunce and John Smirnios (smirnios@sybase.com)';
    $opts{ABSTRACT} = 'Adaptive Server Anywhere DBD driver';
    $opts{PREREQ_PM} = { DBI => 0 };
    $opts{CAPI} = 'TRUE' if $Config{archname} =~ /-object\b/i;
}

$opts{LINKTYPE} = 'static' if $Config{dlsrc} =~ /dl_none/;

# Options (rarely needed)
$::opt_g = '';	# enable debugging (-g for compiler and linker)

GetOptions(qw(g!))
	or die "Invalid arguments";

$::opt_g &&= '-g';	# convert to actual string

# --- Introduction

print "\nConfiguring DBD::ASAny ...\n";

# --- Where is ASA installed...

my $sqlpp_platform;

if( $Config{osname} eq "MSWin32" ) {
    $sqlpp_platform = "WINNT";
} elsif( $Config{ptrsize} == 8 ) {
    $sqlpp_platform = "UNIX64";
} else {
    $sqlpp_platform = "UNIX";
}

my @install_dirs;

if( defined $ENV{ASANY} ) {
    push( @install_dirs, $ENV{ASANY} );
}

my $location;
my $key;
my $type;
my $ver;
if( $Config{osname} eq "MSWin32" ) {
    for( $ver=$max_asa_ver; $ver >= $min_asa_ver; $ver-- ) {
	if( defined $ENV{"ASANY${ver}"} ) {
	    push( @install_dirs, $ENV{"ASANY${ver}"} );
	}
	if( $main::HKEY_CURRENT_USER->Open( "Software\\Sybase\\Adaptive Server Anywhere\\${ver}.0", $key ) ) {
	    if( $key->QueryValueEx( 'Location', $type, $location ) ) {
		push( @install_dirs, $location );
	    }
	    $key->Close();
	}
	if( $main::HKEY_LOCAL_MACHINE->Open( "SOFTWARE\\Sybase\\Adaptive Server Anywhere\\${ver}.0", $key ) ) {
	    if( $key->QueryValueEx( 'Location', $type, $location ) ) {
		push( @install_dirs, $location );
	    }
	    $key->Close();
	}
    }
} else {
    for( $ver=$max_asa_ver; $ver >= $min_asa_ver; $ver-- ) {
	if( defined $ENV{"ASANY${ver}"} ) {
	    push( @install_dirs, $ENV{"ASANY${ver}"} );
	}
	push( @install_dirs, "/opt/sybase/SYBSsa$ver" );
	push( @install_dirs, "/opt/sybase/SYBSasa$ver" );
	push( @install_dirs, "/opt/SYBSsa$ver" );
	push( @install_dirs, "/opt/SYBSasa$ver" );
    }
}

my $ASA = "";
my $asa_version_major = "";
my $dir;
my $found = 0;

foreach $dir ( @install_dirs ) {
    next if $dir eq "";

    if( $Config{osname} eq "MSWin32" ) {
	if( -d "${dir}/win32/lib" &&
	    -d "${dir}/h" ) {
	    for( $ver=$max_asa_ver; $ver >= $min_asa_ver; $ver-- ) {
		if( -e "${dir}/win32/dbeng${ver}.exe" ) {
		    $ASA = $dir;
		    $asa_version_major = $ver;
		    $found = 1;
		    last;
		}
	    }
	}
    } else {
	if( ( -d "${dir}/lib" || -d "${dir}/lib32" || -d "${dir}/lib64" ) &&
	    ( -d "${dir}/bin" || -d "${dir}/bin32" || -d "${dir}/bin64" ) &&
	    -d "${dir}/include" ) {
	    for( $ver=$max_asa_ver; $ver >= $min_asa_ver; $ver-- ) {
		if( -e "${dir}/bin/dbeng${ver}" ||
		    -e "${dir}/bin32/dbeng${ver}" ||
		    -e "${dir}/bin64/dbeng${ver}" ) {
		    $ASA = $dir;
		    $asa_version_major = $ver;
		    $found = 1;
		    last;
		}
	    }
	}
    }
    last if $found;
}

if( !$found ) {
    die "** Unable to find Adaptiver Server Anywhere installation\n\n** Please set the ASANY environment variable.\n";
}

print "Using ASA version ${asa_version_major} in $ASA\n";

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

my $sysliblist;
my $libdir;
$sysliblist = "";
if( $Config{osname} eq "MSWin32" ) {
    if( $Config{archname} =~ /-x64-/ ) {
	$sysliblist .= qq( -L"$ASA/x64/lib" );
    } else {
	$sysliblist .= qq( -L"$ASA/win32/lib" );
    }
    $sysliblist .= qq( -L"$Config{archlibexp}/CORE" );
    foreach $libdir ( split( /;/, $ENV{LIB} ) ) {
	$sysliblist .= qq( -L"$libdir" );
    }
    $sysliblist .= " -ldblibtm ";
} else {
    if( $asa_version_major >= 9 ) {
	$sysliblist .= "-L$ASA/lib${perl_bitness} ";
    } else {
	$sysliblist .= "-L$ASA/lib ";
    }
    
    $sysliblist .= "-L$Config{archlibexp}/CORE ";

    if( $Config{useithreads} ) {
	$sysliblist .= " -ldblib${asa_version_major}_r -ldbtasks${asa_version_major}_r";
    } else {
	$sysliblist .= " -ldblib${asa_version_major} -ldbtasks${asa_version_major}";
    }
}

# On UNIX platforms, leave the perllib symbols unresolved and
# get them from the perl executable at runtime. Libperl.a is not
# built as relocatable code so linking against it now will leave
# relocations in a shared object which is forbidden on some
# platforms.
$opts{CCFLAGS} = $Config{ccflags};	
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
if( $Config{osname} eq "MSWin32" ) {
    $opts{INC}  = qq( -I"$ASA/h" );
    $opts{INC}  .= qq( -I"$dbi_arch_dir" );
    $opts{DEFINE} .= ' -DWINNT -D_CRT_SECURE_NO_DEPRECATE';
    $opts{LD} = "\$(PERL) dolink.pl \$@";
} else {
    $opts{INC}  = "-I$ASA/include ";
    $opts{INC}  .= "-I$dbi_arch_dir ";
    $opts{DEFINE} .= ' -DUNIX';
}
# $opts{OPTIMIZE}="-Zi";
# $opts{dynamic_lib}{OTHERLDFLAGS} .= ' -debug';

# uncomment log key platform information to help me help you quickly
print "System: perl$] @Config{qw(myuname archname dlsrc)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";

WriteMakefile(%opts);

exit 0;

sub MY::postamble {
    return( dbd_postamble(@_) .
"
dbdimp.c: dbdimp.sqc
	sqlpp -r -q -n -o ${sqlpp_platform} dbdimp.sqc dbdimp.c
" );
}

__END__
