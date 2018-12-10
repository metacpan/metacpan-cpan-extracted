# This Makefile is for the Alien::proj extension to perl.
#
# It was generated automatically by MakeMaker version
# 7.34 (Revision: 73400) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     ABSTRACT => q[Alien package for the PROJ library]
#     AUTHOR => [q[Shawn Laffan <shawnlaffan@gmail.com>]]
#     BUILD_REQUIRES => { Alien::Build=>q[1.41], Alien::Build::MM=>q[1.41], Alien::Build::Plugin::Cleanse::BuildDir=>q[0], Alien::MSYS=>q[0], ExtUtils::MakeMaker=>q[6.52], File::Find::Rule=>q[0], PkgConfig=>q[0.19026], Sort::Versions=>q[0] }
#     CONFIGURE_REQUIRES => { Alien::Build=>q[1.41], Alien::Build::MM=>q[1.41], Alien::Build::Plugin::Cleanse::BuildDir=>q[0], Alien::MSYS=>q[0], ExtUtils::MakeMaker=>q[6.52], File::Find::Rule=>q[0], PkgConfig=>q[0], Sort::Versions=>q[0] }
#     DISTNAME => q[Alien-proj]
#     LICENSE => q[perl]
#     META_MERGE => { dynamic_config=>q[1], meta-spec=>{ version=>q[2] }, resources=>{ bugtracker=>{ web=>q[https://github.com/shawnlaffan/perl-alien-proj4/issues/] }, repository=>{ type=>q[git], url=>q[https://github.com/shawnlaffan/perl-alien-proj4] } }, x_alienfile=>{ generated_by=>q[Alien::Build::MM version 1.49], requires=>{ share=>{ Alien::MSYS=>q[0.07], Archive::Tar=>q[0], HTML::LinkExtor=>q[0], HTTP::Tiny=>q[0.044], IO::Zlib=>q[0], Sort::Versions=>q[0], URI=>q[0], URI::Escape=>q[0] }, system=>{  } } } }
#     NAME => q[Alien::proj]
#     PREREQ_PM => { Alien::Base=>q[1.41], Alien::Build=>q[1.41], Alien::Build::MM=>q[1.41], Alien::Build::Plugin::Cleanse::BuildDir=>q[0], Alien::MSYS=>q[0], ExtUtils::MakeMaker=>q[6.52], FFI::CheckLib=>q[0.23], File::Find::Rule=>q[0], PkgConfig=>q[0.19026], Sort::Versions=>q[0], Test::Alien=>q[0] }
#     TEST_REQUIRES => { FFI::CheckLib=>q[0.23], Test::Alien=>q[0] }
#     VERSION_FROM => q[lib/Alien/proj.pm]

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

SHELL = C:\WINDOWS\system32\cmd.exe

