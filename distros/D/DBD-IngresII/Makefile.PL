#!/usr/bin/env perl

# Copyright (c) 2012, 2013 Tomasz Konojacki
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

require 5.008_004;

use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;
use Getopt::Long;

use DBI;
use DBI::DBD;

# Detect compilers and operating systems
my $is_win32 = $Config{osname} eq 'MSWin32';
my $is_msvc = $Config{cc} =~ /cl/;
my $is_gcc = $Config{cc} =~ /gcc/;

# Die if there's no Ingres
unless ($ENV{II_SYSTEM}){
    die "\$II_SYSTEM is not present. Is Ingres installed?\n";
}

my $II_SYSTEM = $ENV{II_SYSTEM};
my $esqlc = qq{"$II_SYSTEM/ingres/bin/esqlc"};

# Options for MakeMaker

my %opts = (
    NAME          => 'DBD::IngresII',
    VERSION_FROM  => 'IngresII.pm',
    PREREQ_PM     => {
        DBI    => 0,
        Config => 0
    },
    LINKTYPE      => 'dynamic',
    AUTHOR        => 'Henrik Tougaard (htoug@cpan.org)',
    LICENSE       => 'perl',
    ABSTRACT_FROM => 'IngresII.pm',
    OBJECT        => 'IngresII$(OBJ_EXT) dbdimp$(OBJ_EXT)',
    META_MERGE    => {
         resources => {
             repository => 'http://code.xenu.tk/repos.cgi/dbd-ingresii'
         }
    },
    clean         => {
        FILES => 'dbdimp.c IngresII.h IngresII.sc IngresII.xsh'
    },
    depend        => {
          'dbdimp$(OBJ_EXT)'   => 'dbdimp.c IngresII.h',
		  'IngresII$(OBJ_EXT)' => 'IngresII.h',
    },
    macro         => {
        ESQLC    => $esqlc,
        ESQLCOPT => '-o.h -w -p'
    }
);

print "\nConfiguring DBD::IngresII...\n";

print qq{Found Ingres at : "$II_SYSTEM"\n};

my($ld_options, $cc_options);

if ($is_msvc && $is_win32) {
    $ld_options = qq{"$II_SYSTEM\\ingres\\lib\\libingres.lib"};
}
elsif ($is_win32) {
    $ld_options = qq{-L"$II_SYSTEM/ingres/lib" -lingres};
}
else {
    $ld_options = qq{-L"$II_SYSTEM/ingres/lib" -lingres -lrt};
}

# Inform linker about libs
$opts{LIBS} = [ $ld_options ];
$opts{dynamic_lib} = { OTHERLDFLAGS => " $ld_options" };

# MinGW requires libingres.a
if ($is_win32 && $is_gcc) {
    unless (-e "$II_SYSTEM\\ingres\\lib\\libingres.a") {
        die q{
You are using MSWin32 Perl with gcc compiler. You need libingres.a file,
which you can download from:
http://community.actian.com/wiki/Libingres.a_for_MinGW
Place it in $II_SYSTEM\\ingres\\lib and run DBD::IngresII installation again.
        }
    }
}

my $dbi_arch_dir = dbd_dbi_arch_dir();
$opts{'INC'} = qq{-I"$dbi_arch_dir"};

# Here we go
WriteMakefile(%opts);

# Rules for generation of dbdimp.c and IngresII.xsh
sub MY::postamble {
    my $driver_template = $dbi_arch_dir."/Driver.xst";

    return q[
dbdimp.c IngresII.h : dbdimp.sc IngresII.sh
	$(ESQLC) $(ESQLCOPT) dbdimp.sc

$(BASEEXT).xs: $(BASEEXT).xsh

$(BASEEXT).c: $(BASEEXT).xsh

DBI_DRIVER_TEMPLATE = ] . $driver_template . q[

$(BASEEXT).xsh: $(DBI_DRIVER_XST)
	$(PERL) -p -e "s/~DRIVER~/$(BASEEXT)/g" < $(DBI_DRIVER_TEMPLATE) > $(BASEEXT).xsh
];
}
