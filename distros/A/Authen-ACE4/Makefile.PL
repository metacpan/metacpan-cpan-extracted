# Makefile for Authen-ACE4
#
# Copyright C 2001-2002 Open System Consultants
# Author: Mike McCauley (mikem@open.com.au)
# $Id: Makefile.PL,v 1.3 2011/12/29 06:03:05 mikem Exp mikem $

use Config;

# On Unix, Set your ACE/Agent version number here. Version 4 has bugs and is deprecated
#$sd_version = 4;
#$sd_version = 5;
#$sd_version = 6;
$sd_version = 8;

print "Configuring for archname $Config{archname}\n";

my $exe = [];

# Adjust these paths to suit your system
if ($Config{archname} =~ /MSWin32/)
{
    # Windows. Assumes the SDK has been installed in C:\ACEAgentSDK
    if ($sd_version < 8)
    {
	$libs = ['-L"C:\Program Files\Microsoft Visual Studio\VC98\Lib" -LC:\ACEAgentSDK\lib\nt_i386 -laceclnt'];
	$inc = '-IC:\ACEAgentSDK\inc',
	$define = "-DSD_VERSION=$sd_version",
    }
    elsif ($sd_version == 8)
    {
	$libdir = 'C:\ACEAgentSDK\lib\32bit\nt\Release_MT';
	$libdir = 'C:\ACEAgentSDK\lib\64bit\nt\Release_MT' if $Config{archname} =~ /x64/;
	
	$libs = ["-L\"C:\\Program Files\\Microsoft Visual Studio\\VC98\\Lib\" -L$libdir -laceclnt"];
	# Make sure the required DLLs are here
	require File::Copy;
	my $to = '.';
	my $from = "$libdir\\aceclnt.dll";
	File::Copy::copy($from, $to) or die "Could not copy dll from $from to $to";
	my $from = "$libdir\\sdmsg.dll";
	File::Copy::copy($from, $to) or die "Could not copy dll from $from to $to";

	$inc = '-IC:\ACEAgentSDK\inc',
	$define = "-DSD_VERSION=$sd_version",
	$exe = ['aceclnt.dll', 'sdmsg.dll'],
    }
    else
    {
	die "unsupported Windows SDK version $sd_version";
    }
}
else
{
    # Unix. Make sure the paths here match the location where
    # you copied the ACEAgentSDK files.
    # Something like this for V 4.1
    # Note, on Solaris the ACE agent client libs that are supplied
    # with ACE/Server 4.1 hang in AceCloseAuth. You need	
    # a patched version of the libraries from SecurID.
    if ($sd_version == 4)
    {
	$acedir = '/opt/ace/ace4';
	$libs = ["-L$acedir/examples/multithread -laceclnt -lpthread"];
	$inc = "-I$acedir/examples/multithread -I$acedir/examples";
    }
    elsif ($sd_version == 5)
    {
	# For V 5.0:
	$acedir = '/opt/ace/ACEAgentSDK';
	$libs = ["-L$acedir/lib/sol -laceclnt -lpthread"];
	$inc = "-I$acedir/inc -I$acedir";
    }
    elsif ($sd_version == 6)
    {
	# For V 6.0:
	$acedir = '/opt/ace/ACEAgentSDK';
	$libs = ["-L$acedir/lib/sol -laceclnt -lpthread"];
	$libs = ["-L$acedir/lib/lnx -laceclnt"] if $Config{archname} =~ /linux/;
	$inc = "-I$acedir/inc";
    }
    elsif  ($sd_version == 8)
    {
	$acedir = '/opt/ace/ACEAgentSDK';
	if ($Config{archname} =~ /64/)
	{
	    $libs = ["-L$acedir/lib/64bit/sol_x86/release -laceclnt -lpthread"];
	    $libs = ["-L$acedir/lib/64bit/sparc/release -laceclnt -lpthread"] if $Config{archname} =~ /sun4/;
	    $libs = ["-L$acedir/lib/64bit/lnx/release -laceclnt"] if $Config{archname} =~ /linux/;
	}
	else
	{
	    $libs = ["-L$acedir/lib/32bit/sol_x86/release -laceclnt -lpthread"];
	    $libs = ["-L$acedir/lib/32bit/sparc/release -laceclnt -lpthread"] if $Config{archname} =~ /sun4/;
	    $libs = ["-L$acedir/lib/32bit/lnx/release -laceclnt"] if `uname` =~ /Linux/;
	}
	$inc = "-I$acedir/inc";
    }
    else
    {
	die "unsupported Unix SDK version $sd_version";
    }
    $define = "-DUNIX -DSD_VERSION=$sd_version",
}


use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'Authen::ACE4',
    'VERSION_FROM' => 'ACE4.pm',
    'LIBS'	   => $libs,
    'DEFINE'	   => $define,
    'INC'	   => $inc,
    'EXE_FILES'    => $exe,
    ($] ge '5.005') ? 
	       (
	        'AUTHOR'   => 'Open System Consultants, Mike McCauley (mikem@open.com.au)',
	        'ABSTRACT' => 'Access to SecurID ACE version 4 and up',
	        ) : (),
);