# These definitions are from config.sh (via C:/berrybrew/5.28.0_64_PDL/perl/lib/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = gcc
CCCDLFLAGS =  
CCDLFLAGS =  
DLEXT = xs.dll
DLSRC = dl_win32.xs
EXE_EXT = .exe
FULL_AR = 
LD = g++.exe
LDDLFLAGS = -mdll -s -L"C:\berrybrew\5.28.0_64_PDL\perl\lib\CORE" -L"C:\berrybrew\5.28.0_64_PDL\c\lib"
LDFLAGS = -s -L"C:\berrybrew\5.28.0_64_PDL\perl\lib\CORE" -L"C:\berrybrew\5.28.0_64_PDL\c\lib"
LIBC = 
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = MSWin32
OSVERS = 10.0.17134.112
RANLIB = rem
SITELIBEXP = C:\berrybrew\5.28.0_64_PDL\perl\site\lib
SITEARCHEXP = C:\berrybrew\5.28.0_64_PDL\perl\site\lib
SO = dll
VENDORARCHEXP = C:\berrybrew\5.28.0_64_PDL\perl\vendor\lib
VENDORLIBEXP = C:\berrybrew\5.28.0_64_PDL\perl\vendor\lib


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = Alien::proj
NAME_SYM = Alien_proj
VERSION = 1.02
VERSION_MACRO = VERSION
VERSION_SYM = 1_02
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 1.02
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib\arch
INST_SCRIPT = blib\script
INST_BIN = blib\bin
INST_LIB = blib\lib
INST_MAN1DIR = blib\man1
INST_MAN3DIR = blib\man3
MAN1EXT = 1
MAN3EXT = 3
INSTALLDIRS = site
DESTDIR = 
PREFIX = $(SITEPREFIX)
PERLPREFIX = C:\berrybrew\5.28.0_64_PDL\perl
SITEPREFIX = C:\berrybrew\5.28.0_64_PDL\perl\site
VENDORPREFIX = C:\berrybrew\5.28.0_64_PDL\perl\vendor
INSTALLPRIVLIB = C:\berrybrew\5.28.0_64_PDL\perl\lib
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = C:\berrybrew\5.28.0_64_PDL\perl\site\lib
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = C:\berrybrew\5.28.0_64_PDL\perl\vendor\lib
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = C:\berrybrew\5.28.0_64_PDL\perl\lib
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = C:\berrybrew\5.28.0_64_PDL\perl\site\lib
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = C:\berrybrew\5.28.0_64_PDL\perl\vendor\lib
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = C:\berrybrew\5.28.0_64_PDL\perl\bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = C:\berrybrew\5.28.0_64_PDL\perl\site\bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = C:\berrybrew\5.28.0_64_PDL\perl\bin
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = C:\berrybrew\5.28.0_64_PDL\perl\bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = C:\berrybrew\5.28.0_64_PDL\perl\site\bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = C:\berrybrew\5.28.0_64_PDL\perl\bin
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = none
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = $(INSTALLMAN1DIR)
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = $(INSTALLMAN1DIR)
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = none
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = $(INSTALLMAN3DIR)
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = $(INSTALLMAN3DIR)
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB = C:\berrybrew\5.28.0_64_PDL\perl\lib
PERL_ARCHLIB = C:\berrybrew\5.28.0_64_PDL\perl\lib
PERL_ARCHLIBDEP = C:\berrybrew\5.28.0_64_PDL\perl\lib
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = C:\berrybrew\5.28.0_64_PDL\perl\lib\CORE
PERL_INCDEP = C:\berrybrew\5.28.0_64_PDL\perl\lib\CORE
PERL = "C:\berrybrew\5.28.0_64_PDL\perl\bin\perl.exe"
FULLPERL = "C:\berrybrew\5.28.0_64_PDL\perl\bin\perl.exe"
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = C:/berrybrew/5.28.0_64_PDL/perl/lib/ExtUtils/MakeMaker.pm
MM_VERSION  = 7.34
MM_REVISION = 73400

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = gmake
FULLEXT = Alien\proj
BASEEXT = proj
PARENT_NAME = Alien
DLBASE = $(BASEEXT)
VERSION_FROM = lib/Alien/proj.pm
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = 
MAN3PODS = 

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIBDEP)$(DFSEP)Config.pm $(PERL_INCDEP)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)\Alien
INST_ARCHLIBDIR  = $(INST_ARCHLIB)\Alien

INST_AUTODIR     = $(INST_LIB)\auto\$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)\auto\$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = $(BASEEXT).def
PERL_ARCHIVE       = $(PERL_INC)\libperl528.a
PERL_ARCHIVEDEP    = $(PERL_INCDEP)\libperl528.a
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/Alien/proj.pm


