##########################################################################
#                                                                        #
# (C) Copyright IBM Corporation 2001, 2013. All rights reserved.         #
#                                                                        #
# This program and the accompanying materials are made available under   #
# the terms of the Common Public License v1.0 which accompanies this     #
# distribution, and is also available at http://www.opensource.org       #
# Contributors:                                                          #
#                                                                        #
# William Spurlin - Initial version and framework                        #
#                                                                        #
# Xue-Dong Chen - Maintenance and defect fixes                           #
# Max Vohlken - Maintenance and defect fixes                             #
#                                                                        #
##########################################################################

use ExtUtils::MakeMaker;
use File::Basename;

BEGIN {
	# On Windows fix the Config.pm based on where ratlperl is installed.
	if($^O =~ /MSWin32/ || $^O =~ /Windows/) {
		eval "use Win32;";
		my $p = $^X;
		if(basename($p) =~ /^ratlperl(\.exe)?$/) {
			my $i = dirname($p);
			$i = Win32::GetShortPathName($i);
			my $modified = 0;
			my $conf;
			my @conf;
			my @conf_orig;
			for(@INC) {
				if(open(CONF, "$_/Config.pm")) {
					$conf = "$_/Config.pm";
					@conf_orig = <CONF>;
					close(CONF);
					@conf = @conf_orig;
					for(@conf) {
						if(s/\Q\public\ratlperl\5.8.6\nt_i386\E/$i/g) {
							$modified = 1;
						}
					}
				}
			}
			if($conf ne '' and $modified) {
				if(open(CONF, ">$conf")) {
					# If we are able to write to the Config.pm then save
					# a copy of the original as Config.pm.orig.
					if(open(CONF, ">$conf.orig")) {
						print CONF @conf_orig;
						close(CONF);
					}
					print CONF @conf;
					close(CONF);
				} else {
					print "Unable to fix incorrect settings in $conf: $!\n";
				}
			}
		}
	}
}

use Config;

# To override ExtUtils::MM_Unix methods:
# require packages SolarisInterposer(for  MY::subdirs ) 
# and Win32C_O (for MY::c_o).  Including these subs inline
# results in their evaluation at compile time and prohibits platform-selective
# overriding of these methods.
# "use" will not work here as it has an implicit "BEGIN".

my $os=$Config{osname};  #why not $^O ?

my $name=ClearCase::CtCmd;
my $ATRIA_ROOT=$ENV{ATRIA_ROOT}?$ENV{ATRIA_ROOT}:"/opt/rational/clearcase"; 
my $COMMON_ROOT=$ENV{COMMON_ROOT}?$ENV{COMMON_ROOT}:"/opt/rational/common"; 
my $cleartool = $ATRIA_ROOT.'/bin/cleartool';
$cleartool = 'cleartool' if($os =~ /MSWin32/ || $os =~ /Windows/);
my $osver;

# CtCmd can only be used with a 32-bit perl.
if($Config{ptrsize} != 4) {
	die("$^X is not a 32-bit application. $name is only supported with a 32-bit perl.\n");
}

die "Cannot find ClearCase 7.0 or higher or cannot find $cleartool" 
unless $ctver = CheckVer('cleartool',
		'7.0',
		$cleartool.' -ver',
		1
		);

my $has_atriacmi = 0;

# libatriacmi was added in 7.1.2.9 and 8.0.0.5.
if(CheckVer(
		'cleartool',
		'7.1.2.9',
		$cleartool.' -ver',
		1
	)
	&& ! CheckVer(
		'cleartool',
		'8.0',
		$cleartool.' -ver',
		1
	)
) {
	$has_atriacmi = 1;
}

if(CheckVer(
		'cleartool',
		'8.0.0.5',
		$cleartool.' -ver',
		1
	)
) {
	$has_atriacmi = 1;
}

if($has_atriacmi) {
	$atriacmi_libs = '-latriacmi -latriajson';
}

my %opts = (
	    'NAME'	=> $name,
	    'VERSION_FROM' => 'CtCmd.pm', # finds $VERSION
	    'LIBS' => "-L. -L$ATRIA_ROOT/shlib -L$COMMON_ROOT/shlib -latriacmdsyn -latriacmd -latriasumcmd -latriasum $atriacmi_libs -latriamsadm -latriacm -latriavob -latriaview -latriacm -latriadbrpc -latriaxdr -latriamvfs -latriatbs -latriaadm -latriacredmap -latriaks -lezrpc -lrpcsvc -latriaccfs -latriasquidad -latriasquidcore -latriamsadm -latriamsinfobase -latriamsinfovob"
	    );

