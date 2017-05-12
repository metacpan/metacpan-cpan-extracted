# This Makefile is for the Mac::DtfSQL extension to perl.
#
# It was generated automatically by MakeMaker version
# 0.3201 (Revision: ) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#   ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker Parameters:

# DEFINE => q[-d DTFMAC]
# DISTNAME => q[DBD-DtfSQLmac]
# INC => q[-i MacintoshHD:dtF_SQL:Includes:]
# LINKTYPE => q[static dynamic]
# NAME => q[Mac::DtfSQL]
# TYPEMAPS => q[:typemap :perlobject.map]
# VERSION_FROM => q[DtfSQL.pm]

# --- MakeMaker constants section:
NAME = Mac::DtfSQL
DISTNAME = DBD-DtfSQLmac
NAME_SYM = Mac_DtfSQL
VERSION = 0.3201
VERSION_SYM = 0_3201
XS_VERSION = 0.3201
INST_LIB = :::lib
INST_ARCHLIB = :::lib
PERL_LIB = :::lib
PERL_SRC = :::
MACPERL_SRC = :::macos:
MACPERL_LIB = :::macos:lib
PERL = :::miniperl
FULLPERL = :::perl
SOURCE =  DtfSQL.c
TYPEMAPS = :typemap :perlobject.map

MODULES = :lib:DBD:DtfSQLmac.pm \
	DtfSQL.pm
PMLIBDIRS = lib


.INCLUDE : $(MACPERL_SRC)BuildRules.mk


VERSION_MACRO = VERSION
DEFINE_VERSION = -d $(VERSION_MACRO)="¶"$(VERSION)¶""
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -d $(XS_VERSION_MACRO)="¶"$(XS_VERSION)¶""

MAKEMAKER = MacintoshHD:macperl_src:perl:lib:ExtUtils:MakeMaker.pm
MM_VERSION = 5.45

# FULLEXT = Pathname for extension directory (eg DBD:Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT (eg DBD)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = Mac:DtfSQL
BASEEXT = DtfSQL
ROOTEXT = Mac:
DEFINE = -d DTFMAC $(XS_DEFINE_VERSION) $(DEFINE_VERSION)
INC = -i MacintoshHD:dtF_SQL:Includes:

# Handy lists of source code files:
XS_FILES= DtfSQL.xs
C_FILES = DtfSQL.c
H_FILES = 


.INCLUDE : $(MACPERL_SRC)ExtBuildRules.mk


# --- MakeMaker dlsyms section:

dynamic :: DtfSQL.exp


DtfSQL.exp: Makefile.PL
	$(PERL) "-I$(PERL_LIB)" -e 'use ExtUtils::Mksymlists; Mksymlists("NAME" => "Mac::DtfSQL", "DL_FUNCS" => {  }, "DL_VARS" => []);'


# --- MakeMaker dynamic section:

all :: dynamic

install :: do_install_dynamic

install_dynamic :: do_install_dynamic


# --- MakeMaker static section:

all :: static

install :: do_install_static

install_static :: do_install_static


# --- MakeMaker htmlifypods section:

htmlifypods : pure_all
	$(NOOP)


# --- MakeMaker processPL section:


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	$(RM_RF) DtfSQL.c
	$(MV) Makefile.mk Makefile.mk.old


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	$(RM_RF) Makefile.mk Makefile.mk.old


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd:
	@$(PERL) -e "print qq{<SOFTPKG NAME=\"DBD-DtfSQLmac\" VERSION=\"0,2201,0,0\">\n}. qq{\t<TITLE>DBD-DtfSQLmac</TITLE>\n}. qq{\t<ABSTRACT></ABSTRACT>\n}. qq{\t<AUTHOR></AUTHOR>\n}. qq{\t<IMPLEMENTATION>\n}. qq{\t\t<OS NAME=\"$(OSNAME)\" />\n}. qq{\t\t<ARCHITECTURE NAME=\"\" />\n}. qq{\t\t<CODEBASE HREF=\"\" />\n}. qq{\t</IMPLEMENTATION>\n}. qq{</SOFTPKG>\n}" > DBD-DtfSQLmac.ppd

# --- MakeMaker postamble section:

# add this to list of MrC dynamic libs

DYNAMIC_STDLIBS_MRC		+= "MacintoshHD:dtF_SQL:Libraries:dtFPPCSV2.8K.shlb" \
                           "MacintoshHD:macperl_src:Sfio_04Aug99:lib:sfio.MrC.Lib"



# --- MakeMaker rulez section:

install install_static install_dynamic :: 
	$(MACPERL_SRC)PerlInstall -l $(PERL_LIB)

.INCLUDE : $(MACPERL_SRC)BulkBuildRules.mk


# End.