# --- MakeMaker platform_constants section:
MM_Win32_VERSION = 7.34


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e "use AutoSplit;  autosplit($$$$ARGV[0], $$$$ARGV[1], 0, 1, 1)" --



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
CHMOD = $(ABSPERLRUN) -MExtUtils::Command -e chmod --
CP = $(ABSPERLRUN) -MExtUtils::Command -e cp --
MV = $(ABSPERLRUN) -MExtUtils::Command -e mv --
NOOP = rem
NOECHO = @
RM_F = $(ABSPERLRUN) -MExtUtils::Command -e rm_f --
RM_RF = $(ABSPERLRUN) -MExtUtils::Command -e rm_rf --
TEST_F = $(ABSPERLRUN) -MExtUtils::Command -e test_f --
TOUCH = $(ABSPERLRUN) -MExtUtils::Command -e touch --
UMASK_NULL = umask 0
DEV_NULL = > NUL
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e mkpath --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e eqtime --
FALSE = $(ABSPERLRUN)  -e "exit 1" --
TRUE = $(ABSPERLRUN)  -e "exit 0" --
ECHO = $(ABSPERLRUN) -l -e "binmode STDOUT, qq{:raw}; print qq{@ARGV}" --
ECHO_N = $(ABSPERLRUN)  -e "print qq{@ARGV}" --
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e "install([ from_to => {@ARGV}, verbose => '$(VERBINST)', uninstall_shadows => '$(UNINST)', dir_mode => '$(PERM_DIR)' ]);" --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e perllocal_install --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e uninstall --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e warn_if_old_packlist --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = pl2bat.bat
CP_NONEMPTY = $(ABSPERLRUN) -MExtUtils::Command::MM -e cp_nonempty --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip --best
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = Alien-proj
DISTVNAME = Alien-proj-1.02


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"\
	PASTHRU_DEFINE="$(DEFINE) $(PASTHRU_DEFINE)"\
	PASTHRU_INC="$(INC) $(PASTHRU_INC)"


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir pure_all subdirs clean_subdirs makemakerdflt manifypods realclean_subdirs subdirs_dynamic subdirs_pure_nolink subdirs_static subdirs-test_dynamic subdirs-test_static test_dynamic test_static



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all
	$(NOECHO) $(NOOP)

pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

help :
	perldoc ExtUtils::MakeMaker


# --- MakeMaker blibdirs section:
blibdirs : $(INST_LIBDIR)$(DFSEP).exists $(INST_ARCHLIB)$(DFSEP).exists $(INST_AUTODIR)$(DFSEP).exists $(INST_ARCHAUTODIR)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists $(INST_SCRIPT)$(DFSEP).exists $(INST_MAN1DIR)$(DFSEP).exists $(INST_MAN3DIR)$(DFSEP).exists
	$(NOECHO) $(NOOP)

# Backwards compat with 6.18 through 6.25
blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

$(INST_LIBDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_LIBDIR)
	$(NOECHO) $(TOUCH) $(INST_LIBDIR)$(DFSEP).exists

$(INST_ARCHLIB)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIB)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIB)
	$(NOECHO) $(TOUCH) $(INST_ARCHLIB)$(DFSEP).exists

$(INST_AUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_AUTODIR)
	$(NOECHO) $(TOUCH) $(INST_AUTODIR)$(DFSEP).exists

$(INST_ARCHAUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHAUTODIR)
	$(NOECHO) $(TOUCH) $(INST_ARCHAUTODIR)$(DFSEP).exists

$(INST_BIN)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_BIN)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_BIN)
	$(NOECHO) $(TOUCH) $(INST_BIN)$(DFSEP).exists

$(INST_SCRIPT)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_SCRIPT)
	$(NOECHO) $(TOUCH) $(INST_SCRIPT)$(DFSEP).exists

$(INST_MAN1DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN1DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN1DIR)$(DFSEP).exists

$(INST_MAN3DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN3DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN3DIR)$(DFSEP).exists



# --- MakeMaker linkext section:

linkext :: dynamic
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:

proj.def: Makefile.PL
	$(PERLRUN) -MExtUtils::Mksymlists \
     -e "Mksymlists('NAME'=>\"Alien::proj\", 'DLBASE' => '$(BASEEXT)', 'DL_FUNCS' => {  }, 'FUNCLIST' => [], 'IMPORTS' => {  }, 'DL_VARS' => []);"


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) config $(INST_BOOT) $(INST_DYNAMIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all config 
	$(NOECHO) $(NOOP)




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	- $(RM_F) \
	  $(BASEEXT).bso $(BASEEXT).def \
	  $(BASEEXT).exp $(BASEEXT).x \
	  $(BOOTSTRAP) $(INST_ARCHAUTODIR)\extralibs.all \
	  $(INST_ARCHAUTODIR)\extralibs.ld $(MAKE_APERL_FILE) \
	  *$(LIB_EXT) *$(OBJ_EXT) \
	  *perl.core MYMETA.json \
	  MYMETA.yml blibdirs.ts \
	  core core.*perl.*.? \
	  core.[0-9] core.[0-9][0-9] \
	  core.[0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9] \
	  core.[0-9][0-9][0-9][0-9][0-9] lib$(BASEEXT).def \
	  mon.out perl \
	  perl$(EXE_EXT) perl.exe \
	  perlmain.c pm_to_blib \
	  pm_to_blib.ts so_locations \
	  tmon.out 
	- $(RM_RF) \
	  blib dll.base \
	  dll.exp 
	  $(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
# so clean is forced to complete before realclean_subdirs runs
realclean_subdirs : clean
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge :: realclean_subdirs
	- $(RM_F) \
	  $(FIRST_MAKEFILE) $(MAKEFILE_OLD) 
	- $(RM_RF) \
	  $(DISTVNAME) 


# --- MakeMaker metafile section:
metafile : create_distdir
	$(NOECHO) $(ECHO) Generating META.yml
	$(NOECHO) $(ECHO) --- > META_new.yml
	$(NOECHO) $(ECHO) "abstract: 'Alien package for the PROJ library'" >> META_new.yml
	$(NOECHO) $(ECHO) author: >> META_new.yml
	$(NOECHO) $(ECHO) "  - 'Shawn Laffan <shawnlaffan@gmail.com>'" >> META_new.yml
	$(NOECHO) $(ECHO) build_requires: >> META_new.yml
	$(NOECHO) $(ECHO) "  Alien::Build: '1.41'" >> META_new.yml
	$(NOECHO) $(ECHO) "  Alien::Build::MM: '1.41'" >> META_new.yml
	$(NOECHO) $(ECHO) "  Alien::Build::Plugin::Cleanse::BuildDir: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "  Alien::MSYS: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "  ExtUtils::MakeMaker: '6.52'" >> META_new.yml
	$(NOECHO) $(ECHO) "  FFI::CheckLib: '0.23'" >> META_new.yml
	$(NOECHO) $(ECHO) "  File::Find::Rule: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "  PkgConfig: '0.19026'" >> META_new.yml
	$(NOECHO) $(ECHO) "  Sort::Versions: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "  Test::Alien: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) configure_requires: >> META_new.yml
	$(NOECHO) $(ECHO) "  Alien::Build: '1.41'" >> META_new.yml
	$(NOECHO) $(ECHO) "  Alien::Build::MM: '1.41'" >> META_new.yml
	$(NOECHO) $(ECHO) "  Alien::Build::Plugin::Cleanse::BuildDir: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "  Alien::MSYS: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "  ExtUtils::MakeMaker: '6.52'" >> META_new.yml
	$(NOECHO) $(ECHO) "  File::Find::Rule: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "  PkgConfig: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "  Sort::Versions: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "dynamic_config: 1" >> META_new.yml
	$(NOECHO) $(ECHO) "generated_by: 'ExtUtils::MakeMaker version 7.34, CPAN::Meta::Converter version 2.150010'" >> META_new.yml
	$(NOECHO) $(ECHO) "license: perl" >> META_new.yml
	$(NOECHO) $(ECHO) meta-spec: >> META_new.yml
	$(NOECHO) $(ECHO) "  url: http://module-build.sourceforge.net/META-spec-v1.4.html" >> META_new.yml
	$(NOECHO) $(ECHO) "  version: '1.4'" >> META_new.yml
	$(NOECHO) $(ECHO) "name: Alien-proj" >> META_new.yml
	$(NOECHO) $(ECHO) no_index: >> META_new.yml
	$(NOECHO) $(ECHO) "  directory:" >> META_new.yml
	$(NOECHO) $(ECHO) "    - t" >> META_new.yml
	$(NOECHO) $(ECHO) "    - inc" >> META_new.yml
	$(NOECHO) $(ECHO) requires: >> META_new.yml
	$(NOECHO) $(ECHO) "  Alien::Base: '1.41'" >> META_new.yml
	$(NOECHO) $(ECHO) "  Alien::Build: '0.25'" >> META_new.yml
	$(NOECHO) $(ECHO) "  FFI::CheckLib: '0.23'" >> META_new.yml
	$(NOECHO) $(ECHO) resources: >> META_new.yml
	$(NOECHO) $(ECHO) "  bugtracker: https://github.com/shawnlaffan/perl-alien-proj4/issues/" >> META_new.yml
	$(NOECHO) $(ECHO) "  repository: https://github.com/shawnlaffan/perl-alien-proj4" >> META_new.yml
	$(NOECHO) $(ECHO) "version: '1.02'" >> META_new.yml
	$(NOECHO) $(ECHO) x_alienfile: >> META_new.yml
	$(NOECHO) $(ECHO) "  generated_by: 'Alien::Build::MM version 1.49'" >> META_new.yml
	$(NOECHO) $(ECHO) "  requires:" >> META_new.yml
	$(NOECHO) $(ECHO) "    share:" >> META_new.yml
	$(NOECHO) $(ECHO) "      Alien::MSYS: '0.07'" >> META_new.yml
	$(NOECHO) $(ECHO) "      Archive::Tar: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "      HTML::LinkExtor: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "      HTTP::Tiny: '0.044'" >> META_new.yml
	$(NOECHO) $(ECHO) "      IO::Zlib: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "      Sort::Versions: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "      URI: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "      URI::Escape: '0'" >> META_new.yml
	$(NOECHO) $(ECHO) "    system: {}" >> META_new.yml
	$(NOECHO) $(ECHO) "x_serialization_backend: 'CPAN::Meta::YAML version 0.018'" >> META_new.yml
	-$(NOECHO) $(MV) META_new.yml $(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) Generating META.json
	$(NOECHO) $(ECHO) { > META_new.json
	$(NOECHO) $(ECHO) "   \"abstract\" : \"Alien package for the PROJ library\"," >> META_new.json
	$(NOECHO) $(ECHO) "   \"author\" : [" >> META_new.json
	$(NOECHO) $(ECHO) "      \"Shawn Laffan ^<shawnlaffan^@gmail.com^>\"" >> META_new.json
	$(NOECHO) $(ECHO) "   ]," >> META_new.json
	$(NOECHO) $(ECHO) "   \"dynamic_config\" : 1," >> META_new.json
	$(NOECHO) $(ECHO) "   \"generated_by\" : \"ExtUtils::MakeMaker version 7.34, CPAN::Meta::Converter version 2.150010\"," >> META_new.json
	$(NOECHO) $(ECHO) "   \"license\" : [" >> META_new.json
	$(NOECHO) $(ECHO) "      \"perl_5\"" >> META_new.json
	$(NOECHO) $(ECHO) "   ]," >> META_new.json
	$(NOECHO) $(ECHO) "   \"meta-spec\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "      \"url\" : \"http://search.cpan.org/perldoc?CPAN::Meta::Spec\"," >> META_new.json
	$(NOECHO) $(ECHO) "      \"version\" : 2" >> META_new.json
	$(NOECHO) $(ECHO) "   }," >> META_new.json
	$(NOECHO) $(ECHO) "   \"name\" : \"Alien-proj\"," >> META_new.json
	$(NOECHO) $(ECHO) "   \"no_index\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "      \"directory\" : [" >> META_new.json
	$(NOECHO) $(ECHO) "         \"t\"," >> META_new.json
	$(NOECHO) $(ECHO) "         \"inc\"" >> META_new.json
	$(NOECHO) $(ECHO) "      ]" >> META_new.json
	$(NOECHO) $(ECHO) "   }," >> META_new.json
	$(NOECHO) $(ECHO) "   \"prereqs\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "      \"build\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "         \"requires\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "            \"Alien::Build\" : \"1.41\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"Alien::Build::MM\" : \"1.41\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"Alien::Build::Plugin::Cleanse::BuildDir\" : \"0\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"Alien::MSYS\" : \"0\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"ExtUtils::MakeMaker\" : \"6.52\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"File::Find::Rule\" : \"0\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"PkgConfig\" : \"0.19026\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"Sort::Versions\" : \"0\"" >> META_new.json
	$(NOECHO) $(ECHO) "         }" >> META_new.json
	$(NOECHO) $(ECHO) "      }," >> META_new.json
	$(NOECHO) $(ECHO) "      \"configure\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "         \"requires\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "            \"Alien::Build\" : \"1.41\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"Alien::Build::MM\" : \"1.41\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"Alien::Build::Plugin::Cleanse::BuildDir\" : \"0\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"Alien::MSYS\" : \"0\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"ExtUtils::MakeMaker\" : \"6.52\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"File::Find::Rule\" : \"0\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"PkgConfig\" : \"0\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"Sort::Versions\" : \"0\"" >> META_new.json
	$(NOECHO) $(ECHO) "         }" >> META_new.json
	$(NOECHO) $(ECHO) "      }," >> META_new.json
	$(NOECHO) $(ECHO) "      \"runtime\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "         \"requires\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "            \"Alien::Base\" : \"1.41\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"Alien::Build\" : \"0.25\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"FFI::CheckLib\" : \"0.23\"" >> META_new.json
	$(NOECHO) $(ECHO) "         }" >> META_new.json
	$(NOECHO) $(ECHO) "      }," >> META_new.json
	$(NOECHO) $(ECHO) "      \"test\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "         \"requires\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "            \"FFI::CheckLib\" : \"0.23\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"Test::Alien\" : \"0\"" >> META_new.json
	$(NOECHO) $(ECHO) "         }" >> META_new.json
	$(NOECHO) $(ECHO) "      }" >> META_new.json
	$(NOECHO) $(ECHO) "   }," >> META_new.json
	$(NOECHO) $(ECHO) "   \"release_status\" : \"stable\"," >> META_new.json
	$(NOECHO) $(ECHO) "   \"resources\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "      \"bugtracker\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "         \"web\" : \"https://github.com/shawnlaffan/perl-alien-proj4/issues/\"" >> META_new.json
	$(NOECHO) $(ECHO) "      }," >> META_new.json
	$(NOECHO) $(ECHO) "      \"repository\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "         \"type\" : \"git\"," >> META_new.json
	$(NOECHO) $(ECHO) "         \"url\" : \"https://github.com/shawnlaffan/perl-alien-proj4\"" >> META_new.json
	$(NOECHO) $(ECHO) "      }" >> META_new.json
	$(NOECHO) $(ECHO) "   }," >> META_new.json
	$(NOECHO) $(ECHO) "   \"version\" : \"1.02\"," >> META_new.json
	$(NOECHO) $(ECHO) "   \"x_alienfile\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "      \"generated_by\" : \"Alien::Build::MM version 1.49\"," >> META_new.json
	$(NOECHO) $(ECHO) "      \"requires\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "         \"share\" : {" >> META_new.json
	$(NOECHO) $(ECHO) "            \"Alien::MSYS\" : \"0.07\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"Archive::Tar\" : \"0\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"HTML::LinkExtor\" : \"0\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"HTTP::Tiny\" : \"0.044\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"IO::Zlib\" : \"0\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"Sort::Versions\" : \"0\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"URI\" : \"0\"," >> META_new.json
	$(NOECHO) $(ECHO) "            \"URI::Escape\" : \"0\"" >> META_new.json
	$(NOECHO) $(ECHO) "         }," >> META_new.json
	$(NOECHO) $(ECHO) "         \"system\" : {}" >> META_new.json
	$(NOECHO) $(ECHO) "      }" >> META_new.json
	$(NOECHO) $(ECHO) "   }," >> META_new.json
	$(NOECHO) $(ECHO) "   \"x_serialization_backend\" : \"JSON::PP version 2.97001\"" >> META_new.json
	$(NOECHO) $(ECHO) } >> META_new.json
	-$(NOECHO) $(MV) META_new.json $(DISTVNAME)/META.json


# --- MakeMaker signature section:
signature :
	cpansign -s


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(ABSPERLRUN) -l -e "print 'Warning: Makefile possibly out of date with $(VERSION_FROM)'\
    if -e '$(VERSION_FROM)' and -M '$(VERSION_FROM)' < -M '$(FIRST_MAKEFILE)';" --

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)_uu'

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)'
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).zip'
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).shar'
	$(POSTOP)