$opts{LIBS} .= ' -latriasplit -latriamntrpc' unless($os =~ /MSWin32/ || $os =~ /Windows/);

if ($os =~ /solaris/){
	my($esp_str,$esp_ver,$flag_rd);
	my $default_compiler = $Config{cc};	
    if( $default_compiler =~ /gcc/ || $ENV{CC_CTCMD_GCC}){
	$default_compiler = "gcc";
	$opts{CC} = $default_compiler;
	$opts{LD} = $default_compiler;
	$opts{OPTIMIZE} = '-O';
	$esp_str="gcc version";
	$esp_ver='2.7';
	$flag_rd = ' -v 2>&1';
    }elsif($default_compiler =~ /cc/){
	$esp_str=q(WorkShop Compilers|Sun C);
	$esp_ver='4.2';
	$flag_rd = ' -V 2>&1';
    }else{
	die 'No default compiler';
    }
    if(-e '/usr/lib/libCrun.so.1'){
       if(!-e 'libCrun.so'){
	   if (!symlink('/usr/lib/libCrun.so.1','libCrun.so')){
	       die "/usr/lib/libCrun.so.1: $!";
	   }
       }
    }else{
	die 'No libCrun.so.1 exist on the lib path';
    }
    die 'Cannot find  '.$default_compiler.' -> Sun Workshop Compilers 5.0 or gcc'  
	unless CheckVer($esp_str,
			$esp_ver,
			$default_compiler.$flag_rd
			);
    die "CtCmd requires Solaris 2.7 or higher"
	unless CheckVer("SunOS",
			'5.7',
			'uname -sr'
			);
    $opts{LIBS} ="-L/usr/lib $opts{LIBS} -lratlssl -lc -lw -lCstd -lCrun";
    $opts{DEFINE}	= $opts{DEFINE}.'-DSVR4';
    $opts{INC}	= '-I. ';
    $opts{dynamic_lib} = { OTHERLDFLAGS => "-t -ucmdsyn_proc_table -R$ATRIA_ROOT/shlib -R$COMMON_ROOT/shlib"} ;
}elsif ($os =~ /linux/){
    $opts{LD} = $Config{ld};
    die 'Cannot find  '.$Config{cc}  
	unless CheckVer('version',
			'2.7',
			$Config{cc}.' -v 2>&1'
			) ||
	       CheckVer('version egcs-',
			'2.7',$Config{cc}.' -v 2>&1'
		       );
    my $bits = 32;
	$bits = 31 if($os =~ /390/);
	$opts{DEFINE}= $opts{DEFINE}." -m$bits -DATRIA_LINUX";
    $opts{INC}='-I. ';
    $opts{LIBS} ="-L/usr/lib -L/lib $opts{LIBS} -lc -lncurses"; 
    if ($Config{perl} =~ /ratlperl/ || $opts{LD} ne "ld") {
    $opts{dynamic_lib}={ OTHERLDFLAGS => 
			     " -m$bits -ucmdsyn_proc_table -Wl,-rpath,$ATRIA_ROOT/shlib -Wl,-rpath,$COMMON_ROOT/shlib"
		       };
    } else {
    $opts{dynamic_lib}={ OTHERLDFLAGS => 
                             " -ucmdsyn_proc_table -rpath $ATRIA_ROOT/shlib -rpath $COMMON_ROOT/shlib"
                       };
    }

}elsif  ($os =~ /hpux/){

    $osver = `uname -r`;chomp $osver;
    $osver =~ s/^[A-Z]\.//;print "OSVER $osver\n";
	$mach = `uname -m`; chomp $mach;
    if ($osver == 10.20){
	print "HPUX-10.20\n";
	$opts{LIBS} =  "$opts{LIBS} -lcurses -lM -lezrpc -lrpcsvc -lsec -lstd -lstream -lcl -lc -ldld";
	$opts{DEFINE}= $opts{DEFINE}.' -DATRIA_HPUX10';
	$opts{dynamic_lib}={ OTHERLDFLAGS => ' +b: -E -lCsup'};
    }elsif(11 <= $osver ){
		print "HPUX-11\n";
		if ($Config{perl} =~ /ratlperl/) {
			if($mach eq 'ia64') {
				$opts{LIBS} = "-L/usr/lib/hpux32 $opts{LIBS}";
			} else {
				$opts{LIBS} = "-L/usr/lib $opts{LIBS}";
			}
			$opts{LDFLAGS}=$Config{ldflags};
			$opts{LDFLAGS} =~ s!\-Wl,\+b!-Wl,+b${ATRIA_ROOT}/shlib:${COMMON_ROOT}/shlib:!g;
			$opts{LDDLFLAGS}=$Config{lddlflags};
			$opts{LDDLFLAGS} =~ s!\-Wl,\+b!-Wl,+b${ATRIA_ROOT}/shlib:${COMMON_ROOT}/shlib:!g;
		}else{
			#$opts{dynamic_lib}={ OTHERLDFLAGS => ' +b: -E -l:libcl.0  -l:libc.0 '};
		}
		$opts{LIBS} .= " -lc -lstd_v2 -lCsup -lcurses -lrpcsvc -lsec";
    }else{
    }    

}elsif  ($os =~ /MSWin32/ || $os =~ /Windows/){
    die 
	'Cannot find  '
	.$Config{cc}.
	' -> Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 12'  
		unless CheckVer('Version','12',$Config{cc}.' 2>&1' );
    $opts{CCFLAGS} = $Config{ccflags}.' -DATRIA_WIN32_COMMON';
	while($opts{LIBS} =~ /-l(atria[^ ]+)/g) {
		my $lib = $1;
		system($^X, 'autoDef', "win32/$lib.conf") 
		|| system($Config{'ar'}, '/nologo', '/machine:i386', "/def:$lib.def");
	}
    #$opts{LIBS}.=' /defaultlib:WS2_32.LIB';
    $opts{LDDLFLAGS}=$Config{lddlflags};
    $opts{LDDLFLAGS} =~ s/-nodefaultlib//;
    require 'Win32C_O';
}elsif ($os =~ /AIX/i){
	$opts{DEFINE}= $opts{DEFINE}.' -q32';
    $opts{LIBS} = "-L/usr/lib -L/lib $opts{LIBS} $Config{LIBS}";
    $opts{LDDLFLAGS} = $Config{lddlflags} ." -b32 -brtl -bshared ";
    $opts{LDDLFLAGS} =~ s/blibpath:/blibpath:$ATRIA_ROOT\/shlib:$COMMON_ROOT\/shlib:/;
	# The ClearCase libraries end in .so so to get the library search
	# mechanism in MakeMaker to work we need to change the lib_ext
	# value in the Config module from .a to .so.
	# $Config{lib_ext} is read-only so this is how I found to modify it.
	if(defined($Config::Config_SH_expanded) and $Config{lib_ext} eq '.a') {
		$Config::Config_SH_expanded =~ s/^lib_ext='[^']+/lib_ext='.so/m;
		# This updates %Config.
		tied(%Config::Config)->fetch_string('lib_ext');
	}
}else{print "Unsupported Platform\n"}

