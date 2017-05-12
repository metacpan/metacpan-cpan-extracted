#!/usr/bin/perl -w

use strict;

#
# Perl program that *should* generate a list of duplicate symbols
# between DBD::Oracle and Oracle client library. It produces useful
# output as-is, but it's not a general solution as it forces a
# symbol in that isn't reported, and eliminates a bunch of symbols
# that can't be removed for one reason or another.

#
# This file may prove useful in the long run as a starting point, so
# I've included it.
#

my %unstrippable = map { $_ => 1 } qw( _OCIAttrGet
                                       _OCIAttrSet
                                       _OCIBindByName
                                       _OCIBindDynamic
                                       _OCIBreak
                                       _OCIDefineByPos
                                       _OCIDescribeAny
                                       _OCIDescriptorAlloc
                                       _OCIDescriptorFree
                                       _OCIEnvInit
                                       _OCIErrorGet
                                       _OCIHandleAlloc
                                       _OCIHandleFree
                                       _OCIInitialize
                                       _OCILobGetLength
                                       _OCILobFileClose
                                       _OCILobFileOpen
                                       _OCILobRead
                                       _OCILobTrim
                                       _OCILobWrite
                                       _OCIParamGet
                                       _OCIServerAttach
                                       _OCIServerDetach
                                       _OCISessionBegin
                                       _OCISessionEnd
                                       _OCIStmtExecute
                                       _OCIStmtFetch
                                       _OCIStmtPrepare
                                       _OCITransCommit
                                       _OCITransRollback
                                       __dyld_func_lookup
                                       _atoi
                                       _fprintf
                                       _fwrite
                                       _getenv
                                       _kgefac_
                                       _kgesec0
                                       _korfpoid
                                       _kotgtivn
                                       _kpgdcd
                                       _kpggGetPG
                                       _kpugsqlt
                                       _kpumfs
                                       _kpumgs
                                       _kpummLtsCtx
                                       _kpusc
                                       _kpuscn
                                       _kpuucf
                                       _kpuuch
                                       _lmsagbf
                                       _lmsaicmt
                                       _lstmup
                                       _ltsmxd
                                       _ltstidd
                                       _lxhLangEnv
                                       _lxhci2h
                                       _lxhnsize
                                       _lxlterm
                                       _lxsCnvCase
                                       _main
                                       _memcmp
                                       _memcpy
                                       _memset
                                       _ociepgoe
                                       _sprintf
                                       _strcasecmp
                                       _strcat
                                       _strchr
                                       _strcpy
                                       _strlen
                                       _strncpy
                                       _ttckpu
                                       _upiacp0
                                       _upigdl
                                       _upihst
                                       _upioep
                                       _upirtr
                                       _upirtrc
                                       dyld_func_lookup_pointer
                                       dyld_lazy_symbol_binding_entry_point
                                       dyld_stub_binding_helper );

print "_main\n";
#print "_dlsym\n";
#print "\n\n";

my %oracle;

open FH,'nm /Users/oracle/9iR2/orahome/lib/libclntsh.dylib.9.0 |';

while ( <FH> ) {
  unless ( /^\// || /^\n/ ) {
    s/...........(\w+)\n/$1/;
    $oracle{$_} = 1;
  }
} 

close FH;

open FH,'nm ../blib/arch/auto/DBD/Oracle/Oracle.bundle |';

while ( <FH> ) {
  unless ( /^\// || /^\n/ ) {
    s/...........(\w+)\n/$1/;
    if ( exists($oracle{$_}) && ! exists($unstrippable{$_}) ) {
      print "$_\n";
    }
  }
}

close FH;