# --- MakeMaker distdir section:
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir distmeta 
	$(NOECHO) $(NOOP)



# --- MakeMaker dist_test section:
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)



# --- MakeMaker dist_ci section:
ci :
	$(ABSPERLRUN) -MExtUtils::Manifest=maniread -e "@all = sort keys %{ maniread() };\
print(qq{Executing $(CI) @all\n});\
system(qq{$(CI) @all}) == 0 or die $$!;\
print(qq{Executing $(RCS_LABEL) ...\n});\
system(qq{$(RCS_LABEL) @all}) == 0 or die $$!;" --


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e "exit unless -e q{META.yml};\
eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }\
    or die \"Could not add META.yml to MANIFEST: $${'^@'}\"" --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e "exit unless -f q{META.json};\
eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }\
    or die \"Could not add META.json to MANIFEST: $${'^@'}\"" --



# --- MakeMaker distsignature section:
distsignature : distmeta
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e "eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }\
    or die \"Could not add SIGNATURE to MANIFEST: $${'^@'}\"" --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s



# --- MakeMaker install section:

install :: pure_install doc_install
	$(NOECHO) $(NOOP)

install_perl :: pure_perl_install doc_perl_install
	$(NOECHO) $(NOOP)

install_site :: pure_site_install doc_site_install
	$(NOECHO) $(NOOP)

