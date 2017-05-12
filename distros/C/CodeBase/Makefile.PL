# @(#) Makefile.PL -- Perl5 CodeBase database interface Makefile template
# @(#) $Id: Makefile.PL,v 1.4 1999/08/10 09:46:39 andrew Exp $
# 
# Copyright (C) 1996-1999, Andrew Ford and Ford & Mason Ltd.  All rights reserved.
#
# You may distribute under the terms of the Perl "Artistic" License,
# as specified in the README file.


use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use Config;

# Determine the appropriate defines

push(@DEFINES, ("-DCB_ENABLE_TRACING"));		# Comment out to exclude tracing

# Optimize flags for the C compiler
$optimize = "-Wall ";

# 
#$mode = "prof+opt";
#$mode = "debug";
$mode = "opt";

my $cbincdir = '/usr/local/include/codebase6.4';
my $cblibdir = '/usr/local/lib';
my $libcb = 'cb64';


#my $cbdir = '/usr/local';
#my $libcb = 'cb64';


# At some point I need to autoprobe to see if the CodeBase library cn be found automatically
#$cbdir = prompt('Where is your CodeBase library and include file installed?', $cbdir);


# if (-f "$cbdir/libcb.a") {
#     $libdir = $cbdir;
# }
# else {
#     $libdir = "$cbdir/lib";
# }

# if (-f "$cbdir/d4all.h") {
#     $incdir = $cbdir;
# }
# else {
#     $incdir = "$cbdir/include";
# }


# If the following doesn't work for you, just set $optimize explicitly.

if ($mode =~ /prof/)
{
    $optimize .= '-pg';
    $optimize .= ' -O9 -funroll-loops' if $mode =~ /opt/;
}
elsif ($mode =~ /debug/)
{
    $optimize .= "-g";
    $optimize .= ' -O9 -funroll-loops' if $mode =~ /opt/;
}
else
{
    $optimize .= ' -O9 -funroll-loops -fomit-frame-pointer';
    $optimize .= ' -O9 -funroll-loops ';
}





$archname = $Config{"archname"};

# SVR4.2 needs "-DNEED_STRCASECMP"
if ($archname =~ /^i\d86-svr4$/)
{
    push(@DEFINES, ("-DNEED_STRCASECMP"));
}


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


WriteMakefile(
    'NAME'		=> 'CodeBase',
    'VERSION_FROM' 	=> 'CodeBase.pm', 		# finds $VERSION
    'LIBS'		=> ["-L$cblibdir -l$libcb -lc"], 		# SVR4 at least requires -lc
    'DEFINE'		=> join(" ", @DEFINES),
    'INC'		=> "-I$cbincdir",
    'NORECURS'		=> 1,
    'OPTIMIZE'		=> $optimize,
    INCLUDE_EXT		=> [],
#    'depend'		=> { "CodeBase.c" => "CodeBase-*.xsh" },
);


# CodeBase 5.1 and 6.x can be differentiated in that
# libcb.a will contain code4init
# nm libcb.a | grep 'T .*4init.*[Uu]ndo$'
#    00000240 T d4init_undo		# 5.1
#    000009fc T code4initUndo		# 6.4
# grep "#define[ \t]*S4VERSION" d4all.h
#    #define S4VERSION  5140
#    #define S4VERSION 6401
sub find_codebase {
    my $libfile = 'libcb.a';
    my $incfile = 'd4all.h';
    my @options;
    my($l, $i);
     
    if (-r ($l = "/usr/lib/$libfile") and -r ($i = "/usr/include/$incfile")) {
	push @options, [ $l, $i ];
    }
    if (-r ($l = "/usr/local/lib/$libfile") and -r ($i = "/usr/include/$incfile")) {
	push @options, [ $l, $i ];
    }
}
