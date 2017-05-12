# This Makefile is for the AudioCD extension to perl.
#
# It was generated automatically by MakeMaker version
# 0.20 (Revision: ) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#	ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker Parameters:

#	DEFINE => q[]
#	INC => q[]
#	LIBS => [q[]]
#	NAME => q[AudioCD]
#	VERSION_FROM => q[AudioCD.pm]
#	XSPROTOARG => q[-noprototypes]

# --- MakeMaker constants section:
NAME = AudioCD
DISTNAME = AudioCD
NAME_SYM = AudioCD
VERSION = 0.20
VERSION_SYM = 0_20
XS_VERSION = 0.20
INST_LIB = :::lib
INST_ARCHLIB = :::lib
PERL_LIB = :::lib
PERL_SRC = :::
PERL = :::miniperl
FULLPERL = :::perl
XSPROTOARG = -noprototypes

MODULES = AudioCD.pm


.INCLUDE : $(PERL_SRC)BuildRules.mk


# FULLEXT = Pathname for extension directory (eg DBD:Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT (eg DBD)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = AudioCD
BASEEXT = AudioCD
ROOTEXT = 

# Handy lists of source code files:
XS_FILES= 
C_FILES = 
H_FILES = 


.INCLUDE : $(PERL_SRC)ext:ExtBuildRules.mk


# --- MakeMaker dlsyms section:

dynamic :: AudioCD.exp


AudioCD.exp: Makefile.PL
	$(PERL) "-I$(PERL_LIB)" -e 'use ExtUtils::Mksymlists; Mksymlists("NAME" => "AudioCD", "DL_FUNCS" => {  }, "DL_VARS" => []);'


# --- MakeMaker dynamic section:

all :: dynamic

install :: do_install_dynamic

install_dynamic :: do_install_dynamic


# --- MakeMaker static section:

all :: static

install :: do_install_static

install_static :: do_install_static


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	Set OldEcho {Echo}
	Set Echo 0
	Directory Mac
	If "`Exists -f Makefile.mk`" != ""
	    $(MAKE) clean
	End
	Set Echo {OldEcho}
		$(RM_RF) 
	$(MV) Makefile.mk Makefile.mk.old


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	Set OldEcho {Echo}
	Set Echo 0
	Directory Mac
	If "`Exists -f Makefile.mk.old`" != ""
	    $(MAKE) realclean
	End
	Set Echo {OldEcho}
		Set OldEcho {Echo}
	Set Echo 0
	Directory Mac
	If "`Exists -f Makefile.mk`" != ""
	    $(MAKE) realclean
	End
	Set Echo {OldEcho}
		$(RM_RF) Makefile.mk Makefile.mk.old


# --- MakeMaker postamble section:


# --- MakeMaker rulez section:

install install_static install_dynamic :: 
	$(PERL_SRC)PerlInstall -l $(PERL_LIB)
	$(PERL_SRC)PerlInstall -l "Bird:MacPerl Ä:site_perl:"

.INCLUDE : $(PERL_SRC)BulkBuildRules.mk

# End.