install_vendor :: pure_vendor_install doc_vendor_install
	$(NOECHO) $(NOOP)

pure_install :: pure_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

doc_install :: doc_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read "$(PERL_ARCHLIB)\auto\$(FULLEXT)\.packlist" \
		write "$(DESTINSTALLARCHLIB)\auto\$(FULLEXT)\.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLPRIVLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLARCHLIB)" \
		"$(INST_BIN)" "$(DESTINSTALLBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(SITEARCHEXP)\auto\$(FULLEXT)"


pure_site_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read "$(SITEARCHEXP)\auto\$(FULLEXT)\.packlist" \
		write "$(DESTINSTALLSITEARCH)\auto\$(FULLEXT)\.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLSITELIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLSITEARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLSITEBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSITESCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLSITEMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLSITEMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(PERL_ARCHLIB)\auto\$(FULLEXT)"

pure_vendor_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read "$(VENDORARCHEXP)\auto\$(FULLEXT)\.packlist" \
		write "$(DESTINSTALLVENDORARCH)\auto\$(FULLEXT)\.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLVENDORLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLVENDORARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLVENDORBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLVENDORSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLVENDORMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLVENDORMAN3DIR)"


doc_perl_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLARCHLIB)/perllocal.pod"
	-$(NOECHO) $(MKPATH) "$(DESTINSTALLARCHLIB)"
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLARCHLIB)\perllocal.pod"

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLARCHLIB)/perllocal.pod"
	-$(NOECHO) $(MKPATH) "$(DESTINSTALLARCHLIB)"
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLARCHLIB)\perllocal.pod"