if($has_atriacmi) {
	$opts{DEFINE} .= ' -DATRIA_HAS_CMI';
}

WriteMakefile(%opts);

sub CheckVer{
    my $expected_string = shift;
    my $level = shift;
    my $prog_output = shift;
    my $trailing = shift;
    $prog_output = `$prog_output`;
    $prog_output =~ /$expected_string\s*(\d+(\.\d+){1,3})/i;
    $found_level = $1;
    @minversion = split('\.',$level);
#
# The output of the cleartool -ver command has changed.
# An earlier version looks like 2003.06.00 while a later version
# looks like 7.0.0.0   We need to be able to handle both styles. 
# The trailing flag means that the version trails the year so we
# need to remove the year.  That is no longer always true so we
# need to test to see if the year is first, if it is not the we
# have to turn off the trailing flag. 
    if($trailing){
    if($found_level !~ /200/) {
    $trailing = 0;
    }
    }

    if($trailing){
	$found_level =~ s/\d+\.(\d+\.\d+)/$1/;
    }
    @foundversion = split('\.',$found_level);
    my $ans = Found;
    $ans = 'Not Found' unless $1;
    print "Looking for $expected_string\t$level\t$ans\t$found_level\n";

    for ($i = 0; $i < @minversion; $i++)
        {
           if ($foundversion[$i] > $minversion[$i]){
                return  $found_level;
           }else{   
                if ($foundversion[$i] < $minversion[$i]){ 
                   return 0;
                }
           }
     }
     return  $found_level;
}


