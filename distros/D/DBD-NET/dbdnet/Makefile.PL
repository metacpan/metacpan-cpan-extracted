#!/usr/bin/perl -sw
# $Id: Makefile.PL,v 1.1 1996/04/14 17:25:11 descarte Exp descarte $
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
# From an original by Tim Bunce
#
# Covered by GPL - License to be added!
#
# $Log: Makefile.PL,v $
# Revision 1.1  1996/04/14 17:25:11  descarte
# Initial revision
#

use ExtUtils::MakeMaker qw(&WriteMakefile $Verbose);
use Getopt::Std;
use Config;

use DBI;	# The DBI must be installed before we can build a DBD

%opts = (
    'NAME'    => 'DBD::NET',
    'VERSION' => '0.24',
);

# --- Where is Informix installed...

my $ID = $ENV{INFORMIXDIR};

$opts{LIBS} = [ $sysliblist ];
$opts{INC}  = "-I$Config{archlib}/DBI -I$Config{sitearch}/DBI";
$opts{OBJECT} = '$(O_FILES)';
$opts{macro} = { 'ESQL_LIB' => '$(INFORMIXDIR)/include' };

$opts{DEFINE} = '-Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align'
	    . ' -Wconversion -Wtraditional -Wpointer-arith'
	    . ' -Wcast-qual'
	if $Config{cc} eq 'gcc';	# Just me asking gcc to be paranoid.

$opts{DEFINE} .= ' -Xa' if $Config{cc} eq 'clcc';	# CenterLine CC

# log key platform information to help me help you quickly
print "System: perl$] @Config{qw(myuname archname dlsrc)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";

# Assorted hints - these should be move to a hints subdirectory
print "See README notes about SPARCompiler on Solaris\n"
    if -d "/opt/SUNWspro/bin" and $Config{osname} eq 'solaris';

print "\n";

WriteMakefile(%opts);

# Cleanly exit from the Makefile-build process

exit 0;

sub MY::clean {
    '
clean::
	rm -f *.o
	rm -f *.so
	rm -f Makefile.old
	rm -f pm_to_blib
	rm -rf blib
';
}

__END__