doc_vendor_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLARCHLIB)/perllocal.pod"
	-$(NOECHO) $(MKPATH) "$(DESTINSTALLARCHLIB)"
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLVENDORLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLARCHLIB)\perllocal.pod"


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::
	$(NOECHO) $(UNINSTALL) "$(PERL_ARCHLIB)\auto\$(FULLEXT)\.packlist"

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) "$(SITEARCHEXP)\auto\$(FULLEXT)\.packlist"

uninstall_from_vendordirs ::
	$(NOECHO) $(UNINSTALL) "$(VENDORARCHEXP)\auto\$(FULLEXT)\.packlist"


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:
# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL 
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	$(FALSE)



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = "C:\berrybrew\5.28.0_64_PDL\perl\bin\perl.exe"
MAP_PERLINC   = "-Iblib\arch" "-Iblib\lib" "-IC:\berrybrew\5.28.0_64_PDL\perl\lib" "-IC:\berrybrew\5.28.0_64_PDL\perl\lib"

$(MAP_TARGET) :: $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : static $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR="" \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:
TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/*.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)
	$(NOECHO) $(NOOP)

test :: $(TEST_TYPE)
	$(NOECHO) $(NOOP)

# Occasionally we may face this degenerate target:
test_ : test_dynamic
	$(NOECHO) $(NOOP)

subdirs-test_dynamic :: dynamic pure_all

test_dynamic :: subdirs-test_dynamic
	$(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: dynamic pure_all
	$(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

subdirs-test_static :: static pure_all

test_static :: subdirs-test_static
	$(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_static :: static pure_all
	$(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)



# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) "<SOFTPKG NAME=\"Alien-proj\" VERSION=\"1.02\">" > Alien-proj.ppd
	$(NOECHO) $(ECHO) "    <ABSTRACT>Alien package for the PROJ library</ABSTRACT>" >> Alien-proj.ppd
	$(NOECHO) $(ECHO) "    <AUTHOR>Shawn Laffan &lt;shawnlaffan@gmail.com&gt;</AUTHOR>" >> Alien-proj.ppd
	$(NOECHO) $(ECHO) "    <IMPLEMENTATION>" >> Alien-proj.ppd
	$(NOECHO) $(ECHO) "        <REQUIRE NAME=\"Alien::Base\" VERSION=\"1.41\" />" >> Alien-proj.ppd
	$(NOECHO) $(ECHO) "        <REQUIRE NAME=\"Alien::Build\" VERSION=\"0.25\" />" >> Alien-proj.ppd
	$(NOECHO) $(ECHO) "        <REQUIRE NAME=\"FFI::CheckLib\" VERSION=\"0.23\" />" >> Alien-proj.ppd
	$(NOECHO) $(ECHO) "        <ARCHITECTURE NAME=\"MSWin32-x64-multi-thread-5.28\" />" >> Alien-proj.ppd
	$(NOECHO) $(ECHO) "        <CODEBASE HREF=\"\" />" >> Alien-proj.ppd
	$(NOECHO) $(ECHO) "    </IMPLEMENTATION>" >> Alien-proj.ppd
	$(NOECHO) $(ECHO) ^</SOFTPKG^> >> Alien-proj.ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e "pm_to_blib({@ARGV}, '$(INST_LIB)\auto', q[$(PM_FILTER)], '$(PERM_DIR)')" -- \
	  lib/Alien/proj.pm blib\lib\Alien\proj.pm 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:

# here so even if top_targets is overridden, these will still be defined
# gmake will silently still work if any are .PHONY-ed but nmake won't

static ::
	$(NOECHO) $(NOOP)

dynamic ::
	$(NOECHO) $(NOOP)

config ::
	$(NOECHO) $(NOOP)


# --- MakeMaker postamble section:
realclean :: alien_realclean

alien_realclean:
	$(RM_RF) _alien

alien_prefix : _alien/mm/prefix

_alien/mm/prefix :
	$(FULLPERL) -MAlien::Build::MM=cmd -e prefix $(INSTALLDIRS) $(INSTALLARCHLIB) $(INSTALLSITEARCH) $(INSTALLVENDORARCH)

alien_version : _alien/mm/version

_alien/mm/version : _alien/mm/prefix
	$(FULLPERL) -MAlien::Build::MM=cmd -e version $(VERSION)

alien_download : _alien/mm/download

_alien/mm/download : _alien/mm/prefix _alien/mm/version
	$(FULLPERL) -MAlien::Build::MM=cmd -e download

alien_build : _alien/mm/build

_alien/mm/build : _alien/mm/download
	$(FULLPERL) -MAlien::Build::MM=cmd -e build

pure_all :: _alien/mm/build

subdirs-test_dynamic subdirs-test_static subdirs-test :: alien_test

alien_test :
	$(FULLPERL) -MAlien::Build::MM=cmd -e test

alien_prop :
	$(FULLPERL) -MAlien::Build::MM=cmd -e dumpprop

alien_prop_meta :
	$(FULLPERL) -MAlien::Build::MM=cmd -e dumpprop meta

alien_prop_install :
	$(FULLPERL) -MAlien::Build::MM=cmd -e dumpprop install

alien_prop_runtime :
	$(FULLPERL) -MAlien::Build::MM=cmd -e dumpprop runtime



# End.
