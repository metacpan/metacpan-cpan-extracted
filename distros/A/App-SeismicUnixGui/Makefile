# This Makefile is for the App::SeismicUnixGui extension to perl.
#
# It was generated automatically by MakeMaker version
# 7.70 (Revision: 77000) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     ABSTRACT_FROM => q[lib/App/SeismicUnixGui.pm]
#     AUTHOR => [q[Juan Lorenzo <gllore@lsu.edu>]]
#     BUILD_REQUIRES => {  }
#     CONFIGURE_REQUIRES => {  }
#     EXE_FILES => [q[./lib/App/SeismicUnixGui/script/post_install_scripts.sh], q[./lib/App/SeismicUnixGui/script/post_install_env.pl], q[./lib/App/SeismicUnixGui/script/post_install_c_compile.pl], q[./lib/App/SeismicUnixGui/script/post_install_fortran_compile.pl]]
#     LICENSE => q[perl]
#     MAN3PODS => {  }
#     NAME => q[App::SeismicUnixGui]
#     PREREQ_PM => { Clone=>q[0.45], File::ShareDir=>q[1.118], File::Slurp=>q[9999.32], MIME::Base64=>q[3.16], Module::Refresh=>q[0.18], Moose=>q[2.2015], PDL=>q[2.080], Shell=>q[v0.73.1], Test::Compile::Internal=>q[1.3], Time::HiRes=>q[1.9764], Tk=>q[804.036], Tk::JFileDialog=>q[2.20], Tk::Pod=>q[0.9943], aliased=>q[0.34], namespace::autoclean=>q[0.29] }
#     TEST_REQUIRES => { Test::Compile::Internal=>q[1.3] }
#     VERSION_FROM => q[lib/App/SeismicUnixGui.pm]
#     dist => { COMPRESS=>q[gzip -9f], SUFFIX=>q[gz] }
#     test => { TESTS=>q[t/*.t] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /usr/lib/x86_64-linux-gnu/perl-base/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = x86_64-linux-gnu-gcc
CCCDLFLAGS = -fPIC
CCDLFLAGS = -Wl,-E
CPPRUN = x86_64-linux-gnu-gcc  -E
DLEXT = so
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = x86_64-linux-gnu-gcc
LDDLFLAGS = -shared -L/usr/local/lib -fstack-protector-strong
LDFLAGS =  -fstack-protector-strong -L/usr/local/lib
LIBC = /lib/x86_64-linux-gnu/libc.so.6
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 6.1.0
RANLIB = :
SITELIBEXP = /usr/local/share/perl/5.38.2
SITEARCHEXP = /usr/local/lib/x86_64-linux-gnu/perl/5.38.2
SO = so
VENDORARCHEXP = /usr/lib/x86_64-linux-gnu/perl5/5.38
VENDORLIBEXP = /usr/share/perl5


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = App::SeismicUnixGui
NAME_SYM = App_SeismicUnixGui
VERSION = 0.87.2
VERSION_MACRO = VERSION
VERSION_SYM = 0_87_2
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 0.87.2
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1p
MAN3EXT = 3pm
MAN1SECTION = 1
MAN3SECTION = 3
INSTALLDIRS = site
DESTDIR = 
PREFIX = $(SITEPREFIX)
PERLPREFIX = /usr
SITEPREFIX = /usr/local
VENDORPREFIX = /usr
INSTALLPRIVLIB = /usr/share/perl/5.38
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = /usr/local/share/perl/5.38.2
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = /usr/share/perl5
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = /usr/lib/x86_64-linux-gnu/perl/5.38
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = /usr/local/lib/x86_64-linux-gnu/perl/5.38.2
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = /usr/lib/x86_64-linux-gnu/perl5/5.38
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = /usr/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = /usr/local/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = /usr/bin
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = /usr/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = /usr/local/bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = /usr/bin
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = /usr/share/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = /usr/local/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = /usr/share/man/man1
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = /usr/share/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = /usr/local/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = /usr/share/man/man3
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB = /usr/share/perl/5.38
PERL_ARCHLIB = /usr/lib/x86_64-linux-gnu/perl/5.38
PERL_ARCHLIBDEP = /usr/lib/x86_64-linux-gnu/perl/5.38
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /usr/lib/x86_64-linux-gnu/perl/5.38/CORE
PERL_INCDEP = /usr/lib/x86_64-linux-gnu/perl/5.38/CORE
PERL = "/usr/bin/perl"
FULLPERL = "/usr/bin/perl"
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

MAKEMAKER   = /usr/share/perl/5.38/ExtUtils/MakeMaker.pm
MM_VERSION  = 7.70
MM_REVISION = 77000

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = App/SeismicUnixGui
BASEEXT = SeismicUnixGui
PARENT_NAME = App
DLBASE = $(BASEEXT)
VERSION_FROM = lib/App/SeismicUnixGui.pm
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = ./lib/App/SeismicUnixGui/script/post_install_c_compile.pl \
	./lib/App/SeismicUnixGui/script/post_install_env.pl \
	./lib/App/SeismicUnixGui/script/post_install_fortran_compile.pl
MAN3PODS = 

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIBDEP)$(DFSEP)Config.pm $(PERL_INCDEP)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)/App
INST_ARCHLIBDIR  = $(INST_ARCHLIB)/App

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVEDEP    = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/App/SeismicUnixGui.pm \
	lib/App/SeismicUnixGui/big_streams/.FileHistory.txt \
	lib/App/SeismicUnixGui/big_streams/BackupProject.pl \
	lib/App/SeismicUnixGui/big_streams/Project.pl \
	lib/App/SeismicUnixGui/big_streams/RestoreProject.pl \
	lib/App/SeismicUnixGui/big_streams/SetProject.pl \
	lib/App/SeismicUnixGui/big_streams/Sseg2su.pl \
	lib/App/SeismicUnixGui/big_streams/Sucat.pl \
	lib/App/SeismicUnixGui/big_streams/Sudipfilt.pl \
	lib/App/SeismicUnixGui/big_streams/Synseis.pl \
	lib/App/SeismicUnixGui/big_streams/Synseis.pm \
	lib/App/SeismicUnixGui/big_streams/archive/iBottomMute_config.pm \
	lib/App/SeismicUnixGui/big_streams/check.pm \
	lib/App/SeismicUnixGui/big_streams/iApply_bottom_mute.pm \
	lib/App/SeismicUnixGui/big_streams/iApply_mute.pm \
	lib/App/SeismicUnixGui/big_streams/iApply_top_mute.pm \
	lib/App/SeismicUnixGui/big_streams/iBottomMute.pl \
	lib/App/SeismicUnixGui/big_streams/iBottomMute.pm \
	lib/App/SeismicUnixGui/big_streams/iBottomMutePicks2par.pm \
	lib/App/SeismicUnixGui/big_streams/iPick.pl \
	lib/App/SeismicUnixGui/big_streams/iPick.pm \
	lib/App/SeismicUnixGui/big_streams/iPicks2par.pm \
	lib/App/SeismicUnixGui/big_streams/iPicks2sort.pm \
	lib/App/SeismicUnixGui/big_streams/iSave_bottom_mute_picks.pm \
	lib/App/SeismicUnixGui/big_streams/iSave_mute_picks.pm \
	lib/App/SeismicUnixGui/big_streams/iSave_picks.pm \
	lib/App/SeismicUnixGui/big_streams/iSave_top_mute_picks.pm \
	lib/App/SeismicUnixGui/big_streams/iSelect_tr_Sumute.pm \
	lib/App/SeismicUnixGui/big_streams/iSelect_tr_Sumute_bottom.pm \
	lib/App/SeismicUnixGui/big_streams/iSelect_tr_Sumute_top.pm \
	lib/App/SeismicUnixGui/big_streams/iSelect_xt.pm \
	lib/App/SeismicUnixGui/big_streams/iShowNselect_picks.pm \
	lib/App/SeismicUnixGui/big_streams/iShow_picks.pm \
	lib/App/SeismicUnixGui/big_streams/iSpectralAnalysis.pl \
	lib/App/SeismicUnixGui/big_streams/iSpectralAnalysis.pm \
	lib/App/SeismicUnixGui/big_streams/iSunmo.pm \
	lib/App/SeismicUnixGui/big_streams/iSuvelan.pm \
	lib/App/SeismicUnixGui/big_streams/iTopMute.pl \
	lib/App/SeismicUnixGui/big_streams/iTopMute.pm \
	lib/App/SeismicUnixGui/big_streams/iTopMutePicks2par.pm \
	lib/App/SeismicUnixGui/big_streams/iVA.pl \
	lib/App/SeismicUnixGui/big_streams/iVA.pm \
	lib/App/SeismicUnixGui/big_streams/iVelocityAnalysis.pl \
	lib/App/SeismicUnixGui/big_streams/iVpicks2par.pm \
	lib/App/SeismicUnixGui/big_streams/iVrms2Vint.pm \
	lib/App/SeismicUnixGui/big_streams/iWrite_All_iva_out.pm \
	lib/App/SeismicUnixGui/big_streams/immodpg.pl \
	lib/App/SeismicUnixGui/big_streams/immodpg.pm \
	lib/App/SeismicUnixGui/big_streams/immodpg_global_constants.pm \
	lib/App/SeismicUnixGui/big_streams/pre_built_big_stream.pm \
	lib/App/SeismicUnixGui/big_streams/test.pl \
	lib/App/SeismicUnixGui/c/bin/synseis \
	lib/App/SeismicUnixGui/c/bin/synseis_old \
	lib/App/SeismicUnixGui/c/bin/tbd \
	lib/App/SeismicUnixGui/c/bin/test \
	lib/App/SeismicUnixGui/c/bin/zrhov \
	lib/App/SeismicUnixGui/c/obj/keep \
	lib/App/SeismicUnixGui/c/synseis/archive/1027.source \
	lib/App/SeismicUnixGui/c/synseis/archive/1027.source.su \
	lib/App/SeismicUnixGui/c/synseis/archive/mk \
	lib/App/SeismicUnixGui/c/synseis/archive/mod \
	lib/App/SeismicUnixGui/c/synseis/archive/plot_rc.sh \
	lib/App/SeismicUnixGui/c/synseis/archive/plot_ss.sh \
	lib/App/SeismicUnixGui/c/synseis/archive/plot_zrhoreg.sh \
	lib/App/SeismicUnixGui/c/synseis/archive/plot_zvreg.sh \
	lib/App/SeismicUnixGui/c/synseis/archive/rc_t \
	lib/App/SeismicUnixGui/c/synseis/archive/rc_t.bin \
	lib/App/SeismicUnixGui/c/synseis/archive/rc_z \
	lib/App/SeismicUnixGui/c/synseis/archive/rc_z.bin \
	lib/App/SeismicUnixGui/c/synseis/archive/source.out \
	lib/App/SeismicUnixGui/c/synseis/archive/ss \
	lib/App/SeismicUnixGui/c/synseis/archive/ss.bin \
	lib/App/SeismicUnixGui/c/synseis/archive/sufft_source.sh \
	lib/App/SeismicUnixGui/c/synseis/archive/synseis \
	lib/App/SeismicUnixGui/c/synseis/archive/synseis.c.bck \
	lib/App/SeismicUnixGui/c/synseis/archive/synseis.sh \
	lib/App/SeismicUnixGui/c/synseis/archive/synseis.tz \
	lib/App/SeismicUnixGui/c/synseis/archive/synseis_bck \
	lib/App/SeismicUnixGui/c/synseis/archive/xk \
	lib/App/SeismicUnixGui/c/synseis/archive/zrho.reg \
	lib/App/SeismicUnixGui/c/synseis/archive/zrho.reg.bin \
	lib/App/SeismicUnixGui/c/synseis/archive/zrhov \
	lib/App/SeismicUnixGui/c/synseis/archive/zrhov.904 \
	lib/App/SeismicUnixGui/c/synseis/archive/zv.reg \
	lib/App/SeismicUnixGui/c/synseis/makefile \
	lib/App/SeismicUnixGui/c/synseis/run_me_only.sh \
	lib/App/SeismicUnixGui/c/synseis/set_env_variables.sh \
	lib/App/SeismicUnixGui/c/synseis/src/synseis.c \
	lib/App/SeismicUnixGui/c/synseis/src/synseis_bck.c \
	lib/App/SeismicUnixGui/c/synseis/src/tbd.c \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/dzdv.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sucvs4fowler.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudivstack.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmofk.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmofkcw.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmotivz.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmotx.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmovz.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suilog.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suintvel.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sulog.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sunmo.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sunmo021020.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sunmo_a.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/supws.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/surecip.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sureduce.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/surelan.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/surelanan.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suresamp.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sushift.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sustack.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sustkvel.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sutaupnmo.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sutihaledmo.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sutivel.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sutsq.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suttoz.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suvel2df.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suvelan.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suvelan_nccs.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suvelan_nsel.config \
	lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suztot.config \
	lib/App/SeismicUnixGui/configs/big_streams/BackupProject.config \
	lib/App/SeismicUnixGui/configs/big_streams/BackupProject_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/Project.config \
	lib/App/SeismicUnixGui/configs/big_streams/Project_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/RestoreProject.config \
	lib/App/SeismicUnixGui/configs/big_streams/RestoreProject_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/Sseg2su.config \
	lib/App/SeismicUnixGui/configs/big_streams/Sseg2su_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/Sucat.config \
	lib/App/SeismicUnixGui/configs/big_streams/Sucat_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/Sudipfilt.config \
	lib/App/SeismicUnixGui/configs/big_streams/Sudipfilt_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/Synseis.config \
	lib/App/SeismicUnixGui/configs/big_streams/Synseis_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/iBottomMute.config \
	lib/App/SeismicUnixGui/configs/big_streams/iBottomMute_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/iBottom_Mute3.config \
	lib/App/SeismicUnixGui/configs/big_streams/iPick.config \
	lib/App/SeismicUnixGui/configs/big_streams/iPick_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/iSpectralAnalysis.config \
	lib/App/SeismicUnixGui/configs/big_streams/iSpectralAnalysis_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/iSurf4_bottom_right_wiggle.config \
	lib/App/SeismicUnixGui/configs/big_streams/iSurf4_top_left_image.config \
	lib/App/SeismicUnixGui/configs/big_streams/iSurf4_top_middle_wiggle.config \
	lib/App/SeismicUnixGui/configs/big_streams/iSurf4_top_right_image.config \
	lib/App/SeismicUnixGui/configs/big_streams/iSurf4_top_right_wiggle.config \
	lib/App/SeismicUnixGui/configs/big_streams/iTopMute.config \
	lib/App/SeismicUnixGui/configs/big_streams/iTopMute_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/iTop_Mute3.config \
	lib/App/SeismicUnixGui/configs/big_streams/iVA.config \
	lib/App/SeismicUnixGui/configs/big_streams/iVA_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/immodpg.config \
	lib/App/SeismicUnixGui/configs/big_streams/immodpg.out \
	lib/App/SeismicUnixGui/configs/big_streams/immodpg_config.pm \
	lib/App/SeismicUnixGui/configs/big_streams/model.txt \
	lib/App/SeismicUnixGui/configs/data/ctrlstrip.config \
	lib/App/SeismicUnixGui/configs/data/data_in.config \
	lib/App/SeismicUnixGui/configs/data/data_out.config \
	lib/App/SeismicUnixGui/configs/data/dt1tosu.config \
	lib/App/SeismicUnixGui/configs/data/segbread.config \
	lib/App/SeismicUnixGui/configs/data/segdread.config \
	lib/App/SeismicUnixGui/configs/data/segyread.config \
	lib/App/SeismicUnixGui/configs/data/segyscan.config \
	lib/App/SeismicUnixGui/configs/data/segywrite.config \
	lib/App/SeismicUnixGui/configs/data/suoldtonew.config \
	lib/App/SeismicUnixGui/configs/data/supack1.config \
	lib/App/SeismicUnixGui/configs/data/supack2.config \
	lib/App/SeismicUnixGui/configs/data/suswapbytes.config \
	lib/App/SeismicUnixGui/configs/data/suunpack1.config \
	lib/App/SeismicUnixGui/configs/data/suunpack2.config \
	lib/App/SeismicUnixGui/configs/data/wpc1uncomp2.config \
	lib/App/SeismicUnixGui/configs/data/wpccompress.config \
	lib/App/SeismicUnixGui/configs/data/wpcuncompress.config \
	lib/App/SeismicUnixGui/configs/data/wptcomp.config \
	lib/App/SeismicUnixGui/configs/data/wptuncomp.config \
	lib/App/SeismicUnixGui/configs/data/wtcomp.config \
	lib/App/SeismicUnixGui/configs/data/wtuncomp.config \
	lib/App/SeismicUnixGui/configs/datum/sudatumk2dr.config \
	lib/App/SeismicUnixGui/configs/datum/sudatumk2ds.config \
	lib/App/SeismicUnixGui/configs/datum/sukdmdcr.config \
	lib/App/SeismicUnixGui/configs/datum/sukdmdcs.config \
	lib/App/SeismicUnixGui/configs/filter/subfilt.config \
	lib/App/SeismicUnixGui/configs/filter/succfilt.config \
	lib/App/SeismicUnixGui/configs/filter/sucddecon.config \
	lib/App/SeismicUnixGui/configs/filter/sudipfilt.config \
	lib/App/SeismicUnixGui/configs/filter/sueipofi.config \
	lib/App/SeismicUnixGui/configs/filter/sufilter.config \
	lib/App/SeismicUnixGui/configs/filter/sufrac.config \
	lib/App/SeismicUnixGui/configs/filter/sufwatrim.config \
	lib/App/SeismicUnixGui/configs/filter/sufxdecon.config \
	lib/App/SeismicUnixGui/configs/filter/sugroll.config \
	lib/App/SeismicUnixGui/configs/filter/suk1k2filter.config \
	lib/App/SeismicUnixGui/configs/filter/sukfilter.config \
	lib/App/SeismicUnixGui/configs/filter/sulfaf.config \
	lib/App/SeismicUnixGui/configs/filter/sumedian.config \
	lib/App/SeismicUnixGui/configs/filter/supef.config \
	lib/App/SeismicUnixGui/configs/filter/suphase.config \
	lib/App/SeismicUnixGui/configs/filter/suphidecon.config \
	lib/App/SeismicUnixGui/configs/filter/supofilt.config \
	lib/App/SeismicUnixGui/configs/filter/supolar.config \
	lib/App/SeismicUnixGui/configs/filter/susmgauss2.config \
	lib/App/SeismicUnixGui/configs/filter/sutvband.config \
	lib/App/SeismicUnixGui/configs/header/segyclean.config \
	lib/App/SeismicUnixGui/configs/header/segyhdrmod.config \
	lib/App/SeismicUnixGui/configs/header/segyhdrs.config \
	lib/App/SeismicUnixGui/configs/header/setbhed.config \
	lib/App/SeismicUnixGui/configs/header/su3dchart.config \
	lib/App/SeismicUnixGui/configs/header/suabshw.config \
	lib/App/SeismicUnixGui/configs/header/suaddhead.config \
	lib/App/SeismicUnixGui/configs/header/suaddstatics.config \
	lib/App/SeismicUnixGui/configs/header/suahw.config \
	lib/App/SeismicUnixGui/configs/header/suascii.config \
	lib/App/SeismicUnixGui/configs/header/suazimuth.config \
	lib/App/SeismicUnixGui/configs/header/sucdpbin.config \
	lib/App/SeismicUnixGui/configs/header/suchart.config \
	lib/App/SeismicUnixGui/configs/header/suchw.config \
	lib/App/SeismicUnixGui/configs/header/sucliphead.config \
	lib/App/SeismicUnixGui/configs/header/sucountkey.config \
	lib/App/SeismicUnixGui/configs/header/sudumptrace.config \
	lib/App/SeismicUnixGui/configs/header/suedit.config \
	lib/App/SeismicUnixGui/configs/header/sugethw.config \
	lib/App/SeismicUnixGui/configs/header/suhtmath.config \
	lib/App/SeismicUnixGui/configs/header/sukeycount.config \
	lib/App/SeismicUnixGui/configs/header/sulcthw.config \
	lib/App/SeismicUnixGui/configs/header/sulhead.config \
	lib/App/SeismicUnixGui/configs/header/supaste.config \
	lib/App/SeismicUnixGui/configs/header/surandhw.config \
	lib/App/SeismicUnixGui/configs/header/surange.config \
	lib/App/SeismicUnixGui/configs/header/suresstat.config \
	lib/App/SeismicUnixGui/configs/header/susehw.config \
	lib/App/SeismicUnixGui/configs/header/sushw.config \
	lib/App/SeismicUnixGui/configs/header/sustatic.config \
	lib/App/SeismicUnixGui/configs/header/sustaticB.config \
	lib/App/SeismicUnixGui/configs/header/sustaticrrs.config \
	lib/App/SeismicUnixGui/configs/header/sustrip.config \
	lib/App/SeismicUnixGui/configs/header/sutrcount.config \
	lib/App/SeismicUnixGui/configs/header/suutm.config \
	lib/App/SeismicUnixGui/configs/header/suxedit.config \
	lib/App/SeismicUnixGui/configs/header/swapbhed.config \
	lib/App/SeismicUnixGui/configs/inversion/suinvco3d.config \
	lib/App/SeismicUnixGui/configs/inversion/suinvvxzco.config \
	lib/App/SeismicUnixGui/configs/inversion/suinvzco3d.config \
	lib/App/SeismicUnixGui/configs/migration/sudatumfd.config \
	lib/App/SeismicUnixGui/configs/migration/sugazmig.config \
	lib/App/SeismicUnixGui/configs/migration/sukdmig2d.config \
	lib/App/SeismicUnixGui/configs/migration/sukdmig3d.config \
	lib/App/SeismicUnixGui/configs/migration/suktmig2d.config \
	lib/App/SeismicUnixGui/configs/migration/sumigfd.config \
	lib/App/SeismicUnixGui/configs/migration/sumigffd.config \
	lib/App/SeismicUnixGui/configs/migration/sumiggbzo.config \
	lib/App/SeismicUnixGui/configs/migration/sumiggbzoan.config \
	lib/App/SeismicUnixGui/configs/migration/sumigprefd.config \
	lib/App/SeismicUnixGui/configs/migration/sumigpreffd.config \
	lib/App/SeismicUnixGui/configs/migration/sumigprepspi.config \
	lib/App/SeismicUnixGui/configs/migration/sumigpresp.config \
	lib/App/SeismicUnixGui/configs/migration/sumigps.config \
	lib/App/SeismicUnixGui/configs/migration/sumigpspi.config \
	lib/App/SeismicUnixGui/configs/migration/sumigpsti.config \
	lib/App/SeismicUnixGui/configs/migration/sumigsplit.config \
	lib/App/SeismicUnixGui/configs/migration/sumigtk.config \
	lib/App/SeismicUnixGui/configs/migration/sumigtopo2d.config \
	lib/App/SeismicUnixGui/configs/migration/sunmo.config \
	lib/App/SeismicUnixGui/configs/migration/sustolt.config \
	lib/App/SeismicUnixGui/configs/migration/sutifowler.config \
	lib/App/SeismicUnixGui/configs/model/addrvl3d.config \
	lib/App/SeismicUnixGui/configs/model/cellauto.config \
	lib/App/SeismicUnixGui/configs/model/elacheck.config \
	lib/App/SeismicUnixGui/configs/model/elamodel.config \
	lib/App/SeismicUnixGui/configs/model/elaray.config \
	lib/App/SeismicUnixGui/configs/model/elasyn.config \
	lib/App/SeismicUnixGui/configs/model/elatriuni.config \
	lib/App/SeismicUnixGui/configs/model/gbbeam.config \
	lib/App/SeismicUnixGui/configs/model/grm.config \
	lib/App/SeismicUnixGui/configs/model/normray.config \
	lib/App/SeismicUnixGui/configs/model/raydata.config \
	lib/App/SeismicUnixGui/configs/model/suaddevent.config \
	lib/App/SeismicUnixGui/configs/model/suaddnoise.config \
	lib/App/SeismicUnixGui/configs/model/sudgwaveform.config \
	lib/App/SeismicUnixGui/configs/model/suea2df.config \
	lib/App/SeismicUnixGui/configs/model/sufctanismod.config \
	lib/App/SeismicUnixGui/configs/model/sufdmod1.config \
	lib/App/SeismicUnixGui/configs/model/sufdmod2.config \
	lib/App/SeismicUnixGui/configs/model/sufdmod2_pml.config \
	lib/App/SeismicUnixGui/configs/model/sugoupillaud.config \
	lib/App/SeismicUnixGui/configs/model/sugoupillaudpo.config \
	lib/App/SeismicUnixGui/configs/model/suimp2d.config \
	lib/App/SeismicUnixGui/configs/model/suimp3d.config \
	lib/App/SeismicUnixGui/configs/model/suimpedance.config \
	lib/App/SeismicUnixGui/configs/model/sujitter.config \
	lib/App/SeismicUnixGui/configs/model/sukdsyn2d.config \
	lib/App/SeismicUnixGui/configs/model/sunull.config \
	lib/App/SeismicUnixGui/configs/model/suplane.config \
	lib/App/SeismicUnixGui/configs/model/surandspike.config \
	lib/App/SeismicUnixGui/configs/model/surandstat.config \
	lib/App/SeismicUnixGui/configs/model/suremac2d.config \
	lib/App/SeismicUnixGui/configs/model/suremel2dan.config \
	lib/App/SeismicUnixGui/configs/model/suspike.config \
	lib/App/SeismicUnixGui/configs/model/susyncz.config \
	lib/App/SeismicUnixGui/configs/model/susynlv.config \
	lib/App/SeismicUnixGui/configs/model/susynlvcw.config \
	lib/App/SeismicUnixGui/configs/model/susynlvfti.config \
	lib/App/SeismicUnixGui/configs/model/susynvxz.config \
	lib/App/SeismicUnixGui/configs/model/susynvxzcs.config \
	lib/App/SeismicUnixGui/configs/par/a2b.config \
	lib/App/SeismicUnixGui/configs/par/a2i.config \
	lib/App/SeismicUnixGui/configs/par/b2a.config \
	lib/App/SeismicUnixGui/configs/par/bhedtopar.config \
	lib/App/SeismicUnixGui/configs/par/cshotplot.config \
	lib/App/SeismicUnixGui/configs/par/float2ibm.config \
	lib/App/SeismicUnixGui/configs/par/ftnstrip.config \
	lib/App/SeismicUnixGui/configs/par/ftnunstrip.config \
	lib/App/SeismicUnixGui/configs/par/makevel.config \
	lib/App/SeismicUnixGui/configs/par/mkparfile.config \
	lib/App/SeismicUnixGui/configs/par/transp.config \
	lib/App/SeismicUnixGui/configs/par/unif2.config \
	lib/App/SeismicUnixGui/configs/par/unif2aniso.config \
	lib/App/SeismicUnixGui/configs/par/unisam.config \
	lib/App/SeismicUnixGui/configs/par/unisam2.config \
	lib/App/SeismicUnixGui/configs/par/vel2stiff.config \
	lib/App/SeismicUnixGui/configs/plot/elaps.config \
	lib/App/SeismicUnixGui/configs/plot/lcmap.config \
	lib/App/SeismicUnixGui/configs/plot/lprop.config \
	lib/App/SeismicUnixGui/configs/plot/psbbox.config \
	lib/App/SeismicUnixGui/configs/plot/pscontour.config \
	lib/App/SeismicUnixGui/configs/plot/pscube.config \
	lib/App/SeismicUnixGui/configs/plot/pscubecontour.config \
	lib/App/SeismicUnixGui/configs/plot/psepsi.config \
	lib/App/SeismicUnixGui/configs/plot/psgraph.config \
	lib/App/SeismicUnixGui/configs/plot/psimage.config \
	lib/App/SeismicUnixGui/configs/plot/pslabel.config \
	lib/App/SeismicUnixGui/configs/plot/psmanager.config \
	lib/App/SeismicUnixGui/configs/plot/psmerge.config \
	lib/App/SeismicUnixGui/configs/plot/psmovie.config \
	lib/App/SeismicUnixGui/configs/plot/pswigb.config \
	lib/App/SeismicUnixGui/configs/plot/pswigp.config \
	lib/App/SeismicUnixGui/configs/plot/scmap.config \
	lib/App/SeismicUnixGui/configs/plot/spsplot.config \
	lib/App/SeismicUnixGui/configs/plot/supscontour.config \
	lib/App/SeismicUnixGui/configs/plot/supscube.config \
	lib/App/SeismicUnixGui/configs/plot/supscubecontour.config \
	lib/App/SeismicUnixGui/configs/plot/supsgraph.config \
	lib/App/SeismicUnixGui/configs/plot/supsimage.config \
	lib/App/SeismicUnixGui/configs/plot/supsmax.config \
	lib/App/SeismicUnixGui/configs/plot/supsmovie.config \
	lib/App/SeismicUnixGui/configs/plot/supswigb.config \
	lib/App/SeismicUnixGui/configs/plot/supswigp.config \
	lib/App/SeismicUnixGui/configs/plot/suxcontour.config \
	lib/App/SeismicUnixGui/configs/plot/suxgraph.config \
	lib/App/SeismicUnixGui/configs/plot/suximage.config \
	lib/App/SeismicUnixGui/configs/plot/suxmax.config \
	lib/App/SeismicUnixGui/configs/plot/suxmovie.config \
	lib/App/SeismicUnixGui/configs/plot/suxpicker.config \
	lib/App/SeismicUnixGui/configs/plot/suxwigb.config \
	lib/App/SeismicUnixGui/configs/plot/xcontour.config \
	lib/App/SeismicUnixGui/configs/plot/xgraph.config \
	lib/App/SeismicUnixGui/configs/plot/ximage.config \
	lib/App/SeismicUnixGui/configs/plot/xmovie.config \
	lib/App/SeismicUnixGui/configs/plot/xpicker.config \
	lib/App/SeismicUnixGui/configs/plot/xwigb.config \
	lib/App/SeismicUnixGui/configs/shapeNcut/suflip.config \
	lib/App/SeismicUnixGui/configs/shapeNcut/sugain.config \
	lib/App/SeismicUnixGui/configs/shapeNcut/sugprfb.config \
	lib/App/SeismicUnixGui/configs/shapeNcut/sukill.config \
	lib/App/SeismicUnixGui/configs/shapeNcut/sumute.config \
	lib/App/SeismicUnixGui/configs/shapeNcut/supad.config \
	lib/App/SeismicUnixGui/configs/shapeNcut/suramp.config \
	lib/App/SeismicUnixGui/configs/shapeNcut/susort.config \
	lib/App/SeismicUnixGui/configs/shapeNcut/susplit.config \
	lib/App/SeismicUnixGui/configs/shapeNcut/suvcat.config \
	lib/App/SeismicUnixGui/configs/shapeNcut/suwind.config \
	lib/App/SeismicUnixGui/configs/shell/cat_su.config \
	lib/App/SeismicUnixGui/configs/shell/evince.config \
	lib/App/SeismicUnixGui/configs/shell/par/a2b.config \
	lib/App/SeismicUnixGui/configs/shell/par/b2a.config \
	lib/App/SeismicUnixGui/configs/shell/par/makevel.config \
	lib/App/SeismicUnixGui/configs/shell/par/mkparfile.config \
	lib/App/SeismicUnixGui/configs/shell/par/unisam.config \
	lib/App/SeismicUnixGui/configs/shell/par/unisam2.config \
	lib/App/SeismicUnixGui/configs/shell/sugetgthr.config \
	lib/App/SeismicUnixGui/configs/shell/suputgthr.config \
	lib/App/SeismicUnixGui/configs/shell/xk.config \
	lib/App/SeismicUnixGui/configs/statsMath/cpftrend.config \
	lib/App/SeismicUnixGui/configs/statsMath/entropy.config \
	lib/App/SeismicUnixGui/configs/statsMath/farith.config \
	lib/App/SeismicUnixGui/configs/statsMath/suacor.config \
	lib/App/SeismicUnixGui/configs/statsMath/suacorfrac.config \
	lib/App/SeismicUnixGui/configs/statsMath/sualford.config \
	lib/App/SeismicUnixGui/configs/statsMath/suattributes.config \
	lib/App/SeismicUnixGui/configs/statsMath/suconv.config \
	lib/App/SeismicUnixGui/configs/statsMath/sufwmix.config \
	lib/App/SeismicUnixGui/configs/statsMath/suhistogram.config \
	lib/App/SeismicUnixGui/configs/statsMath/suhrot.config \
	lib/App/SeismicUnixGui/configs/statsMath/suinterp.config \
	lib/App/SeismicUnixGui/configs/statsMath/sumax.config \
	lib/App/SeismicUnixGui/configs/statsMath/sumean.config \
	lib/App/SeismicUnixGui/configs/statsMath/sumix.config \
	lib/App/SeismicUnixGui/configs/statsMath/suop.config \
	lib/App/SeismicUnixGui/configs/statsMath/suop2.config \
	lib/App/SeismicUnixGui/configs/statsMath/suxcor.config \
	lib/App/SeismicUnixGui/configs/statsMath/suxmax.config \
	lib/App/SeismicUnixGui/configs/transform/dctcomp.config \
	lib/App/SeismicUnixGui/configs/transform/suamp.config \
	lib/App/SeismicUnixGui/configs/transform/succepstrum.config \
	lib/App/SeismicUnixGui/configs/transform/succwt.config \
	lib/App/SeismicUnixGui/configs/transform/sucepstrum.config \
	lib/App/SeismicUnixGui/configs/transform/sucwt.config \
	lib/App/SeismicUnixGui/configs/transform/sufft.config \
	lib/App/SeismicUnixGui/configs/transform/sugabor.config \
	lib/App/SeismicUnixGui/configs/transform/suicepstrum.config \
	lib/App/SeismicUnixGui/configs/transform/suifft.config \
	lib/App/SeismicUnixGui/configs/transform/suminphase.config \
	lib/App/SeismicUnixGui/configs/transform/suphasevel.config \
	lib/App/SeismicUnixGui/configs/transform/suspecfk.config \
	lib/App/SeismicUnixGui/configs/transform/suspecfx.config \
	lib/App/SeismicUnixGui/configs/transform/sutaup.config \
	lib/App/SeismicUnixGui/configs/well/las2su.config \
	lib/App/SeismicUnixGui/configs/well/subackus.config \
	lib/App/SeismicUnixGui/configs/well/subackush.config \
	lib/App/SeismicUnixGui/configs/well/sugassman.config \
	lib/App/SeismicUnixGui/configs/well/sulprime.config \
	lib/App/SeismicUnixGui/configs/well/suwellrf.config \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/dzdv.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/dzdv_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sucvs4fowler.su.main.stacking \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudivstack.su.main.stacking \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmofk.su.main.dip_moveout \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmofkcw.su.main.dip_moveout \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmotivz.su.main.dip_moveout \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmotx.su.main.dip_moveout \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmovz.su.main.dip_moveout \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suilog.su.main.stretching_moveout_resamp \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suintvel.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sulog.su.main.stretching_moveout_resamp \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sunmo.su.main.stretching_moveout_resamp \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sunmo_a.su.main.stretching_moveout_resamp \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/supws.su.main.stacking \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/surecip.su.main.stacking \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sureduce.su.main.stretching_moveout_resamp \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/surelan.su.main.velocity_analysis \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/surelanan.su.main.velocity_analysis \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suresamp.su.main.stretching_moveout_resamp \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sushift.su.main.stretching_moveout_resamp \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sustack.su.main.stacking \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sustkvel.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sustkvel_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutaupnmo.su.main.stretching_moveout_resamp \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutaupnmo_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutihaledmo.su.main.dip_moveout \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutihaledmo_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutivel.su.main.velocity_analysis \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutivel_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutsq.su.main.stretching_moveout_resamp \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutsq_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suttoz.su.main.stretching_moveout_resamp \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suttoz_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvel2df.su.main.velocity_analysis \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvel2df_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan.su.main.velocity_analysis \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_nccs.su.main.velocity_analysis \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_nccs_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_nsel.su.main.velocity_analysis \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_nsel_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_uccs.su.main.velocity_analysis \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_usel.su.main.velocity_analysis \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suztot.su.main.stretching_moveout_resamp \
	lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suztot_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/data/ctrlstrip.cwp.main \
	lib/App/SeismicUnixGui/developer/Stripped/data/dt1tosu.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/data/seg2segy.ThirdParty \
	lib/App/SeismicUnixGui/developer/Stripped/data/segbread.Sfio.main \
	lib/App/SeismicUnixGui/developer/Stripped/data/segdread.Sfio.main \
	lib/App/SeismicUnixGui/developer/Stripped/data/segyclean.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/data/segyhdrs.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/data/segyhdrs_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/data/segyread.c.hold.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/data/segyread.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/data/segyread_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/data/segyscan.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/data/segywrite.c.hold.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/data/segywrite.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/data/segywrite_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/data/suoldtonew.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/data/supack1.su.main.data_compression \
	lib/App/SeismicUnixGui/developer/Stripped/data/supack2.su.main.data_compression \
	lib/App/SeismicUnixGui/developer/Stripped/data/suswapbytes.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/data/suunpack1.su.main.data_compression \
	lib/App/SeismicUnixGui/developer/Stripped/data/suunpack2.su.main.data_compression \
	lib/App/SeismicUnixGui/developer/Stripped/data/wpc1uncomp2.comp.dwpt.1d.main \
	lib/App/SeismicUnixGui/developer/Stripped/data/wpccompress.comp.dwpt.2d.main \
	lib/App/SeismicUnixGui/developer/Stripped/data/wpcuncompress.comp.dwpt.2d.main \
	lib/App/SeismicUnixGui/developer/Stripped/data/wptcomp.comp.dct.main \
	lib/App/SeismicUnixGui/developer/Stripped/data/wptuncomp.comp.dct.main \
	lib/App/SeismicUnixGui/developer/Stripped/data/wtcomp.comp.dct.main \
	lib/App/SeismicUnixGui/developer/Stripped/data/wtuncomp.comp.dct.main \
	lib/App/SeismicUnixGui/developer/Stripped/datum/sudatumk2dr.su.main.datuming \
	lib/App/SeismicUnixGui/developer/Stripped/datum/sudatumk2ds.su.main.datuming \
	lib/App/SeismicUnixGui/developer/Stripped/datum/sukdmdcr.su.main.datuming \
	lib/App/SeismicUnixGui/developer/Stripped/datum/sukdmdcs.su.main.datuming \
	lib/App/SeismicUnixGui/developer/Stripped/filter/subfilt.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/succfilt.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sucddecon.su.main.decon_shaping \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sudipfilt.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sueipofi.su.main.multicomponent \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sufilter.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sufrac.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sufwatrim.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sufxdecon.su.main.decon_shaping \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sugroll.su.main.noise \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sugroll_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/filter/suk1k2filter.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sukfilter.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sukfrac.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sulfaf.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sumedian.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/supef.su.main.decon_shaping \
	lib/App/SeismicUnixGui/developer/Stripped/filter/suphase.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/suphidecon.su.main.decon_shaping \
	lib/App/SeismicUnixGui/developer/Stripped/filter/supofilt.su.main.multicomponent \
	lib/App/SeismicUnixGui/developer/Stripped/filter/supolar.su.main.multicomponent \
	lib/App/SeismicUnixGui/developer/Stripped/filter/susmgauss2.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/filter/sutvband.su.main.filters \
	lib/App/SeismicUnixGui/developer/Stripped/header/segyhdrmod.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/header/setbhed.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/header/su3dchart.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/suabshw.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/suaddhead.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/suaddstatics.su.main.statics \
	lib/App/SeismicUnixGui/developer/Stripped/header/suahw.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/suascii.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/header/suazimuth.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/sucdpbin.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/suchart.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/suchw.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/sucliphead.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/sucountkey.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/sudumptrace.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/suedit.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/sugethw.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/suhtmath.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/sukeycount.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/sulcthw.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/sulhead.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/supaste.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/surandhw.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/surange.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/suresstat.su.main.statics \
	lib/App/SeismicUnixGui/developer/Stripped/header/suresstat_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/header/susehw.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/sushw.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/sustatic.su.main.statics \
	lib/App/SeismicUnixGui/developer/Stripped/header/sustaticB.su.main.statics \
	lib/App/SeismicUnixGui/developer/Stripped/header/sustaticrrs.su.main.statics \
	lib/App/SeismicUnixGui/developer/Stripped/header/sustrip.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/sutrcount.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/suutm.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/suxedit.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/header/swapbhed.su.main.data_conversion \
	lib/App/SeismicUnixGui/developer/Stripped/header/zebc.cwp.lib \
	lib/App/SeismicUnixGui/developer/Stripped/inversion/suinvco3d.3D.Suinvco3d \
	lib/App/SeismicUnixGui/developer/Stripped/inversion/suinvvxzco.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/inversion/suinvzco3d.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sudatumfd.su.main.datuming \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sugazmig.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sukdmig2d.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sukdmig3d.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sukdmig3d_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/migration/suktmig2d.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigfd.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigffd.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumiggbzo.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumiggbzoan.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigprefd.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigpreffd.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigprepspi.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigpresp.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigps.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigps_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigpspi.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigpsti.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigsplit.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigtk.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sumigtopo2d.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sustolt.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/migration/sutifowler.su.main.migration_inversion \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/CWPGrep.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/argv.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/copyright.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/cpall.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/cpusec.cwputils \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/cputime.cwputils \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/cwpfind.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/dirtree.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/downfort.cwp.main \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/fcat.cwp.main \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/filetype.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/gendocs.par.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/isatty.cwp.main \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/lookpar.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/maxdiff.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/maxints.cwp.main \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/merge2.psplot.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/merge4.psplot.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/newcase.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/overwrite.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/pause.cwp.main \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/precedence.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/recip.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/replace.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/rmaxdiff.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/striptotxt.par.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suagc.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suband.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sucmp.su.main.attributes_parameter_estimation \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sudiff.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sudoc.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suenv.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sufind.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sufind2.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sugendocs.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suget.su.main.supromax \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sugetgthr.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sugprfb.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suhelp.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sukeyword.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suname.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suput.su.main.supromax \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/t.cwp.main \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/this_year.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/time_now.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/todays_date.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/unglitch.su.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/updatedoc.par.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/updatedocall.par.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/updatehead.par.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/upfort.cwp.main \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/usernames.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/varlist.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/wallsec.cwputils \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/walltime.cwputils \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/weekday.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/xrects.Xtcwp.main \
	lib/App/SeismicUnixGui/developer/Stripped/misc/bck/zap.cwp.shell \
	lib/App/SeismicUnixGui/developer/Stripped/model/addrvl3d.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/addrvl3d_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/model/cellauto.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/cellauto_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/model/elacheck.Trielas.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/elamodel.Trielas.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/elaray.Trielas.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/elasyn.Trielas.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/elatriuni.Trielas.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/gbbeam.Trielas.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/gbbeam.tri.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/grm.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/grm_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/model/normray.tri.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/raydata.Trielas.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/suaddevent.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/suaddnoise.su.main.noise \
	lib/App/SeismicUnixGui/developer/Stripped/model/sudgwaveform.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/suea2df.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/sufctanismod.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/sufdmod1.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/sufdmod2.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/sufdmod2_pml.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/sugoupillaud.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/sugoupillaudpo.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/suimp2d.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/suimp3d.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/suimpedance.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/sujitter.su.main.noise \
	lib/App/SeismicUnixGui/developer/Stripped/model/sukdsyn2d.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/sunhmospike.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/sunull.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/suplane.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/surandspike.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/surandstat.su.main.statics \
	lib/App/SeismicUnixGui/developer/Stripped/model/suremac2d.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/suremel2dan.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/suspike.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/susyncz.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/susynlv.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/susynlvcw.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/susynlvfti.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/susynvxz.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/susynvxzcs.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/sutetraray.tetra.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/suvibro.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/suwaveform.su.main.synthetics_waveforms_testpatterns \
	lib/App/SeismicUnixGui/developer/Stripped/model/sxplot.xtri \
	lib/App/SeismicUnixGui/developer/Stripped/model/tetramod.tetra.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/tri2uni.tri.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/trimodel.tri.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/trip.Mesa.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/triray.tri.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/triseis.tri.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/uni2tri.tri.main \
	lib/App/SeismicUnixGui/developer/Stripped/model/unif2.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/.FileHistory.txt \
	lib/App/SeismicUnixGui/developer/Stripped/par/a2i.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/a2i_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/par/b2a.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/bhedtopar.su.main.headers \
	lib/App/SeismicUnixGui/developer/Stripped/par/bhedtopar_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/par/cshotplot.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/cshotplot_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/par/float2ibm.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/float2ibm_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/par/ftnstrip.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/ftnstrip_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/par/ftnunstrip.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/ftnunstrip_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/par/h2b.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/hti2stiff.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/hudson.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/i2a.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/ibm2float.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/kaperture.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/linrort.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/lorenz.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/makevel.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/mkparfile.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/mrafxzwt.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/pdfhistogram.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/prplot.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/randvel3d.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/rayt2d.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/rayt2dan.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/recast.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/refRealAziHTI.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/refRealVTI.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/regrid3.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/resamp.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/rossler.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/smooth2.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/smooth3d.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/smoothint2.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/stiff2vel.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/subset.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/swapbytes.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/thom2hti.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/thom2stiff.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/transp.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/transp3d.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/tvnmoqc.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/unif2aniso.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/unif2ti2.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/unisam.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/unisam2.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/unisam2_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/par/utmconv.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/vel2stiff.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/velconv.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/velpert.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/velpertan.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/verhulst.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/vtlvz.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/wkbj.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/xy2z.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/par/z2xyz.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/picking/sufbpickw.su.main.picking \
	lib/App/SeismicUnixGui/developer/Stripped/picking/sufnzero.su.main.picking \
	lib/App/SeismicUnixGui/developer/Stripped/picking/supickamp.su.main.picking \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/elaps.Trielas.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/junk \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/lcmap.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/list \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/lprop.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psbbox.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pscontour.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pscube.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pscubecontour.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psepsi.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psgraph.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psimage.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pslabel.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psmanager.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psmerge.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psmovie.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pswigb.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pswigp.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/scmap.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/spsplot.tri.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supscontour.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supscube.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supscubecontour.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supsgraph.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supsimage.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supsmax.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supsmovie.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supswigb.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supswigp.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxcontour.su.graphics.xplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxgraph.su.graphics.xplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suximage.su.graphics.xplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxmax.su.graphics.xplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxmovie.su.graphics.xplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxpicker.su.graphics.xplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxwigb.su.graphics.xplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/viewer3.Mesa.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xcontour.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xepsb.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xepsp.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xgraph.Xtcwp.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/ximage.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xmovie.Xtcwp.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xpicker.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xpsp.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xwigb.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/elaps.Trielas.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/lcmap.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/lprop.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/psbbox.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/pscontour.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/pscube.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/pscubecontour.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/psepsi.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/psgraph.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/psimage.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/pslabel.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/psmanager.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/psmerge.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/psmovie.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/pswigb.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/pswigp.psplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/scmap.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/spsplot.tri.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/supscontour.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/supscube.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/supscubecontour.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/supsgraph.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/supsimage.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/supsmax.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/supsmovie.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/supswigb.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/supswigp.su.graphics.psplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/suxcontour.su.graphics.xplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/suxmax.su.graphics.xplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/suxpicker.su.graphics.xplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/suxwigb.su.graphics.xplot \
	lib/App/SeismicUnixGui/developer/Stripped/plot/viewer3.Mesa.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/xcontour.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/xcontour_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/plot/xepsb.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/xepsp.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/xpicker.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/plot/xpicker_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/plot/xpsp.xplot.main \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sucentsamp.su.main.amplitudes \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sucommand.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sudipdivcor.su.main.amplitudes \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sudivcor.su.main.amplitudes \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suflip.su.main.operations \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sugain.config \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sugain.su.main.amplitudes \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sugausstaper.su.main.tapering \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sukill.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sumute.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sumute_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sunan.su.main.amplitudes \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/supad.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/supad_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/supermute.su.main.operations \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/supgc.su.main.amplitudes \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suputgthr.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suramp.su.main.tapering \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suresstat.su.main.statics \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sushape.su.main.decon_shaping \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/susort.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/susorty.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/susplit.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sutxtaper.su.main.tapering \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suvcat.su.main.operations \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suvcat_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suvlength.su.main.operations \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suwind.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suwindpoly.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suzero.su.main.amplitudes \
	lib/App/SeismicUnixGui/developer/Stripped/shell/catsu.par \
	lib/App/SeismicUnixGui/developer/Stripped/shell/sugetgthr.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/shell/suputgthr.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/cpftrend.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/cpftrend_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/entropy.comp.dct.main \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/farith.par.main \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/farith_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/list \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suacor.su.main.convolution_correlation \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suacorfrac.su.main.convolution_correlation \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/sualford.su.main.multicomponent \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suattributes.su.main.attributes_parameter_estimation \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suattributes_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suconv.su.main.convolution_correlation \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/sufwmix.su.main.operations \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suharlan.su.main.noise \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suhistogram.su.main.attributes_parameter_estimation \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suhrot.su.main.multicomponent \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suinterp.su.main.interp_extrap \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suinterpfowler.su.main.interp_extrap \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/sultt.su.main.multicomponent \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumath.su.main.operations \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumax.su.main.attributes_parameter_estimation \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumean.su.main.attributes_parameter_estimation \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumix.su.main.operations \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumixgathers.su.main.windowing_sorting_muting \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/sunormalize.su.main.amplitudes \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suocext.su.main.interp_extrap \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suop.su.main.operations \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suop2.su.main.operations \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suop_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suquantile.su.main.attributes_parameter_estimation \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/surefcon.su.main.convolution_correlation \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/sutaper.su.main.tapering \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suweight.su.main.amplitudes \
	lib/App/SeismicUnixGui/developer/Stripped/statsMath/suxcor.su.main.convolution_correlation \
	lib/App/SeismicUnixGui/developer/Stripped/transform/dctcomp.comp.dct.main \
	lib/App/SeismicUnixGui/developer/Stripped/transform/dctuncomp.comp.dct.main \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suamp.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suamp.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suanalytic.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suanalytic.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/succepstrum.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/succwt.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/sucepstrum.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suclogfft.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suclogfft.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/sucwt.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/sucwt_changes.txt \
	lib/App/SeismicUnixGui/developer/Stripped/transform/sufft.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/sufft.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/sugabor.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suhilb.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suicepstrum.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suiclogfft.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suiclogfft.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suifft.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suminphase.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suminphase.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suphasevel.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suphasevel.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suradon.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suradon.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suslowft.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suslowft.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suslowift.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suslowift.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suspecfk.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suspecfk.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suspecfx.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suspecfx.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suspeck1k2.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suspeck1k2.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/sutaup.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suwfft.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suwfft.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suzerophase.config \
	lib/App/SeismicUnixGui/developer/Stripped/transform/suzerophase.su.main.transforms \
	lib/App/SeismicUnixGui/developer/Stripped/well/las2su.su.main.well_logs \
	lib/App/SeismicUnixGui/developer/Stripped/well/subackus.su.main.well_logs \
	lib/App/SeismicUnixGui/developer/Stripped/well/subackush.su.main.well_logs \
	lib/App/SeismicUnixGui/developer/Stripped/well/sugassman.main.well_logs \
	lib/App/SeismicUnixGui/developer/Stripped/well/sulprime.su.main.well_logs \
	lib/App/SeismicUnixGui/developer/Stripped/well/suwellrf.su.main.well_logs \
	lib/App/SeismicUnixGui/developer/archive/pod/Dialog.pod \
	lib/App/SeismicUnixGui/developer/archive/pod/perl5004delta.pod \
	lib/App/SeismicUnixGui/developer/archive/studio/test_file_read.pl \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/README \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/bck/perltidy.config \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_all.sh \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_big_streams.sh \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_configs.sh \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_geopsy.sh \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_gmt.sh \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_main.sh \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_messages.sh \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_misc.sh \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_specs.sh \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_sqlite.sh \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_sunix.sh \
	lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_unix.sh \
	lib/App/SeismicUnixGui/developer/code/archive/change_a_line.pl \
	lib/App/SeismicUnixGui/developer/code/archive/convert2V07.pl \
	lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package.pm \
	lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_clear.pm \
	lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_declare.pm \
	lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_encapsulated.pm \
	lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_header.pm \
	lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_instantiation.pm \
	lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_pod.pm \
	lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_subroutine.pm \
	lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_tail.pm \
	lib/App/SeismicUnixGui/developer/code/archive/immodpg/kill4mmodpg_development.pl \
	lib/App/SeismicUnixGui/developer/code/archive/insert_line_in_file.pl \
	lib/App/SeismicUnixGui/developer/code/archive/insert_manylines2_in_file.pl \
	lib/App/SeismicUnixGui/developer/code/archive/insert_manylines3_in_file.pl \
	lib/App/SeismicUnixGui/developer/code/archive/insert_manylines_in_file.pl \
	lib/App/SeismicUnixGui/developer/code/archive/insert_two_lines_in_file.pl \
	lib/App/SeismicUnixGui/developer/code/archive/plotting_project/L_su_plot.pl \
	lib/App/SeismicUnixGui/developer/code/archive/plotting_project/PerlTk_plot.pm \
	lib/App/SeismicUnixGui/developer/code/archive/plotting_project/l_suplot \
	lib/App/SeismicUnixGui/developer/code/archive/search_directories.pm \
	lib/App/SeismicUnixGui/developer/code/archive/shell/.FileHistory.txt \
	lib/App/SeismicUnixGui/developer/code/archive/shell/create_evince_doc.pl \
	lib/App/SeismicUnixGui/developer/code/archive/shell/evince.config \
	lib/App/SeismicUnixGui/developer/code/archive/shell/evince.par \
	lib/App/SeismicUnixGui/developer/code/archive/shell/evince.pm \
	lib/App/SeismicUnixGui/developer/code/archive/shell/evince_doc.pm \
	lib/App/SeismicUnixGui/developer/code/archive/shell/evince_doc2pm.pl \
	lib/App/SeismicUnixGui/developer/code/archive/shell/evince_package.pm \
	lib/App/SeismicUnixGui/developer/code/archive/shell/evince_spec.pm \
	lib/App/SeismicUnixGui/developer/code/archive/shell/log.txt \
	lib/App/SeismicUnixGui/developer/code/archive/shell/prog_doc2pm.pm \
	lib/App/SeismicUnixGui/developer/code/archive/shell/sudoc2pm.pl \
	lib/App/SeismicUnixGui/developer/code/archive/shell/sudoc2pm_updates.pl \
	lib/App/SeismicUnixGui/developer/code/archive/shell/sunix_package.pm \
	lib/App/SeismicUnixGui/developer/code/archive/shell/update.pm \
	lib/App/SeismicUnixGui/developer/code/archive/test_incompatibles.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/2.view_1_126_clean.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/My_SeismicUnix.pm \
	lib/App/SeismicUnixGui/developer/code/archive/tests/change_a_line.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/log.txt \
	lib/App/SeismicUnixGui/developer/code/archive/tests/map.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_Exporter.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_INC.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_L_SU_project_selector.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_SeismicUnix.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_config_superflows.pm \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_extends.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_extends_v2.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_extends_v3.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_file.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_file_orig.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_global_libs.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_project_selector.pm \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_quotem.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_quotem1.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_quotem2.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_require.pl \
	lib/App/SeismicUnixGui/developer/code/archive/tests/test_split.pl \
	lib/App/SeismicUnixGui/developer/code/sunix/README.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/change_a_line_everywhere.pl \
	lib/App/SeismicUnixGui/developer/code/sunix/convert2V08.pl \
	lib/App/SeismicUnixGui/developer/code/sunix/copyNclean_sgy_up.pl \
	lib/App/SeismicUnixGui/developer/code/sunix/nameNnumber.txt \
	lib/App/SeismicUnixGui/developer/code/sunix/prog_doc2pm.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/replacelines.pl \
	lib/App/SeismicUnixGui/developer/code/sunix/sudoc.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sudoc2pm_nameNnumber.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sudoc2pm_pt1.pl \
	lib/App/SeismicUnixGui/developer/code/sunix/sudoc2pm_pt2.pl \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_Step.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_clear.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_declaration.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_encapsulated.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_header.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_instantiation.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_note.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_pod.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_pod_header.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_subroutine.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_tail.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_use.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sunix_spec.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/sustkvel_changes.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/update.pm \
	lib/App/SeismicUnixGui/developer/code/sunix/update_main_version_number.pl \
	lib/App/SeismicUnixGui/doc/FAQ_SeismicUnixGui \
	lib/App/SeismicUnixGui/doc/FAQ_immodpg \
	lib/App/SeismicUnixGui/doc/README_to_INSTALL \
	lib/App/SeismicUnixGui/doc/SeismicUnixGuiInstallationGuide0.87.2.pdf \
	lib/App/SeismicUnixGui/doc/SeismicUnixGuiTutorial0.87.2.pdf \
	lib/App/SeismicUnixGui/doc/archive/L_SU\ Tutorial_0.3.6-1.pdf \
	lib/App/SeismicUnixGui/doc/archive/L_SU\ Tutorial_0.3.9.1.docx \
	lib/App/SeismicUnixGui/doc/archive/L_SU\ Tutorial_0.3.9.1.pdf \
	lib/App/SeismicUnixGui/doc/archive/L_SU\ Tutorial_0.4.0.1.pdf \
	lib/App/SeismicUnixGui/doc/archive/L_SU\ Tutorial_0.5.0.pdf \
	lib/App/SeismicUnixGui/doc/archive/L_SU_Installation\ Guide\ 0.3.9.1.docx \
	lib/App/SeismicUnixGui/doc/archive/L_SU_Installation\ Guide\ 0.3.9.1.pdf \
	lib/App/SeismicUnixGui/doc/archive/L_SU_Installation\ Guide\ 0.4.0.0.docx \
	lib/App/SeismicUnixGui/doc/archive/L_SU_Installation\ Guide\ 0.4.0.1.docx \
	lib/App/SeismicUnixGui/doc/archive/L_SU_Installation\ Guide\ 0.4.0.2.pdf \
	lib/App/SeismicUnixGui/doc/archive/L_SU_Installation\ Guide\ 0.4.5.0.pdf \
	lib/App/SeismicUnixGui/doc/archive/L_SU_Installation\ and\ Developer\ Guide_0.3.7-1.pdf \
	lib/App/SeismicUnixGui/doc/archive/L_SU_Installation_Guide_0.6.6.3.docx \
	lib/App/SeismicUnixGui/doc/archive/L_SU_Installation_Guide_0.7.0.0.docx \
	lib/App/SeismicUnixGui/doc/archive/L_SU_Installation_Guide_0.7.0.0.pdf \
	lib/App/SeismicUnixGui/doc/archive/Notes_V0 \
	lib/App/SeismicUnixGui/doc/archive/Notes_V1 \
	lib/App/SeismicUnixGui/doc/archive/README \
	lib/App/SeismicUnixGui/doc/documentation_conversion/.FileHistory.txt \
	lib/App/SeismicUnixGui/doc/documentation_conversion/pod2htmd.tmp \
	lib/App/SeismicUnixGui/doc/documentation_conversion/pod2rst.sh \
	lib/App/SeismicUnixGui/doc/documentation_conversion/suop.html \
	lib/App/SeismicUnixGui/doc/documentation_conversion/suop.markdown \
	lib/App/SeismicUnixGui/doc/documentation_conversion/suop.pm \
	lib/App/SeismicUnixGui/doc/documentation_conversion/suop.rst \
	lib/App/SeismicUnixGui/doc/documentation_conversion/suop_2.rst \
	lib/App/SeismicUnixGui/fortran/.FileHistory.txt \
	lib/App/SeismicUnixGui/fortran/Makefile \
	lib/App/SeismicUnixGui/fortran/archive/P2 \
	lib/App/SeismicUnixGui/fortran/archive/ar \
	lib/App/SeismicUnixGui/fortran/archive/immodpg.out \
	lib/App/SeismicUnixGui/fortran/archive/mmodpg.config \
	lib/App/SeismicUnixGui/fortran/archive/mmodpg.config_bck \
	lib/App/SeismicUnixGui/fortran/archive/mmodpg_config_master \
	lib/App/SeismicUnixGui/fortran/archive/model1 \
	lib/App/SeismicUnixGui/fortran/archive/process_P.pl \
	lib/App/SeismicUnixGui/fortran/archive/src/bck/Makefile \
	lib/App/SeismicUnixGui/fortran/archive/src/bck/data1.dat \
	lib/App/SeismicUnixGui/fortran/archive/src/bck/main.f \
	lib/App/SeismicUnixGui/fortran/archive/src/bck/makefile \
	lib/App/SeismicUnixGui/fortran/archive/src/bck/read.f \
	lib/App/SeismicUnixGui/fortran/archive/src/bck/read_1col.f \
	lib/App/SeismicUnixGui/fortran/archive/src/bck/run.sh \
	lib/App/SeismicUnixGui/fortran/archive/src/bck/write_1col.f \
	lib/App/SeismicUnixGui/fortran/archive/src/data1.dat \
	lib/App/SeismicUnixGui/fortran/archive/src/denfvp.for \
	lib/App/SeismicUnixGui/fortran/archive/src/main.f \
	lib/App/SeismicUnixGui/fortran/archive/src/main_read_from_fifo.f \
	lib/App/SeismicUnixGui/fortran/archive/src/messa.for \
	lib/App/SeismicUnixGui/fortran/archive/src/mmodpg.for \
	lib/App/SeismicUnixGui/fortran/archive/src/pgzoom.for \
	lib/App/SeismicUnixGui/fortran/archive/src/read_1col.f \
	lib/App/SeismicUnixGui/fortran/archive/src/read_1col_int.f \
	lib/App/SeismicUnixGui/fortran/archive/src/read_layer_file.f \
	lib/App/SeismicUnixGui/fortran/archive/src/read_mmodpg_config.f \
	lib/App/SeismicUnixGui/fortran/archive/src/read_option_file.f \
	lib/App/SeismicUnixGui/fortran/archive/src/read_yes_no_file.f \
	lib/App/SeismicUnixGui/fortran/archive/src/readmmod.for \
	lib/App/SeismicUnixGui/fortran/archive/src/readpar.for \
	lib/App/SeismicUnixGui/fortran/archive/src/thi.for \
	lib/App/SeismicUnixGui/fortran/archive/src/txgrd.for \
	lib/App/SeismicUnixGui/fortran/archive/src/txpr.for \
	lib/App/SeismicUnixGui/fortran/archive/src/wrimod2.for \
	lib/App/SeismicUnixGui/fortran/archive/src/write_1col.f \
	lib/App/SeismicUnixGui/fortran/archive/sw \
	lib/App/SeismicUnixGui/fortran/archive/write_2fifo.pl \
	lib/App/SeismicUnixGui/fortran/archive/write_test.pl \
	lib/App/SeismicUnixGui/fortran/archive/xtra_code/read.f \
	lib/App/SeismicUnixGui/fortran/bin/immodpg1.1 \
	lib/App/SeismicUnixGui/fortran/bin/stdsleep \
	lib/App/SeismicUnixGui/fortran/obj/Project_config.o \
	lib/App/SeismicUnixGui/fortran/obj/denfvp.o \
	lib/App/SeismicUnixGui/fortran/obj/immodpg.o \
	lib/App/SeismicUnixGui/fortran/obj/messa.o \
	lib/App/SeismicUnixGui/fortran/obj/moveNzoom.o \
	lib/App/SeismicUnixGui/fortran/obj/rdata.o \
	lib/App/SeismicUnixGui/fortran/obj/readVbotNtop_factor_file.o \
	lib/App/SeismicUnixGui/fortran/obj/readVbot_file.o \
	lib/App/SeismicUnixGui/fortran/obj/readVbot_upper_file.o \
	lib/App/SeismicUnixGui/fortran/obj/readVincrement_file.o \
	lib/App/SeismicUnixGui/fortran/obj/readVtop_file.o \
	lib/App/SeismicUnixGui/fortran/obj/readVtop_lower_file.o \
	lib/App/SeismicUnixGui/fortran/obj/read_bin_data.o \
	lib/App/SeismicUnixGui/fortran/obj/read_clip_file.o \
	lib/App/SeismicUnixGui/fortran/obj/read_dataxy.o \
	lib/App/SeismicUnixGui/fortran/obj/read_immodpg_config.o \
	lib/App/SeismicUnixGui/fortran/obj/read_layer_file.o \
	lib/App/SeismicUnixGui/fortran/obj/read_option_file.o \
	lib/App/SeismicUnixGui/fortran/obj/read_parmmod_file.o \
	lib/App/SeismicUnixGui/fortran/obj/read_thickness_increment_m_file.o \
	lib/App/SeismicUnixGui/fortran/obj/read_thickness_m_file.o \
	lib/App/SeismicUnixGui/fortran/obj/read_yes_no_file.o \
	lib/App/SeismicUnixGui/fortran/obj/readmmod.o \
	lib/App/SeismicUnixGui/fortran/obj/readpar.o \
	lib/App/SeismicUnixGui/fortran/obj/stdsleep.o \
	lib/App/SeismicUnixGui/fortran/obj/thi.o \
	lib/App/SeismicUnixGui/fortran/obj/txgrd.o \
	lib/App/SeismicUnixGui/fortran/obj/txpr.o \
	lib/App/SeismicUnixGui/fortran/obj/wrimod2.o \
	lib/App/SeismicUnixGui/fortran/obj/write_model_file_text.o \
	lib/App/SeismicUnixGui/fortran/obj/write_yes_no_file.o \
	lib/App/SeismicUnixGui/fortran/pl/.mmodpg/change \
	lib/App/SeismicUnixGui/fortran/pl/datammod \
	lib/App/SeismicUnixGui/fortran/pl/mmodpg.config \
	lib/App/SeismicUnixGui/fortran/pl/mmodpg.out \
	lib/App/SeismicUnixGui/fortran/pl/model1 \
	lib/App/SeismicUnixGui/fortran/pl/parmmod \
	lib/App/SeismicUnixGui/fortran/posix.mod \
	lib/App/SeismicUnixGui/fortran/run_me_only.sh \
	lib/App/SeismicUnixGui/fortran/src/Project_config.f \
	lib/App/SeismicUnixGui/fortran/src/archive/Makefile \
	lib/App/SeismicUnixGui/fortran/src/archive/main.f \
	lib/App/SeismicUnixGui/fortran/src/archive/main_read_from_fifo.f \
	lib/App/SeismicUnixGui/fortran/src/archive/makefile \
	lib/App/SeismicUnixGui/fortran/src/archive/panNzoom.for \
	lib/App/SeismicUnixGui/fortran/src/archive/readVtop_lower_file_bck.f \
	lib/App/SeismicUnixGui/fortran/src/archive/read_1col.f \
	lib/App/SeismicUnixGui/fortran/src/archive/read_1col_int.f \
	lib/App/SeismicUnixGui/fortran/src/archive/read_bin_data_bck2.f \
	lib/App/SeismicUnixGui/fortran/src/archive/write_1col.f \
	lib/App/SeismicUnixGui/fortran/src/archive/write_option_file.f \
	lib/App/SeismicUnixGui/fortran/src/denfvp.for \
	lib/App/SeismicUnixGui/fortran/src/immodpg.for \
	lib/App/SeismicUnixGui/fortran/src/messa.for \
	lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/mmodpg.for \
	lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/mmodpg2.for \
	lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/ns_y_sn.su \
	lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/ns_y_sn.xt \
	lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/pgplot.inc \
	lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/pgpolyev.for \
	lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/vmodns_sn \
	lib/App/SeismicUnixGui/fortran/src/moveNzoom.for \
	lib/App/SeismicUnixGui/fortran/src/pgzoom.for \
	lib/App/SeismicUnixGui/fortran/src/rdata.for \
	lib/App/SeismicUnixGui/fortran/src/readVbotNtop_factor_file.f \
	lib/App/SeismicUnixGui/fortran/src/readVbot_file.f \
	lib/App/SeismicUnixGui/fortran/src/readVbot_upper_file.f \
	lib/App/SeismicUnixGui/fortran/src/readVincrement_file.f \
	lib/App/SeismicUnixGui/fortran/src/readVtop_file.f \
	lib/App/SeismicUnixGui/fortran/src/readVtop_lower_file.f \
	lib/App/SeismicUnixGui/fortran/src/read_bin_data.f \
	lib/App/SeismicUnixGui/fortran/src/read_clip_file.f \
	lib/App/SeismicUnixGui/fortran/src/read_dataxy.for \
	lib/App/SeismicUnixGui/fortran/src/read_immodpg_config.f \
	lib/App/SeismicUnixGui/fortran/src/read_layer_file.f \
	lib/App/SeismicUnixGui/fortran/src/read_option_file.f \
	lib/App/SeismicUnixGui/fortran/src/read_panNzoom_file.f \
	lib/App/SeismicUnixGui/fortran/src/read_parmmod_file.f \
	lib/App/SeismicUnixGui/fortran/src/read_thickness_increment_m_file.f \
	lib/App/SeismicUnixGui/fortran/src/read_thickness_m_file.f \
	lib/App/SeismicUnixGui/fortran/src/read_yes_no_file.f \
	lib/App/SeismicUnixGui/fortran/src/readmmod.for \
	lib/App/SeismicUnixGui/fortran/src/readpar.for \
	lib/App/SeismicUnixGui/fortran/src/stdsleep.f \
	lib/App/SeismicUnixGui/fortran/src/thi.for \
	lib/App/SeismicUnixGui/fortran/src/txgrd.for \
	lib/App/SeismicUnixGui/fortran/src/txpr.for \
	lib/App/SeismicUnixGui/fortran/src/wrimod2.for \
	lib/App/SeismicUnixGui/fortran/src/write_model_file_text.f \
	lib/App/SeismicUnixGui/fortran/src/write_yes_no_file.f \
	lib/App/SeismicUnixGui/geopsy/dinver.pm \
	lib/App/SeismicUnixGui/geopsy/gpdcreport.pm \
	lib/App/SeismicUnixGui/geopsy/gphistogram.pm \
	lib/App/SeismicUnixGui/geopsy/gpprofile.pm \
	lib/App/SeismicUnixGui/geopsy/gpviewdcreport.pm \
	lib/App/SeismicUnixGui/images/cross.ppm \
	lib/App/SeismicUnixGui/images/cross.xpm \
	lib/App/SeismicUnixGui/images/file_item_down_arrow-mask.xbm \
	lib/App/SeismicUnixGui/images/file_item_down_arrow.xbm \
	lib/App/SeismicUnixGui/images/file_item_down_arrow.xcf \
	lib/App/SeismicUnixGui/images/file_item_up_arrow-mask.xbm \
	lib/App/SeismicUnixGui/images/file_item_up_arrow.xbm \
	lib/App/SeismicUnixGui/images/file_item_up_arrow.xcf \
	lib/App/SeismicUnixGui/images/file_item_up_arrow.xpm \
	lib/App/SeismicUnixGui/images/minus.xbm \
	lib/App/SeismicUnixGui/images/minus.xcf \
	lib/App/SeismicUnixGui/images/minus.xpm \
	lib/App/SeismicUnixGui/images/working\ images/Screenshot\ from\ 2019-08-28\ 17-45-12.png \
	lib/App/SeismicUnixGui/images/working\ images/Untitled.xbm \
	lib/App/SeismicUnixGui/images/working\ images/cross.ppm \
	lib/App/SeismicUnixGui/images/working\ images/cross.svg \
	lib/App/SeismicUnixGui/images/working\ images/cross.xcf \
	lib/App/SeismicUnixGui/images/working\ images/lightning-mask.xbm \
	lib/App/SeismicUnixGui/images/working\ images/lightning.pbm \
	lib/App/SeismicUnixGui/images/working\ images/lightning.png \
	lib/App/SeismicUnixGui/images/working\ images/lightning.svg \
	lib/App/SeismicUnixGui/images/working\ images/lightning.xbm \
	lib/App/SeismicUnixGui/images/working\ images/lightning.xcf \
	lib/App/SeismicUnixGui/images/working\ images/lightning.xpm \
	lib/App/SeismicUnixGui/messages/About.pm \
	lib/App/SeismicUnixGui/messages/FileDialog_button_messages.pm \
	lib/App/SeismicUnixGui/messages/FileDialog_close_messages.pm \
	lib/App/SeismicUnixGui/messages/SuMessages.pm \
	lib/App/SeismicUnixGui/messages/archive/About.pm_bck \
	lib/App/SeismicUnixGui/messages/archive/help_button_messages.pm_bck \
	lib/App/SeismicUnixGui/messages/archive/help_button_messages_old.pm \
	lib/App/SeismicUnixGui/messages/backup_project_selector_messages.pm \
	lib/App/SeismicUnixGui/messages/color_listbox_messages.pm \
	lib/App/SeismicUnixGui/messages/flows_messages.pm \
	lib/App/SeismicUnixGui/messages/help_button_messages.pm \
	lib/App/SeismicUnixGui/messages/iPick_messages.pm \
	lib/App/SeismicUnixGui/messages/immodpg_messages.pm \
	lib/App/SeismicUnixGui/messages/message_director.pm \
	lib/App/SeismicUnixGui/messages/notes.pl \
	lib/App/SeismicUnixGui/messages/null_messages.pm \
	lib/App/SeismicUnixGui/messages/project_selector_messages.pm \
	lib/App/SeismicUnixGui/messages/run_button_messages.pm \
	lib/App/SeismicUnixGui/messages/save_button_messages.pm \
	lib/App/SeismicUnixGui/messages/superflow_messages.pm \
	lib/App/SeismicUnixGui/misc/L_SU.pm \
	lib/App/SeismicUnixGui/misc/L_SU_global_constants.pm \
	lib/App/SeismicUnixGui/misc/L_SU_local_user_constants.pm \
	lib/App/SeismicUnixGui/misc/L_SU_path.pm \
	lib/App/SeismicUnixGui/misc/Math.pm \
	lib/App/SeismicUnixGui/misc/PID.pm \
	lib/App/SeismicUnixGui/misc/Project_Variables.pm \
	lib/App/SeismicUnixGui/misc/SeismicUnix.pm \
	lib/App/SeismicUnixGui/misc/a2su.pm \
	lib/App/SeismicUnixGui/misc/algebra_by.pm \
	lib/App/SeismicUnixGui/misc/archive/L_SU_global_constants.pm \
	lib/App/SeismicUnixGui/misc/archive/L_SU_global_constants.pm_bck \
	lib/App/SeismicUnixGui/misc/archive/Point.pm \
	lib/App/SeismicUnixGui/misc/archive/backup_project_selector.pm \
	lib/App/SeismicUnixGui/misc/archive/binding2.pm \
	lib/App/SeismicUnixGui/misc/archive/canvas_data.pm \
	lib/App/SeismicUnixGui/misc/archive/canvas_graph.pm \
	lib/App/SeismicUnixGui/misc/archive/control.pm \
	lib/App/SeismicUnixGui/misc/archive/pdl_su.pm \
	lib/App/SeismicUnixGui/misc/archive/segdread.pm \
	lib/App/SeismicUnixGui/misc/archive/t \
	lib/App/SeismicUnixGui/misc/array.pm \
	lib/App/SeismicUnixGui/misc/big_streams_param.pm \
	lib/App/SeismicUnixGui/misc/binding.pm \
	lib/App/SeismicUnixGui/misc/blue_flow.pm \
	lib/App/SeismicUnixGui/misc/check_buttons.pm \
	lib/App/SeismicUnixGui/misc/cmpcc.pm \
	lib/App/SeismicUnixGui/misc/color_listbox.pm \
	lib/App/SeismicUnixGui/misc/conditions4big_streams.pm \
	lib/App/SeismicUnixGui/misc/conditions4flows.pm \
	lib/App/SeismicUnixGui/misc/config_superflows.pm \
	lib/App/SeismicUnixGui/misc/control.pm \
	lib/App/SeismicUnixGui/misc/copyNclean_sgy_up.pl \
	lib/App/SeismicUnixGui/misc/count.pm \
	lib/App/SeismicUnixGui/misc/cps.pm \
	lib/App/SeismicUnixGui/misc/decisions.pm \
	lib/App/SeismicUnixGui/misc/developer.pm \
	lib/App/SeismicUnixGui/misc/dirs.pm \
	lib/App/SeismicUnixGui/misc/error.pm \
	lib/App/SeismicUnixGui/misc/file_dialog.pm \
	lib/App/SeismicUnixGui/misc/files_LSU.pm \
	lib/App/SeismicUnixGui/misc/flow.pm \
	lib/App/SeismicUnixGui/misc/flow_widgets.pm \
	lib/App/SeismicUnixGui/misc/geometry_pack.pm \
	lib/App/SeismicUnixGui/misc/get_pod_run_flows.pm \
	lib/App/SeismicUnixGui/misc/green_flow.pm \
	lib/App/SeismicUnixGui/misc/grey_flow.pm \
	lib/App/SeismicUnixGui/misc/gui_history.pm \
	lib/App/SeismicUnixGui/misc/help.pm \
	lib/App/SeismicUnixGui/misc/iFile.pm \
	lib/App/SeismicUnixGui/misc/junk \
	lib/App/SeismicUnixGui/misc/label_boxes.pm \
	lib/App/SeismicUnixGui/misc/manage_dirs_by.pm \
	lib/App/SeismicUnixGui/misc/manage_files_by.pm \
	lib/App/SeismicUnixGui/misc/manage_files_by2.pm \
	lib/App/SeismicUnixGui/misc/message.pm \
	lib/App/SeismicUnixGui/misc/mkparfile.pm \
	lib/App/SeismicUnixGui/misc/name.pm \
	lib/App/SeismicUnixGui/misc/neutral_flow.pm \
	lib/App/SeismicUnixGui/misc/new_pkg.pm \
	lib/App/SeismicUnixGui/misc/old_data.pm \
	lib/App/SeismicUnixGui/misc/oop_declaration_defaults.pm \
	lib/App/SeismicUnixGui/misc/oop_declare_data_in.pm \
	lib/App/SeismicUnixGui/misc/oop_declare_data_out.pm \
	lib/App/SeismicUnixGui/misc/oop_declare_pkg.pm \
	lib/App/SeismicUnixGui/misc/oop_flows.pm \
	lib/App/SeismicUnixGui/misc/oop_inbound.pm \
	lib/App/SeismicUnixGui/misc/oop_instantiation_defaults.pm \
	lib/App/SeismicUnixGui/misc/oop_log_flows.pm \
	lib/App/SeismicUnixGui/misc/oop_pod_header.pm \
	lib/App/SeismicUnixGui/misc/oop_print_flows.pm \
	lib/App/SeismicUnixGui/misc/oop_prog_params.pm \
	lib/App/SeismicUnixGui/misc/oop_run_flows.pm \
	lib/App/SeismicUnixGui/misc/oop_text.pm \
	lib/App/SeismicUnixGui/misc/oop_use_pkg.pm \
	lib/App/SeismicUnixGui/misc/param.pm \
	lib/App/SeismicUnixGui/misc/param_flow.pm \
	lib/App/SeismicUnixGui/misc/param_flow_blue.pm \
	lib/App/SeismicUnixGui/misc/param_flow_green.pm \
	lib/App/SeismicUnixGui/misc/param_flow_grey.pm \
	lib/App/SeismicUnixGui/misc/param_flow_neutral.pm \
	lib/App/SeismicUnixGui/misc/param_flow_pink.pm \
	lib/App/SeismicUnixGui/misc/param_sunix.pm \
	lib/App/SeismicUnixGui/misc/param_widgets.pm \
	lib/App/SeismicUnixGui/misc/param_widgets4pre_built_streams.pm \
	lib/App/SeismicUnixGui/misc/param_widgets_blue.pm \
	lib/App/SeismicUnixGui/misc/param_widgets_green.pm \
	lib/App/SeismicUnixGui/misc/param_widgets_grey.pm \
	lib/App/SeismicUnixGui/misc/param_widgets_neutral.pm \
	lib/App/SeismicUnixGui/misc/param_widgets_pink.pm \
	lib/App/SeismicUnixGui/misc/perl_declare.pm \
	lib/App/SeismicUnixGui/misc/perl_flow.pm \
	lib/App/SeismicUnixGui/misc/perl_header.pm \
	lib/App/SeismicUnixGui/misc/perl_inbound.pm \
	lib/App/SeismicUnixGui/misc/perl_instantiate.pm \
	lib/App/SeismicUnixGui/misc/perl_use_pkg.pm \
	lib/App/SeismicUnixGui/misc/pink_flow.pm \
	lib/App/SeismicUnixGui/misc/plot.pm \
	lib/App/SeismicUnixGui/misc/pm_io.pm \
	lib/App/SeismicUnixGui/misc/pod_declare.pm \
	lib/App/SeismicUnixGui/misc/pod_flows.pm \
	lib/App/SeismicUnixGui/misc/pod_log_flows.pm \
	lib/App/SeismicUnixGui/misc/pod_prog_param_setup.pm \
	lib/App/SeismicUnixGui/misc/pod_run_flows.pm \
	lib/App/SeismicUnixGui/misc/premmod.pm \
	lib/App/SeismicUnixGui/misc/program_name.pm \
	lib/App/SeismicUnixGui/misc/project_selector.pm \
	lib/App/SeismicUnixGui/misc/read_psunix.pm \
	lib/App/SeismicUnixGui/misc/readfiles.pm \
	lib/App/SeismicUnixGui/misc/redisplay.pm \
	lib/App/SeismicUnixGui/misc/run_button.pm \
	lib/App/SeismicUnixGui/misc/save.pm \
	lib/App/SeismicUnixGui/misc/save_button.pm \
	lib/App/SeismicUnixGui/misc/save_button_messages.pm \
	lib/App/SeismicUnixGui/misc/seismics.pm \
	lib/App/SeismicUnixGui/misc/smooth2.pm \
	lib/App/SeismicUnixGui/misc/su_param.pm \
	lib/App/SeismicUnixGui/misc/su_select_waveform.pm \
	lib/App/SeismicUnixGui/misc/su_spectral_analysis.pm \
	lib/App/SeismicUnixGui/misc/su_xtract_waveform.pm \
	lib/App/SeismicUnixGui/misc/sudata_in.pm \
	lib/App/SeismicUnixGui/misc/sunix_pl.pm \
	lib/App/SeismicUnixGui/misc/superflows_config.pm \
	lib/App/SeismicUnixGui/misc/system.pm \
	lib/App/SeismicUnixGui/misc/tbd.pl \
	lib/App/SeismicUnixGui/misc/unif2.pm \
	lib/App/SeismicUnixGui/misc/use_pkg.pm \
	lib/App/SeismicUnixGui/misc/value_boxes.pm \
	lib/App/SeismicUnixGui/misc/whereami.pm \
	lib/App/SeismicUnixGui/misc/whereami2.pm \
	lib/App/SeismicUnixGui/misc/wipe.pm \
	lib/App/SeismicUnixGui/misc/write_LSU.pm \
	lib/App/SeismicUnixGui/misc/writefiles.pm \
	lib/App/SeismicUnixGui/script/.FileHistory.txt \
	lib/App/SeismicUnixGui/script/BackupProject \
	lib/App/SeismicUnixGui/script/LICENSE \
	lib/App/SeismicUnixGui/script/L_SU.pl \
	lib/App/SeismicUnixGui/script/L_SU_project_selector.pl \
	lib/App/SeismicUnixGui/script/Project \
	lib/App/SeismicUnixGui/script/RestoreProject \
	lib/App/SeismicUnixGui/script/RestoreTutorial \
	lib/App/SeismicUnixGui/script/SeismicUnixGui \
	lib/App/SeismicUnixGui/script/SetProject \
	lib/App/SeismicUnixGui/script/Sseg2su \
	lib/App/SeismicUnixGui/script/Sucat \
	lib/App/SeismicUnixGui/script/Sudipfilt \
	lib/App/SeismicUnixGui/script/Synseis \
	lib/App/SeismicUnixGui/script/archive/L_SU.pl \
	lib/App/SeismicUnixGui/script/archive/L_SU.pl_bck \
	lib/App/SeismicUnixGui/script/archive/set_env_variables.sh \
	lib/App/SeismicUnixGui/script/archive/tbd.pl \
	lib/App/SeismicUnixGui/script/convert2V08 \
	lib/App/SeismicUnixGui/script/copyNclean_sgy_up \
	lib/App/SeismicUnixGui/script/iBottomMute \
	lib/App/SeismicUnixGui/script/iPick \
	lib/App/SeismicUnixGui/script/iSA \
	lib/App/SeismicUnixGui/script/iSpectralAnalysis \
	lib/App/SeismicUnixGui/script/iTopMute \
	lib/App/SeismicUnixGui/script/iVA \
	lib/App/SeismicUnixGui/script/immodpg \
	lib/App/SeismicUnixGui/script/post_install_c_compile.pl \
	lib/App/SeismicUnixGui/script/post_install_env.pl \
	lib/App/SeismicUnixGui/script/post_install_fortran_compile.pl \
	lib/App/SeismicUnixGui/script/post_install_scripts.sh \
	lib/App/SeismicUnixGui/script/set_env_variables.sh \
	lib/App/SeismicUnixGui/script/tbd \
	lib/App/SeismicUnixGui/script/xk \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/dzdv_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sucvs4fowler_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudivstack_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmofk_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmofkcw_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmotivz_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmotx_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmovz_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suilog_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suintvel_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sulog_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sunmo_a_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sunmo_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/supws_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/surecip_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sureduce_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/surelan_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/surelanan_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suresamp_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sushift_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sustack_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sustkvel_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sutaupnmo_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sutihaledmo_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sutivel_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sutsq_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suttoz_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suvel2df_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suvelan_nccs_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suvelan_nsel_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suvelan_spec.pm \
	lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suztot_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/BackupProject_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/Project_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/RestoreProject_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/Sseg2su_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/Sucat_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/Sucat_specB.pm \
	lib/App/SeismicUnixGui/specs/big_streams/Sudipfilt_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/Synseis_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/iBottomMute_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/iPick_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/iPick_specB.pm \
	lib/App/SeismicUnixGui/specs/big_streams/iPick_specC.pm \
	lib/App/SeismicUnixGui/specs/big_streams/iPick_specD.pm \
	lib/App/SeismicUnixGui/specs/big_streams/iSpectralAnalysis_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/iTopMute_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/iVA_spec.pm \
	lib/App/SeismicUnixGui/specs/big_streams/immodpg_spec.pm \
	lib/App/SeismicUnixGui/specs/data/ctrlstrip_spec.pm \
	lib/App/SeismicUnixGui/specs/data/data_in_spec.pm \
	lib/App/SeismicUnixGui/specs/data/data_out_spec.pm \
	lib/App/SeismicUnixGui/specs/data/dt1tosu_spec.pm \
	lib/App/SeismicUnixGui/specs/data/segbread_spec.pm \
	lib/App/SeismicUnixGui/specs/data/segdread_spec.pm \
	lib/App/SeismicUnixGui/specs/data/segyread_spec.pm \
	lib/App/SeismicUnixGui/specs/data/segyscan_spec.pm \
	lib/App/SeismicUnixGui/specs/data/segywrite_spec.pm \
	lib/App/SeismicUnixGui/specs/data/suoldtonew_spec.pm \
	lib/App/SeismicUnixGui/specs/data/supack1_spec.pm \
	lib/App/SeismicUnixGui/specs/data/supack2_spec.pm \
	lib/App/SeismicUnixGui/specs/data/suswapbytes_spec.pm \
	lib/App/SeismicUnixGui/specs/data/suunpack1_spec.pm \
	lib/App/SeismicUnixGui/specs/data/suunpack2_spec.pm \
	lib/App/SeismicUnixGui/specs/data/wpc1uncomp2_spec.pm \
	lib/App/SeismicUnixGui/specs/data/wpccompress_spec.pm \
	lib/App/SeismicUnixGui/specs/data/wpcuncompress_spec.pm \
	lib/App/SeismicUnixGui/specs/data/wptcomp_spec.pm \
	lib/App/SeismicUnixGui/specs/data/wptuncomp_spec.pm \
	lib/App/SeismicUnixGui/specs/data/wtcomp_spec.pm \
	lib/App/SeismicUnixGui/specs/data/wtuncomp_spec.pm \
	lib/App/SeismicUnixGui/specs/datum/sudatumk2dr_spec.pm \
	lib/App/SeismicUnixGui/specs/datum/sudatumk2ds_spec.pm \
	lib/App/SeismicUnixGui/specs/datum/sukdmdcr_spec.pm \
	lib/App/SeismicUnixGui/specs/datum/sukdmdcs_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/subfilt_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/succfilt_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/sucddecon_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/sudipfilt_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/sueipofi_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/sufilter_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/sufrac_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/sufwatrim_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/sufxdecon_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/sugroll_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/suk1k2filter_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/sukfilter_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/sulfaf_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/sumedian_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/supef_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/suphase_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/suphidecon_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/supofilt_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/supolar_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/susmgauss2_spec.pm \
	lib/App/SeismicUnixGui/specs/filter/sutvband_spec.pm \
	lib/App/SeismicUnixGui/specs/header/segyclean_spec.pm \
	lib/App/SeismicUnixGui/specs/header/segyhdrmod_spec.pm \
	lib/App/SeismicUnixGui/specs/header/segyhdrs_spec.pm \
	lib/App/SeismicUnixGui/specs/header/setbhed_spec.pm \
	lib/App/SeismicUnixGui/specs/header/su3dchart_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suabshw_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suaddhead_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suaddstatics_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suahw_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suascii_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suazimuth_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sucdpbin_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suchart_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suchw_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sucliphead_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sucountkey_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sudumptrace_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suedit_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sugethw_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suhtmath_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sukeycount_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sulcthw_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sulhead_spec.pm \
	lib/App/SeismicUnixGui/specs/header/supaste_spec.pm \
	lib/App/SeismicUnixGui/specs/header/surandhw_spec.pm \
	lib/App/SeismicUnixGui/specs/header/surange_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suresstat_spec.pm \
	lib/App/SeismicUnixGui/specs/header/susehw_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sushw_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sustaticB_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sustatic_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sustaticrrs_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sustrip_spec.pm \
	lib/App/SeismicUnixGui/specs/header/sutrcount_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suutm_spec.pm \
	lib/App/SeismicUnixGui/specs/header/suxedit_spec.pm \
	lib/App/SeismicUnixGui/specs/header/swapbhed_spec.pm \
	lib/App/SeismicUnixGui/specs/inversion/suinvco3d_spec.pm \
	lib/App/SeismicUnixGui/specs/inversion/suinvvxzco_spec.pm \
	lib/App/SeismicUnixGui/specs/inversion/suinvzco3d_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sudatumfd_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sugazmig_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sukdmig2d_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sukdmig3d_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/suktmig2d_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumigfd_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumigffd_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumiggbzo_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumiggbzoan_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumigprefd_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumigpreffd_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumigprepspi_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumigpresp_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumigps_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumigpspi_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumigpsti_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumigsplit_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumigtk_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sumigtopo2d_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sustolt_spec.pm \
	lib/App/SeismicUnixGui/specs/migration/sutifowler_spec.pm \
	lib/App/SeismicUnixGui/specs/model/addrvl3d_spec.pm \
	lib/App/SeismicUnixGui/specs/model/cellauto_spec.pm \
	lib/App/SeismicUnixGui/specs/model/elacheck_spec.pm \
	lib/App/SeismicUnixGui/specs/model/elamodel_spec.pm \
	lib/App/SeismicUnixGui/specs/model/elaray_spec.pm \
	lib/App/SeismicUnixGui/specs/model/elasyn_spec.pm \
	lib/App/SeismicUnixGui/specs/model/elatriuni_spec.pm \
	lib/App/SeismicUnixGui/specs/model/gbbeam_spec.pm \
	lib/App/SeismicUnixGui/specs/model/grm_spec.pm \
	lib/App/SeismicUnixGui/specs/model/normray_spec.pm \
	lib/App/SeismicUnixGui/specs/model/raydata_spec.pm \
	lib/App/SeismicUnixGui/specs/model/suaddevent_spec.pm \
	lib/App/SeismicUnixGui/specs/model/suaddnoise_spec.pm \
	lib/App/SeismicUnixGui/specs/model/sudgwaveform_spec.pm \
	lib/App/SeismicUnixGui/specs/model/suea2df_spec.pm \
	lib/App/SeismicUnixGui/specs/model/sufctanismod_spec.pm \
	lib/App/SeismicUnixGui/specs/model/sufdmod1_spec.pm \
	lib/App/SeismicUnixGui/specs/model/sufdmod2_pml_spec.pm \
	lib/App/SeismicUnixGui/specs/model/sufdmod2_spec.pm \
	lib/App/SeismicUnixGui/specs/model/sugoupillaud_spec.pm \
	lib/App/SeismicUnixGui/specs/model/sugoupillaudpo_spec.pm \
	lib/App/SeismicUnixGui/specs/model/suimp2d_spec.pm \
	lib/App/SeismicUnixGui/specs/model/suimp3d_spec.pm \
	lib/App/SeismicUnixGui/specs/model/suimpedance_spec.pm \
	lib/App/SeismicUnixGui/specs/model/sujitter_spec.pm \
	lib/App/SeismicUnixGui/specs/model/sukdsyn2d_spec.pm \
	lib/App/SeismicUnixGui/specs/model/sunull_spec.pm \
	lib/App/SeismicUnixGui/specs/model/suplane_spec.pm \
	lib/App/SeismicUnixGui/specs/model/surandspike_spec.pm \
	lib/App/SeismicUnixGui/specs/model/surandstat_spec.pm \
	lib/App/SeismicUnixGui/specs/model/suremac2d_spec.pm \
	lib/App/SeismicUnixGui/specs/model/suremel2dan_spec.pm \
	lib/App/SeismicUnixGui/specs/model/suspike_spec.pm \
	lib/App/SeismicUnixGui/specs/model/susyncz_spec.pm \
	lib/App/SeismicUnixGui/specs/model/susynlv_spec.pm \
	lib/App/SeismicUnixGui/specs/model/susynlvcw_spec.pm \
	lib/App/SeismicUnixGui/specs/model/susynlvfti_spec.pm \
	lib/App/SeismicUnixGui/specs/model/susynvxz_spec.pm \
	lib/App/SeismicUnixGui/specs/model/susynvxzcs_spec.pm \
	lib/App/SeismicUnixGui/specs/par/a2b_spec.pm \
	lib/App/SeismicUnixGui/specs/par/a2i_spec.pm \
	lib/App/SeismicUnixGui/specs/par/b2a_spec.pm \
	lib/App/SeismicUnixGui/specs/par/bhedtopar_spec.pm \
	lib/App/SeismicUnixGui/specs/par/cshotplot_spec.pm \
	lib/App/SeismicUnixGui/specs/par/float2ibm_spec.pm \
	lib/App/SeismicUnixGui/specs/par/ftnstrip_spec.pm \
	lib/App/SeismicUnixGui/specs/par/ftnunstrip_spec.pm \
	lib/App/SeismicUnixGui/specs/par/makevel_spec.pm \
	lib/App/SeismicUnixGui/specs/par/mkparfile_spec.pm \
	lib/App/SeismicUnixGui/specs/par/transp_spec.pm \
	lib/App/SeismicUnixGui/specs/par/unif2_spec.pm \
	lib/App/SeismicUnixGui/specs/par/unif2aniso_spec.pm \
	lib/App/SeismicUnixGui/specs/par/unisam2_spec.pm \
	lib/App/SeismicUnixGui/specs/par/unisam_spec.pm \
	lib/App/SeismicUnixGui/specs/par/vel2stiff_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/elaps_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/lcmap_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/lprop_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/psbbox_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/pscontour_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/pscube_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/pscubecontour_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/psepsi_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/psgraph_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/psimage_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/pslabel_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/psmanager_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/psmerge_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/psmovie_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/pswigb_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/pswigp_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/scmap_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/spsplot_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/supscontour_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/supscube_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/supscubecontour_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/supsgraph_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/supsimage_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/supsmax_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/supsmovie_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/supswigb_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/supswigp_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/suxcontour_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/suxgraph_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/suximage_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/suxmax_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/suxmovie_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/suxpicker_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/suxwigb_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/xcontour_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/xgraph_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/ximage_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/xmovie_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/xpicker_spec.pm \
	lib/App/SeismicUnixGui/specs/plot/xwigb_spec.pm \
	lib/App/SeismicUnixGui/specs/shapeNcut/archive/sumute_spec_old.pm \
	lib/App/SeismicUnixGui/specs/shapeNcut/suflip_spec.pm \
	lib/App/SeismicUnixGui/specs/shapeNcut/sugain_spec.pm \
	lib/App/SeismicUnixGui/specs/shapeNcut/sugprfb_spec.pm \
	lib/App/SeismicUnixGui/specs/shapeNcut/sukill_spec.pm \
	lib/App/SeismicUnixGui/specs/shapeNcut/sumute_spec.pm \
	lib/App/SeismicUnixGui/specs/shapeNcut/supad_spec.pm \
	lib/App/SeismicUnixGui/specs/shapeNcut/suramp_spec.pm \
	lib/App/SeismicUnixGui/specs/shapeNcut/susort_spec.pm \
	lib/App/SeismicUnixGui/specs/shapeNcut/susplit_spec.pm \
	lib/App/SeismicUnixGui/specs/shapeNcut/suvcat_spec.pm \
	lib/App/SeismicUnixGui/specs/shapeNcut/suwind_spec.pm \
	lib/App/SeismicUnixGui/specs/shell/cat_su_spec.pm \
	lib/App/SeismicUnixGui/specs/shell/evince_spec.pm \
	lib/App/SeismicUnixGui/specs/shell/sugetgthr_spec.pm \
	lib/App/SeismicUnixGui/specs/shell/suputgthr_spec.pm \
	lib/App/SeismicUnixGui/specs/shell/xk_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/cpftrend_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/entropy_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/farith_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/suacor_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/suacorfrac_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/sualford_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/suattributes_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/suconv_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/sufwmix_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/suhistogram_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/suhrot_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/suinterp_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/sumax_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/sumean_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/sumix_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/suop2_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/suop_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/susort_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/suxcor_spec.pm \
	lib/App/SeismicUnixGui/specs/statsMath/suxmax_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/dctcomp_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/suamp_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/succepstrum_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/succwt_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/sucepstrum_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/sucwt_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/sufft_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/sugabor_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/suicepstrum_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/suifft_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/suminphase_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/suphasevel_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/suspecfx_spec.pm \
	lib/App/SeismicUnixGui/specs/transform/sutaup_spec.pm \
	lib/App/SeismicUnixGui/specs/well/las2su_spec.pm \
	lib/App/SeismicUnixGui/specs/well/subackus_spec.pm \
	lib/App/SeismicUnixGui/specs/well/subackush_spec.pm \
	lib/App/SeismicUnixGui/specs/well/sugassman_spec.pm \
	lib/App/SeismicUnixGui/specs/well/sulprime_spec.pm \
	lib/App/SeismicUnixGui/specs/well/suwellrf_spec.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/dzdv.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sucvs4fowler.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudivstack.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmofk.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmofkcw.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmotivz.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmotx.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmovz.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suilog.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suintvel.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sulog.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sunmo.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sunmo_a.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/supws.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/surecip.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sureduce.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/surelan.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/surelanan.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suresamp.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sushift.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sustack.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sustkvel.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sutaupnmo.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sutihaledmo.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sutivel.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sutsq.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suttoz.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suvel2df.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suvelan.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suvelan_nccs.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suvelan_nsel.pm \
	lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suztot.pm \
	lib/App/SeismicUnixGui/sunix/data/ctrlstrip.pm \
	lib/App/SeismicUnixGui/sunix/data/data_in.pm \
	lib/App/SeismicUnixGui/sunix/data/data_out.pm \
	lib/App/SeismicUnixGui/sunix/data/dt1tosu.pm \
	lib/App/SeismicUnixGui/sunix/data/segbread.pm \
	lib/App/SeismicUnixGui/sunix/data/segdread.pm \
	lib/App/SeismicUnixGui/sunix/data/segyread.pm \
	lib/App/SeismicUnixGui/sunix/data/segyread_old.pm \
	lib/App/SeismicUnixGui/sunix/data/segyscan.pm \
	lib/App/SeismicUnixGui/sunix/data/segywrite.pm \
	lib/App/SeismicUnixGui/sunix/data/suoldtonew.pm \
	lib/App/SeismicUnixGui/sunix/data/supack1.pm \
	lib/App/SeismicUnixGui/sunix/data/supack2.pm \
	lib/App/SeismicUnixGui/sunix/data/suswapbytes.pm \
	lib/App/SeismicUnixGui/sunix/data/suunpack1.pm \
	lib/App/SeismicUnixGui/sunix/data/suunpack2.pm \
	lib/App/SeismicUnixGui/sunix/data/wpc1uncomp2.pm \
	lib/App/SeismicUnixGui/sunix/data/wpccompress.pm \
	lib/App/SeismicUnixGui/sunix/data/wpcuncompress.pm \
	lib/App/SeismicUnixGui/sunix/data/wptcomp.pm \
	lib/App/SeismicUnixGui/sunix/data/wptuncomp.pm \
	lib/App/SeismicUnixGui/sunix/data/wtcomp.pm \
	lib/App/SeismicUnixGui/sunix/data/wtuncomp.pm \
	lib/App/SeismicUnixGui/sunix/datum/sudatumk2dr.pm \
	lib/App/SeismicUnixGui/sunix/datum/sudatumk2ds.pm \
	lib/App/SeismicUnixGui/sunix/datum/sukdmdcr.pm \
	lib/App/SeismicUnixGui/sunix/datum/sukdmdcs.pm \
	lib/App/SeismicUnixGui/sunix/filter/subfilt.pm \
	lib/App/SeismicUnixGui/sunix/filter/succfilt.pm \
	lib/App/SeismicUnixGui/sunix/filter/sucddecon.pm \
	lib/App/SeismicUnixGui/sunix/filter/sudipfilt.pm \
	lib/App/SeismicUnixGui/sunix/filter/sueipofi.pm \
	lib/App/SeismicUnixGui/sunix/filter/sufilter.pm \
	lib/App/SeismicUnixGui/sunix/filter/sufrac.pm \
	lib/App/SeismicUnixGui/sunix/filter/sufwatrim.pm \
	lib/App/SeismicUnixGui/sunix/filter/sufxdecon.pm \
	lib/App/SeismicUnixGui/sunix/filter/sugroll.pm \
	lib/App/SeismicUnixGui/sunix/filter/suk1k2filter.pm \
	lib/App/SeismicUnixGui/sunix/filter/sukfilter.pm \
	lib/App/SeismicUnixGui/sunix/filter/sulfaf.pm \
	lib/App/SeismicUnixGui/sunix/filter/sumedian.pm \
	lib/App/SeismicUnixGui/sunix/filter/supef.pm \
	lib/App/SeismicUnixGui/sunix/filter/suphase.pm \
	lib/App/SeismicUnixGui/sunix/filter/suphidecon.pm \
	lib/App/SeismicUnixGui/sunix/filter/supofilt.pm \
	lib/App/SeismicUnixGui/sunix/filter/supolar.pm \
	lib/App/SeismicUnixGui/sunix/filter/susmgauss2.pm \
	lib/App/SeismicUnixGui/sunix/filter/sutvband.pm \
	lib/App/SeismicUnixGui/sunix/header/header_values.pm \
	lib/App/SeismicUnixGui/sunix/header/segyclean.pm \
	lib/App/SeismicUnixGui/sunix/header/segyhdrmod.pm \
	lib/App/SeismicUnixGui/sunix/header/segyhdrs.pm \
	lib/App/SeismicUnixGui/sunix/header/segyhdrs_old.pm \
	lib/App/SeismicUnixGui/sunix/header/setbhed.pm \
	lib/App/SeismicUnixGui/sunix/header/su3dchart.pm \
	lib/App/SeismicUnixGui/sunix/header/suabshw.pm \
	lib/App/SeismicUnixGui/sunix/header/suaddhead.pm \
	lib/App/SeismicUnixGui/sunix/header/suaddstatics.pm \
	lib/App/SeismicUnixGui/sunix/header/suahw.pm \
	lib/App/SeismicUnixGui/sunix/header/suascii.pm \
	lib/App/SeismicUnixGui/sunix/header/suazimuth.pm \
	lib/App/SeismicUnixGui/sunix/header/sucdpbin.pm \
	lib/App/SeismicUnixGui/sunix/header/suchart.pm \
	lib/App/SeismicUnixGui/sunix/header/suchw.pm \
	lib/App/SeismicUnixGui/sunix/header/sucliphead.pm \
	lib/App/SeismicUnixGui/sunix/header/sucountkey.pm \
	lib/App/SeismicUnixGui/sunix/header/sudumptrace.pm \
	lib/App/SeismicUnixGui/sunix/header/suedit.pm \
	lib/App/SeismicUnixGui/sunix/header/sugethw.pm \
	lib/App/SeismicUnixGui/sunix/header/suhtmath.pm \
	lib/App/SeismicUnixGui/sunix/header/sukeycount.pm \
	lib/App/SeismicUnixGui/sunix/header/sulcthw.pm \
	lib/App/SeismicUnixGui/sunix/header/sulhead.pm \
	lib/App/SeismicUnixGui/sunix/header/supaste.pm \
	lib/App/SeismicUnixGui/sunix/header/surandhw.pm \
	lib/App/SeismicUnixGui/sunix/header/surange.pm \
	lib/App/SeismicUnixGui/sunix/header/suresstat.pm \
	lib/App/SeismicUnixGui/sunix/header/suresstat_old.pm \
	lib/App/SeismicUnixGui/sunix/header/susehw.pm \
	lib/App/SeismicUnixGui/sunix/header/sushw.pm \
	lib/App/SeismicUnixGui/sunix/header/sustatic.pm \
	lib/App/SeismicUnixGui/sunix/header/sustaticB.pm \
	lib/App/SeismicUnixGui/sunix/header/sustatic_old.pm \
	lib/App/SeismicUnixGui/sunix/header/sustaticrrs.pm \
	lib/App/SeismicUnixGui/sunix/header/sustrip.pm \
	lib/App/SeismicUnixGui/sunix/header/sutrcount.pm \
	lib/App/SeismicUnixGui/sunix/header/suutm.pm \
	lib/App/SeismicUnixGui/sunix/header/suxedit.pm \
	lib/App/SeismicUnixGui/sunix/header/swapbhed.pm \
	lib/App/SeismicUnixGui/sunix/inversion/suinvco3d.pm \
	lib/App/SeismicUnixGui/sunix/inversion/suinvvxzco.pm \
	lib/App/SeismicUnixGui/sunix/inversion/suinvzco3d.pm \
	lib/App/SeismicUnixGui/sunix/migration/sudatumfd.pm \
	lib/App/SeismicUnixGui/sunix/migration/sugazmig.pm \
	lib/App/SeismicUnixGui/sunix/migration/sukdmig2d.pm \
	lib/App/SeismicUnixGui/sunix/migration/sukdmig3d.pm \
	lib/App/SeismicUnixGui/sunix/migration/suktmig2d.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumigfd.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumigffd.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumiggbzo.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumiggbzoan.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumigprefd.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumigpreffd.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumigprepspi.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumigpresp.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumigps.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumigpspi.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumigpsti.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumigsplit.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumigtk.pm \
	lib/App/SeismicUnixGui/sunix/migration/sumigtopo2d.pm \
	lib/App/SeismicUnixGui/sunix/migration/sustolt.pm \
	lib/App/SeismicUnixGui/sunix/migration/sutifowler.pm \
	lib/App/SeismicUnixGui/sunix/model/addrvl3d.pm \
	lib/App/SeismicUnixGui/sunix/model/cellauto.pm \
	lib/App/SeismicUnixGui/sunix/model/elacheck.pm \
	lib/App/SeismicUnixGui/sunix/model/elamodel.pm \
	lib/App/SeismicUnixGui/sunix/model/elaray.pm \
	lib/App/SeismicUnixGui/sunix/model/elasyn.pm \
	lib/App/SeismicUnixGui/sunix/model/elatriuni.pm \
	lib/App/SeismicUnixGui/sunix/model/gbbeam.pm \
	lib/App/SeismicUnixGui/sunix/model/grm.pm \
	lib/App/SeismicUnixGui/sunix/model/normray.pm \
	lib/App/SeismicUnixGui/sunix/model/raydata.pm \
	lib/App/SeismicUnixGui/sunix/model/suaddevent.pm \
	lib/App/SeismicUnixGui/sunix/model/suaddnoise.pm \
	lib/App/SeismicUnixGui/sunix/model/sudgwaveform.pm \
	lib/App/SeismicUnixGui/sunix/model/suea2df.pm \
	lib/App/SeismicUnixGui/sunix/model/sufctanismod.pm \
	lib/App/SeismicUnixGui/sunix/model/sufdmod1.pm \
	lib/App/SeismicUnixGui/sunix/model/sufdmod2.pm \
	lib/App/SeismicUnixGui/sunix/model/sufdmod2_pml.pm \
	lib/App/SeismicUnixGui/sunix/model/sugoupillaud.pm \
	lib/App/SeismicUnixGui/sunix/model/sugoupillaudpo.pm \
	lib/App/SeismicUnixGui/sunix/model/suimp2d.pm \
	lib/App/SeismicUnixGui/sunix/model/suimp3d.pm \
	lib/App/SeismicUnixGui/sunix/model/suimpedance.pm \
	lib/App/SeismicUnixGui/sunix/model/sujitter.pm \
	lib/App/SeismicUnixGui/sunix/model/sukdsyn2d.pm \
	lib/App/SeismicUnixGui/sunix/model/sunull.pm \
	lib/App/SeismicUnixGui/sunix/model/suplane.pm \
	lib/App/SeismicUnixGui/sunix/model/surandspike.pm \
	lib/App/SeismicUnixGui/sunix/model/surandstat.pm \
	lib/App/SeismicUnixGui/sunix/model/suremac2d.pm \
	lib/App/SeismicUnixGui/sunix/model/suremel2dan.pm \
	lib/App/SeismicUnixGui/sunix/model/suspike.pm \
	lib/App/SeismicUnixGui/sunix/model/susyncz.pm \
	lib/App/SeismicUnixGui/sunix/model/susynlv.pm \
	lib/App/SeismicUnixGui/sunix/model/susynlvcw.pm \
	lib/App/SeismicUnixGui/sunix/model/susynlvfti.pm \
	lib/App/SeismicUnixGui/sunix/model/susynvxz.pm \
	lib/App/SeismicUnixGui/sunix/model/susynvxzcs.pm \
	lib/App/SeismicUnixGui/sunix/par/a2b.pm \
	lib/App/SeismicUnixGui/sunix/par/a2i.pm \
	lib/App/SeismicUnixGui/sunix/par/b2a.pm \
	lib/App/SeismicUnixGui/sunix/par/bhedtopar.pm \
	lib/App/SeismicUnixGui/sunix/par/cshotplot.pm \
	lib/App/SeismicUnixGui/sunix/par/float2ibm.pm \
	lib/App/SeismicUnixGui/sunix/par/ftnstrip.pm \
	lib/App/SeismicUnixGui/sunix/par/ftnunstrip.pm \
	lib/App/SeismicUnixGui/sunix/par/makevel.pm \
	lib/App/SeismicUnixGui/sunix/par/mkparfile.pm \
	lib/App/SeismicUnixGui/sunix/par/transp.pm \
	lib/App/SeismicUnixGui/sunix/par/unif2.pm \
	lib/App/SeismicUnixGui/sunix/par/unif2aniso.pm \
	lib/App/SeismicUnixGui/sunix/par/unisam.pm \
	lib/App/SeismicUnixGui/sunix/par/unisam2.pm \
	lib/App/SeismicUnixGui/sunix/par/vel2stiff.pm \
	lib/App/SeismicUnixGui/sunix/plot/elaps.pm \
	lib/App/SeismicUnixGui/sunix/plot/lcmap.pm \
	lib/App/SeismicUnixGui/sunix/plot/lprop.pm \
	lib/App/SeismicUnixGui/sunix/plot/psbbox.pm \
	lib/App/SeismicUnixGui/sunix/plot/pscontour.pm \
	lib/App/SeismicUnixGui/sunix/plot/pscube.pm \
	lib/App/SeismicUnixGui/sunix/plot/pscubecontour.pm \
	lib/App/SeismicUnixGui/sunix/plot/psepsi.pm \
	lib/App/SeismicUnixGui/sunix/plot/psgraph.pm \
	lib/App/SeismicUnixGui/sunix/plot/psimage.pm \
	lib/App/SeismicUnixGui/sunix/plot/pslabel.pm \
	lib/App/SeismicUnixGui/sunix/plot/psmanager.pm \
	lib/App/SeismicUnixGui/sunix/plot/psmerge.pm \
	lib/App/SeismicUnixGui/sunix/plot/psmovie.pm \
	lib/App/SeismicUnixGui/sunix/plot/pswigb.pm \
	lib/App/SeismicUnixGui/sunix/plot/pswigp.pm \
	lib/App/SeismicUnixGui/sunix/plot/scmap.pm \
	lib/App/SeismicUnixGui/sunix/plot/spsplot.pm \
	lib/App/SeismicUnixGui/sunix/plot/supscontour.pm \
	lib/App/SeismicUnixGui/sunix/plot/supscube.pm \
	lib/App/SeismicUnixGui/sunix/plot/supscubecontour.pm \
	lib/App/SeismicUnixGui/sunix/plot/supsgraph.pm \
	lib/App/SeismicUnixGui/sunix/plot/supsimage.pm \
	lib/App/SeismicUnixGui/sunix/plot/supsmax.pm \
	lib/App/SeismicUnixGui/sunix/plot/supsmovie.pm \
	lib/App/SeismicUnixGui/sunix/plot/supswigb.pm \
	lib/App/SeismicUnixGui/sunix/plot/supswigp.pm \
	lib/App/SeismicUnixGui/sunix/plot/suxcontour.pm \
	lib/App/SeismicUnixGui/sunix/plot/suxgraph.pm \
	lib/App/SeismicUnixGui/sunix/plot/suximage.pm \
	lib/App/SeismicUnixGui/sunix/plot/suxmax.pm \
	lib/App/SeismicUnixGui/sunix/plot/suxmovie.pm \
	lib/App/SeismicUnixGui/sunix/plot/suxpicker.pm \
	lib/App/SeismicUnixGui/sunix/plot/suxwigb.pm \
	lib/App/SeismicUnixGui/sunix/plot/todo/viewer3.pm \
	lib/App/SeismicUnixGui/sunix/plot/xcontour.pm \
	lib/App/SeismicUnixGui/sunix/plot/xgraph.pm \
	lib/App/SeismicUnixGui/sunix/plot/ximage.pm \
	lib/App/SeismicUnixGui/sunix/plot/xmovie.pm \
	lib/App/SeismicUnixGui/sunix/plot/xpicker.pm \
	lib/App/SeismicUnixGui/sunix/plot/xwigb.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/archive/sumute_old.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/archive/suresamp.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/suflip.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/sugain.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/sugprfb.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/sukill.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/sumute.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/supad.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/suramp.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/susort.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/susplit.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/suvcat.pm \
	lib/App/SeismicUnixGui/sunix/shapeNcut/suwind.pm \
	lib/App/SeismicUnixGui/sunix/shell/cat_su.pm \
	lib/App/SeismicUnixGui/sunix/shell/cat_txt.pm \
	lib/App/SeismicUnixGui/sunix/shell/cp.pm \
	lib/App/SeismicUnixGui/sunix/shell/evince.pm \
	lib/App/SeismicUnixGui/sunix/shell/sucat.pm \
	lib/App/SeismicUnixGui/sunix/shell/sugetgthr.pm \
	lib/App/SeismicUnixGui/sunix/shell/suputgthr.pm \
	lib/App/SeismicUnixGui/sunix/shell/xk.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/cpftrend.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/entropy.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/farith.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/suacor.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/suacorfrac.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/sualford.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/suattributes.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/suconv.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/sufwmix.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/suhistogram.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/suhrot.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/suinterp.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/sumax.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/sumean.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/sumix.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/suop.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/suop2.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/suxcor.pm \
	lib/App/SeismicUnixGui/sunix/statsMath/suxmax.pm \
	lib/App/SeismicUnixGui/sunix/transform/dctcomp.pm \
	lib/App/SeismicUnixGui/sunix/transform/suamp.pm \
	lib/App/SeismicUnixGui/sunix/transform/succepstrum.pm \
	lib/App/SeismicUnixGui/sunix/transform/succwt.pm \
	lib/App/SeismicUnixGui/sunix/transform/sucepstrum.pm \
	lib/App/SeismicUnixGui/sunix/transform/sucwt.pm \
	lib/App/SeismicUnixGui/sunix/transform/sufft.pm \
	lib/App/SeismicUnixGui/sunix/transform/sugabor.pm \
	lib/App/SeismicUnixGui/sunix/transform/suicepstrum.pm \
	lib/App/SeismicUnixGui/sunix/transform/suifft.pm \
	lib/App/SeismicUnixGui/sunix/transform/suminphase.pm \
	lib/App/SeismicUnixGui/sunix/transform/suphasevel.pm \
	lib/App/SeismicUnixGui/sunix/transform/suspecfk.pm \
	lib/App/SeismicUnixGui/sunix/transform/suspecfx.pm \
	lib/App/SeismicUnixGui/sunix/transform/sutaup.pm \
	lib/App/SeismicUnixGui/sunix/well/las2su.pm \
	lib/App/SeismicUnixGui/sunix/well/subackus.pm \
	lib/App/SeismicUnixGui/sunix/well/subackush.pm \
	lib/App/SeismicUnixGui/sunix/well/sugassman.pm \
	lib/App/SeismicUnixGui/sunix/well/sulprime.pm \
	lib/App/SeismicUnixGui/sunix/well/suwellrf.pm \
	lib/App/archive/BackupProjectSelector.pl \
	lib/App/archive/SeismicUnixGui.pm_bck \
	lib/App/archive/sunix/NMO_Vel_Stk/dzdv.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sucvs4fowler.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sudivstack.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sudmofk.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sudmofkcw.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sudmotivz.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sudmotx.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sudmovz.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/suilog.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/suintvel.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sulog.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sunmo.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sunmo_a.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/supws.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/surecip.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sureduce.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/surelan.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/surelanan.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/suresamp.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sushift.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sustack.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sustkvel.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sutaupnmo.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sutihaledmo.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sutivel.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/sutsq.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/suttoz.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/suvel2df.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/suvelan.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/suvelan_nccs.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/suvelan_nsel.pm \
	lib/App/archive/sunix/NMO_Vel_Stk/suztot.pm \
	lib/App/archive/sunix/data/ctrlstrip.pm \
	lib/App/archive/sunix/data/data_in.pm \
	lib/App/archive/sunix/data/data_out.pm \
	lib/App/archive/sunix/data/dt1tosu.pm \
	lib/App/archive/sunix/data/segbread.pm \
	lib/App/archive/sunix/data/segdread.pm \
	lib/App/archive/sunix/data/segyread.pm \
	lib/App/archive/sunix/data/segyread_old.pm \
	lib/App/archive/sunix/data/segyscan.pm \
	lib/App/archive/sunix/data/segywrite.pm \
	lib/App/archive/sunix/data/suoldtonew.pm \
	lib/App/archive/sunix/data/supack1.pm \
	lib/App/archive/sunix/data/supack2.pm \
	lib/App/archive/sunix/data/suswapbytes.pm \
	lib/App/archive/sunix/data/suunpack1.pm \
	lib/App/archive/sunix/data/suunpack2.pm \
	lib/App/archive/sunix/data/wpc1uncomp2.pm \
	lib/App/archive/sunix/data/wpccompress.pm \
	lib/App/archive/sunix/data/wpcuncompress.pm \
	lib/App/archive/sunix/data/wptcomp.pm \
	lib/App/archive/sunix/data/wptuncomp.pm \
	lib/App/archive/sunix/data/wtcomp.pm \
	lib/App/archive/sunix/data/wtuncomp.pm \
	lib/App/archive/sunix/datum/sudatumk2dr.pm \
	lib/App/archive/sunix/datum/sudatumk2ds.pm \
	lib/App/archive/sunix/datum/sukdmdcr.pm \
	lib/App/archive/sunix/datum/sukdmdcs.pm \
	lib/App/archive/sunix/filter/subfilt.pm \
	lib/App/archive/sunix/filter/succfilt.pm \
	lib/App/archive/sunix/filter/sucddecon.pm \
	lib/App/archive/sunix/filter/sudipfilt.pm \
	lib/App/archive/sunix/filter/sueipofi.pm \
	lib/App/archive/sunix/filter/sufilter.pm \
	lib/App/archive/sunix/filter/sufrac.pm \
	lib/App/archive/sunix/filter/sufwatrim.pm \
	lib/App/archive/sunix/filter/sufxdecon.pm \
	lib/App/archive/sunix/filter/sugroll.pm \
	lib/App/archive/sunix/filter/suk1k2filter.pm \
	lib/App/archive/sunix/filter/sukfilter.pm \
	lib/App/archive/sunix/filter/sulfaf.pm \
	lib/App/archive/sunix/filter/sumedian.pm \
	lib/App/archive/sunix/filter/supef.pm \
	lib/App/archive/sunix/filter/suphase.pm \
	lib/App/archive/sunix/filter/suphidecon.pm \
	lib/App/archive/sunix/filter/supofilt.pm \
	lib/App/archive/sunix/filter/supolar.pm \
	lib/App/archive/sunix/filter/susmgauss2.pm \
	lib/App/archive/sunix/filter/sutvband.pm \
	lib/App/archive/sunix/header/header_values.pm \
	lib/App/archive/sunix/header/segyclean.pm \
	lib/App/archive/sunix/header/segyhdrmod.pm \
	lib/App/archive/sunix/header/segyhdrs.pm \
	lib/App/archive/sunix/header/segyhdrs_old.pm \
	lib/App/archive/sunix/header/setbhed.pm \
	lib/App/archive/sunix/header/su3dchart.pm \
	lib/App/archive/sunix/header/suabshw.pm \
	lib/App/archive/sunix/header/suaddhead.pm \
	lib/App/archive/sunix/header/suaddstatics.pm \
	lib/App/archive/sunix/header/suahw.pm \
	lib/App/archive/sunix/header/suascii.pm \
	lib/App/archive/sunix/header/suazimuth.pm \
	lib/App/archive/sunix/header/sucdpbin.pm \
	lib/App/archive/sunix/header/suchart.pm \
	lib/App/archive/sunix/header/suchw.pm \
	lib/App/archive/sunix/header/sucliphead.pm \
	lib/App/archive/sunix/header/sucountkey.pm \
	lib/App/archive/sunix/header/sucwt.pm \
	lib/App/archive/sunix/header/sudumptrace.pm \
	lib/App/archive/sunix/header/suedit.pm \
	lib/App/archive/sunix/header/sugethw.pm \
	lib/App/archive/sunix/header/suhtmath.pm \
	lib/App/archive/sunix/header/sukeycount.pm \
	lib/App/archive/sunix/header/sulcthw.pm \
	lib/App/archive/sunix/header/sulhead.pm \
	lib/App/archive/sunix/header/supaste.pm \
	lib/App/archive/sunix/header/surandhw.pm \
	lib/App/archive/sunix/header/surange.pm \
	lib/App/archive/sunix/header/suresstat.pm \
	lib/App/archive/sunix/header/susehw.pm \
	lib/App/archive/sunix/header/sushw.pm \
	lib/App/archive/sunix/header/sustatic.pm \
	lib/App/archive/sunix/header/sustaticB.pm \
	lib/App/archive/sunix/header/sustatic_old.pm \
	lib/App/archive/sunix/header/sustaticrrs.pm \
	lib/App/archive/sunix/header/sustrip.pm \
	lib/App/archive/sunix/header/sutrcount.pm \
	lib/App/archive/sunix/header/suutm.pm \
	lib/App/archive/sunix/header/suxedit.pm \
	lib/App/archive/sunix/header/swapbhed.pm \
	lib/App/archive/sunix/inversion/suinvco3d.pm \
	lib/App/archive/sunix/inversion/suinvvxzco.pm \
	lib/App/archive/sunix/inversion/suinvzco3d.pm \
	lib/App/archive/sunix/migration/sudatumfd.pm \
	lib/App/archive/sunix/migration/sugazmig.pm \
	lib/App/archive/sunix/migration/sukdmig2d.pm \
	lib/App/archive/sunix/migration/sukdmig3d.pm \
	lib/App/archive/sunix/migration/suktmig2d.pm \
	lib/App/archive/sunix/migration/sumigfd.pm \
	lib/App/archive/sunix/migration/sumigffd.pm \
	lib/App/archive/sunix/migration/sumiggbzo.pm \
	lib/App/archive/sunix/migration/sumiggbzoan.pm \
	lib/App/archive/sunix/migration/sumigprefd.pm \
	lib/App/archive/sunix/migration/sumigpreffd.pm \
	lib/App/archive/sunix/migration/sumigprepspi.pm \
	lib/App/archive/sunix/migration/sumigpresp.pm \
	lib/App/archive/sunix/migration/sumigps.pm \
	lib/App/archive/sunix/migration/sumigpspi.pm \
	lib/App/archive/sunix/migration/sumigpsti.pm \
	lib/App/archive/sunix/migration/sumigsplit.pm \
	lib/App/archive/sunix/migration/sumigtk.pm \
	lib/App/archive/sunix/migration/sumigtopo2d.pm \
	lib/App/archive/sunix/migration/sustolt.pm \
	lib/App/archive/sunix/migration/sutifowler.pm \
	lib/App/archive/sunix/model/addrvl3d.pm \
	lib/App/archive/sunix/model/cellauto.pm \
	lib/App/archive/sunix/model/elacheck.pm \
	lib/App/archive/sunix/model/elamodel.pm \
	lib/App/archive/sunix/model/elaray.pm \
	lib/App/archive/sunix/model/elasyn.pm \
	lib/App/archive/sunix/model/elatriuni.pm \
	lib/App/archive/sunix/model/gbbeam.pm \
	lib/App/archive/sunix/model/grm.pm \
	lib/App/archive/sunix/model/normray.pm \
	lib/App/archive/sunix/model/raydata.pm \
	lib/App/archive/sunix/model/suaddevent.pm \
	lib/App/archive/sunix/model/suaddnoise.pm \
	lib/App/archive/sunix/model/sudgwaveform.pm \
	lib/App/archive/sunix/model/suea2df.pm \
	lib/App/archive/sunix/model/sufctanismod.pm \
	lib/App/archive/sunix/model/sufdmod1.pm \
	lib/App/archive/sunix/model/sufdmod2.pm \
	lib/App/archive/sunix/model/sufdmod2_pml.pm \
	lib/App/archive/sunix/model/sugoupillaud.pm \
	lib/App/archive/sunix/model/sugoupillaudpo.pm \
	lib/App/archive/sunix/model/suimp2d.pm \
	lib/App/archive/sunix/model/suimp3d.pm \
	lib/App/archive/sunix/model/suimpedance.pm \
	lib/App/archive/sunix/model/sujitter.pm \
	lib/App/archive/sunix/model/sukdsyn2d.pm \
	lib/App/archive/sunix/model/sunull.pm \
	lib/App/archive/sunix/model/suplane.pm \
	lib/App/archive/sunix/model/surandspike.pm \
	lib/App/archive/sunix/model/surandstat.pm \
	lib/App/archive/sunix/model/suremac2d.pm \
	lib/App/archive/sunix/model/suremel2dan.pm \
	lib/App/archive/sunix/model/suspike.pm \
	lib/App/archive/sunix/model/susyncz.pm \
	lib/App/archive/sunix/model/susynlv.pm \
	lib/App/archive/sunix/model/susynlvcw.pm \
	lib/App/archive/sunix/model/susynlvfti.pm \
	lib/App/archive/sunix/model/susynvxz.pm \
	lib/App/archive/sunix/model/susynvxzcs.pm \
	lib/App/archive/sunix/par/a2b.pm \
	lib/App/archive/sunix/par/a2i.pm \
	lib/App/archive/sunix/par/b2a.pm \
	lib/App/archive/sunix/par/bhedtopar.pm \
	lib/App/archive/sunix/par/cshotplot.pm \
	lib/App/archive/sunix/par/float2ibm.pm \
	lib/App/archive/sunix/par/ftnstrip.pm \
	lib/App/archive/sunix/par/ftnunstrip.pm \
	lib/App/archive/sunix/par/makevel.pm \
	lib/App/archive/sunix/par/mkparfile.pm \
	lib/App/archive/sunix/par/transp.pm \
	lib/App/archive/sunix/par/unif2.pm \
	lib/App/archive/sunix/par/unif2aniso.pm \
	lib/App/archive/sunix/par/unisam.pm \
	lib/App/archive/sunix/par/unisam2.pm \
	lib/App/archive/sunix/par/vel2stiff.pm \
	lib/App/archive/sunix/plot/elaps.pm \
	lib/App/archive/sunix/plot/lcmap.pm \
	lib/App/archive/sunix/plot/lprop.pm \
	lib/App/archive/sunix/plot/psbbox.pm \
	lib/App/archive/sunix/plot/pscontour.pm \
	lib/App/archive/sunix/plot/pscube.pm \
	lib/App/archive/sunix/plot/pscubecontour.pm \
	lib/App/archive/sunix/plot/psepsi.pm \
	lib/App/archive/sunix/plot/psgraph.pm \
	lib/App/archive/sunix/plot/psimage.pm \
	lib/App/archive/sunix/plot/pslabel.pm \
	lib/App/archive/sunix/plot/psmanager.pm \
	lib/App/archive/sunix/plot/psmerge.pm \
	lib/App/archive/sunix/plot/psmovie.pm \
	lib/App/archive/sunix/plot/pswigb.pm \
	lib/App/archive/sunix/plot/pswigp.pm \
	lib/App/archive/sunix/plot/scmap.pm \
	lib/App/archive/sunix/plot/spsplot.pm \
	lib/App/archive/sunix/plot/supscontour.pm \
	lib/App/archive/sunix/plot/supscube.pm \
	lib/App/archive/sunix/plot/supscubecontour.pm \
	lib/App/archive/sunix/plot/supsgraph.pm \
	lib/App/archive/sunix/plot/supsimage.pm \
	lib/App/archive/sunix/plot/supsmax.pm \
	lib/App/archive/sunix/plot/supsmovie.pm \
	lib/App/archive/sunix/plot/supswigb.pm \
	lib/App/archive/sunix/plot/supswigp.pm \
	lib/App/archive/sunix/plot/suxcontour.pm \
	lib/App/archive/sunix/plot/suxgraph.pm \
	lib/App/archive/sunix/plot/suximage.pm \
	lib/App/archive/sunix/plot/suxmax.pm \
	lib/App/archive/sunix/plot/suxmovie.pm \
	lib/App/archive/sunix/plot/suxpicker.pm \
	lib/App/archive/sunix/plot/suxwigb.pm \
	lib/App/archive/sunix/plot/viewer3.pm \
	lib/App/archive/sunix/plot/xcontour.pm \
	lib/App/archive/sunix/plot/xgraph.pm \
	lib/App/archive/sunix/plot/ximage.pm \
	lib/App/archive/sunix/plot/xmovie.pm \
	lib/App/archive/sunix/plot/xpicker.pm \
	lib/App/archive/sunix/plot/xwigb.pm \
	lib/App/archive/sunix/shapeNcut/archive/sumute_old.pm \
	lib/App/archive/sunix/shapeNcut/suflip.pm \
	lib/App/archive/sunix/shapeNcut/sugain.pm \
	lib/App/archive/sunix/shapeNcut/sugprfb.pm \
	lib/App/archive/sunix/shapeNcut/sukill.pm \
	lib/App/archive/sunix/shapeNcut/sumute.pm \
	lib/App/archive/sunix/shapeNcut/supad.pm \
	lib/App/archive/sunix/shapeNcut/suresamp.pm \
	lib/App/archive/sunix/shapeNcut/susort.pm \
	lib/App/archive/sunix/shapeNcut/susplit.pm \
	lib/App/archive/sunix/shapeNcut/suvcat.pm \
	lib/App/archive/sunix/shapeNcut/suwind.pm \
	lib/App/archive/sunix/shell/cat_su.pm \
	lib/App/archive/sunix/shell/cat_txt.pm \
	lib/App/archive/sunix/shell/cp.pm \
	lib/App/archive/sunix/shell/evince.pm \
	lib/App/archive/sunix/shell/sucat.pm \
	lib/App/archive/sunix/shell/sugetgthr.pm \
	lib/App/archive/sunix/shell/suputgthr.pm \
	lib/App/archive/sunix/shell/xk.pm \
	lib/App/archive/sunix/statsMath/cpftrend.pm \
	lib/App/archive/sunix/statsMath/entropy.pm \
	lib/App/archive/sunix/statsMath/farith.pm \
	lib/App/archive/sunix/statsMath/suacor.pm \
	lib/App/archive/sunix/statsMath/suacorfrac.pm \
	lib/App/archive/sunix/statsMath/sualford.pm \
	lib/App/archive/sunix/statsMath/suattributes.pm \
	lib/App/archive/sunix/statsMath/suconv.pm \
	lib/App/archive/sunix/statsMath/sufwmix.pm \
	lib/App/archive/sunix/statsMath/suhistogram.pm \
	lib/App/archive/sunix/statsMath/suhrot.pm \
	lib/App/archive/sunix/statsMath/suinterp.pm \
	lib/App/archive/sunix/statsMath/sumax.pm \
	lib/App/archive/sunix/statsMath/sumean.pm \
	lib/App/archive/sunix/statsMath/sumix.pm \
	lib/App/archive/sunix/statsMath/suop.pm \
	lib/App/archive/sunix/statsMath/suop2.pm \
	lib/App/archive/sunix/statsMath/suxcor.pm \
	lib/App/archive/sunix/statsMath/suxmax.pm \
	lib/App/archive/sunix/transform/dctcomp.pm \
	lib/App/archive/sunix/transform/suamp.pm \
	lib/App/archive/sunix/transform/succepstrum.pm \
	lib/App/archive/sunix/transform/succwt.pm \
	lib/App/archive/sunix/transform/sucepstrum.pm \
	lib/App/archive/sunix/transform/sufft.pm \
	lib/App/archive/sunix/transform/sugabor.pm \
	lib/App/archive/sunix/transform/suicepstrum.pm \
	lib/App/archive/sunix/transform/suifft.pm \
	lib/App/archive/sunix/transform/suminphase.pm \
	lib/App/archive/sunix/transform/suphasevel.pm \
	lib/App/archive/sunix/transform/suspecfk.pm \
	lib/App/archive/sunix/transform/suspecfx.pm \
	lib/App/archive/sunix/transform/sutaup.pm \
	lib/App/archive/sunix/well/las2su.pm \
	lib/App/archive/sunix/well/subackus.pm \
	lib/App/archive/sunix/well/subackush.pm \
	lib/App/archive/sunix/well/sugassman.pm \
	lib/App/archive/sunix/well/sulprime.pm \
	lib/App/archive/sunix/well/suwellrf.pm


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 7.70
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$$$ARGV[0], $$$$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(TRUE)
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e 'mkpath' --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e 'eqtime' --
FALSE = false
TRUE = true
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e 'install([ from_to => {@ARGV}, verbose => '\''$(VERBINST)'\'', uninstall_shadows => '\''$(UNINST)'\'', dir_mode => '\''$(PERM_DIR)'\'' ]);' --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'perllocal_install' --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'uninstall' --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'warn_if_old_packlist' --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = $(ABSPERLRUN) -MExtUtils::MY -e 'MY->fixin(shift)' --
CP_NONEMPTY = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'cp_nonempty' --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip -9f
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = App-SeismicUnixGui
DISTVNAME = App-SeismicUnixGui-0.87.2


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	LD="$(LD)"\
	PREFIX="$(PREFIX)"\
	PASTHRU_DEFINE='$(DEFINE) $(PASTHRU_DEFINE)'\
	PASTHRU_INC='$(INC) $(PASTHRU_INC)'


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir pure_all subdirs clean_subdirs makemakerdflt manifypods realclean_subdirs subdirs_dynamic subdirs_pure_nolink subdirs_static subdirs-test_dynamic subdirs-test_static test_dynamic test_static



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)

pure_all :: config pm_to_blib subdirs linkext
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


manifypods : pure_all config  \
	./lib/App/SeismicUnixGui/script/post_install_c_compile.pl \
	./lib/App/SeismicUnixGui/script/post_install_env.pl \
	./lib/App/SeismicUnixGui/script/post_install_fortran_compile.pl
	$(NOECHO) $(POD2MAN) --section=$(MAN1EXT) --perm_rw=$(PERM_RW) -u \
	  ./lib/App/SeismicUnixGui/script/post_install_c_compile.pl $(INST_MAN1DIR)/post_install_c_compile.pl.$(MAN1EXT) \
	  ./lib/App/SeismicUnixGui/script/post_install_env.pl $(INST_MAN1DIR)/post_install_env.pl.$(MAN1EXT) \
	  ./lib/App/SeismicUnixGui/script/post_install_fortran_compile.pl $(INST_MAN1DIR)/post_install_fortran_compile.pl.$(MAN1EXT) 




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:

EXE_FILES = ./lib/App/SeismicUnixGui/script/post_install_c_compile.pl ./lib/App/SeismicUnixGui/script/post_install_env.pl ./lib/App/SeismicUnixGui/script/post_install_fortran_compile.pl ./lib/App/SeismicUnixGui/script/post_install_scripts.sh

pure_all :: $(INST_SCRIPT)/post_install_c_compile.pl $(INST_SCRIPT)/post_install_env.pl $(INST_SCRIPT)/post_install_fortran_compile.pl $(INST_SCRIPT)/post_install_scripts.sh
	$(NOECHO) $(NOOP)

realclean ::
	$(RM_F) \
	  $(INST_SCRIPT)/post_install_c_compile.pl $(INST_SCRIPT)/post_install_env.pl \
	  $(INST_SCRIPT)/post_install_fortran_compile.pl $(INST_SCRIPT)/post_install_scripts.sh 

$(INST_SCRIPT)/post_install_c_compile.pl : ./lib/App/SeismicUnixGui/script/post_install_c_compile.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/post_install_c_compile.pl
	$(CP) ./lib/App/SeismicUnixGui/script/post_install_c_compile.pl $(INST_SCRIPT)/post_install_c_compile.pl
	$(FIXIN) $(INST_SCRIPT)/post_install_c_compile.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/post_install_c_compile.pl

$(INST_SCRIPT)/post_install_env.pl : ./lib/App/SeismicUnixGui/script/post_install_env.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/post_install_env.pl
	$(CP) ./lib/App/SeismicUnixGui/script/post_install_env.pl $(INST_SCRIPT)/post_install_env.pl
	$(FIXIN) $(INST_SCRIPT)/post_install_env.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/post_install_env.pl

$(INST_SCRIPT)/post_install_fortran_compile.pl : ./lib/App/SeismicUnixGui/script/post_install_fortran_compile.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/post_install_fortran_compile.pl
	$(CP) ./lib/App/SeismicUnixGui/script/post_install_fortran_compile.pl $(INST_SCRIPT)/post_install_fortran_compile.pl
	$(FIXIN) $(INST_SCRIPT)/post_install_fortran_compile.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/post_install_fortran_compile.pl

$(INST_SCRIPT)/post_install_scripts.sh : ./lib/App/SeismicUnixGui/script/post_install_scripts.sh $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/post_install_scripts.sh
	$(CP) ./lib/App/SeismicUnixGui/script/post_install_scripts.sh $(INST_SCRIPT)/post_install_scripts.sh
	$(FIXIN) $(INST_SCRIPT)/post_install_scripts.sh
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/post_install_scripts.sh



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
	  $(BOOTSTRAP) $(INST_ARCHAUTODIR)/extralibs.all \
	  $(INST_ARCHAUTODIR)/extralibs.ld $(MAKE_APERL_FILE) \
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
	  blib 
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
	$(NOECHO) $(ECHO) '---' > META_new.yml
	$(NOECHO) $(ECHO) 'abstract: '\''A graphical user interface for Seismic Unix'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'author:' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Juan Lorenzo <gllore@lsu.edu>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'build_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Test::Compile::Internal: '\''1.3'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'configure_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'dynamic_config: 1' >> META_new.yml
	$(NOECHO) $(ECHO) 'generated_by: '\''ExtUtils::MakeMaker version 7.70, CPAN::Meta::Converter version 2.150010'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'license: perl' >> META_new.yml
	$(NOECHO) $(ECHO) 'meta-spec:' >> META_new.yml
	$(NOECHO) $(ECHO) '  url: http://module-build.sourceforge.net/META-spec-v1.4.html' >> META_new.yml
	$(NOECHO) $(ECHO) '  version: '\''1.4'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'name: App-SeismicUnixGui' >> META_new.yml
	$(NOECHO) $(ECHO) 'no_index:' >> META_new.yml
	$(NOECHO) $(ECHO) '  directory:' >> META_new.yml
	$(NOECHO) $(ECHO) '    - t' >> META_new.yml
	$(NOECHO) $(ECHO) '    - inc' >> META_new.yml
	$(NOECHO) $(ECHO) 'requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  Clone: '\''0.45'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::ShareDir: '\''1.118'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::Slurp: '\''9999.32'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  MIME::Base64: '\''3.16'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Module::Refresh: '\''0.18'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Moose: '\''2.2015'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  PDL: '\''2.080'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Shell: v0.73.1' >> META_new.yml
	$(NOECHO) $(ECHO) '  Time::HiRes: '\''1.9764'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Tk: '\''804.036'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Tk::JFileDialog: '\''2.20'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Tk::Pod: '\''0.9943'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  aliased: '\''0.34'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  namespace::autoclean: '\''0.29'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'version: v0.87.2' >> META_new.yml
	$(NOECHO) $(ECHO) 'x_serialization_backend: '\''CPAN::Meta::YAML version 0.018'\''' >> META_new.yml
	-$(NOECHO) $(MV) META_new.yml $(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) Generating META.json
	$(NOECHO) $(ECHO) '{' > META_new.json
	$(NOECHO) $(ECHO) '   "abstract" : "A graphical user interface for Seismic Unix",' >> META_new.json
	$(NOECHO) $(ECHO) '   "author" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "Juan Lorenzo <gllore@lsu.edu>"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "dynamic_config" : 1,' >> META_new.json
	$(NOECHO) $(ECHO) '   "generated_by" : "ExtUtils::MakeMaker version 7.70, CPAN::Meta::Converter version 2.150010",' >> META_new.json
	$(NOECHO) $(ECHO) '   "license" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "perl_5"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "meta-spec" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",' >> META_new.json
	$(NOECHO) $(ECHO) '      "version" : 2' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "name" : "App-SeismicUnixGui",' >> META_new.json
	$(NOECHO) $(ECHO) '   "no_index" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "directory" : [' >> META_new.json
	$(NOECHO) $(ECHO) '         "t",' >> META_new.json
	$(NOECHO) $(ECHO) '         "inc"' >> META_new.json
	$(NOECHO) $(ECHO) '      ]' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "prereqs" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "build" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "configure" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "runtime" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "Clone" : "0.45",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::ShareDir" : "1.118",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::Slurp" : "9999.32",' >> META_new.json
	$(NOECHO) $(ECHO) '            "MIME::Base64" : "3.16",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Module::Refresh" : "0.18",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Moose" : "2.2015",' >> META_new.json
	$(NOECHO) $(ECHO) '            "PDL" : "2.080",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Shell" : "v0.73.1",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Time::HiRes" : "1.9764",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Tk" : "804.036",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Tk::JFileDialog" : "2.20",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Tk::Pod" : "0.9943",' >> META_new.json
	$(NOECHO) $(ECHO) '            "aliased" : "0.34",' >> META_new.json
	$(NOECHO) $(ECHO) '            "namespace::autoclean" : "0.29"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "test" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "Test::Compile::Internal" : "1.3"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      }' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "release_status" : "stable",' >> META_new.json
	$(NOECHO) $(ECHO) '   "version" : "v0.87.2",' >> META_new.json
	$(NOECHO) $(ECHO) '   "x_serialization_backend" : "JSON::PP version 4.16"' >> META_new.json
	$(NOECHO) $(ECHO) '}' >> META_new.json
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
	$(NOECHO) $(ABSPERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	  -e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';' --

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
	$(ABSPERLRUN) -MExtUtils::Manifest=maniread -e '@all = sort keys %{ maniread() };' \
	  -e 'print(qq{Executing $(CI) @all\n});' \
	  -e 'system(qq{$(CI) @all}) == 0 or die $$!;' \
	  -e 'print(qq{Executing $(RCS_LABEL) ...\n});' \
	  -e 'system(qq{$(RCS_LABEL) @all}) == 0 or die $$!;' --


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -e q{META.yml};' \
	  -e 'eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.yml to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -f q{META.json};' \
	  -e 'eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.json to MANIFEST: $${'\''@'\''}"' --



# --- MakeMaker distsignature section:
distsignature : distmeta
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
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
	$(NOECHO) umask 022; $(MOD_INSTALL) \
		"$(INST_LIB)" "$(DESTINSTALLPRIVLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLARCHLIB)" \
		"$(INST_BIN)" "$(DESTINSTALLBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(SITEARCHEXP)/auto/$(FULLEXT)"


pure_site_install :: all
	$(NOECHO) umask 02; $(MOD_INSTALL) \
		read "$(SITEARCHEXP)/auto/$(FULLEXT)/.packlist" \
		write "$(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLSITELIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLSITEARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLSITEBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSITESCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLSITEMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLSITEMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(PERL_ARCHLIB)/auto/$(FULLEXT)"

pure_vendor_install :: all
	$(NOECHO) umask 022; $(MOD_INSTALL) \
		"$(INST_LIB)" "$(DESTINSTALLVENDORLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLVENDORARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLVENDORBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLVENDORSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLVENDORMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLVENDORMAN3DIR)"


doc_perl_install :: all

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLSITEARCH)/perllocal.pod"
	-$(NOECHO) umask 02; $(MKPATH) "$(DESTINSTALLSITEARCH)"
	-$(NOECHO) umask 02; $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLSITEARCH)/perllocal.pod"

doc_vendor_install :: all


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) "$(SITEARCHEXP)/auto/$(FULLEXT)/.packlist"

uninstall_from_vendordirs ::


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
FULLPERL      = "/usr/bin/perl"
MAP_PERLINC   = "-Iblib/arch" "-Iblib/lib" "-I/usr/lib/x86_64-linux-gnu/perl/5.38" "-I/usr/share/perl/5.38"

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
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: dynamic pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

subdirs-test_static :: static pure_all

test_static :: subdirs-test_static
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_static :: static pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)



# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="App-SeismicUnixGui" VERSION="0.87.2">' > App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT>A graphical user interface for Seismic Unix</ABSTRACT>' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>Juan Lorenzo &lt;gllore@lsu.edu&gt;</AUTHOR>' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Clone::" VERSION="0.45" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::ShareDir" VERSION="1.118" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::Slurp" VERSION="9999.32" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="MIME::Base64" VERSION="3.16" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Module::Refresh" VERSION="0.18" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Moose::" VERSION="2.2015" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="PDL::" VERSION="2.080" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Shell::" VERSION="v0.73.1" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Time::HiRes" VERSION="1.9764" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Tk::" VERSION="804.036" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Tk::JFileDialog" VERSION="2.20" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Tk::Pod" VERSION="0.9943" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="aliased::" VERSION="0.34" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="namespace::autoclean" VERSION="0.29" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="x86_64-linux-gnu-thread-multi-5.38" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> App-SeismicUnixGui.ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> App-SeismicUnixGui.ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui.pm' 'blib/lib/App/SeismicUnixGui.pm' \
	  'lib/App/SeismicUnixGui/big_streams/.FileHistory.txt' 'blib/lib/App/SeismicUnixGui/big_streams/.FileHistory.txt' \
	  'lib/App/SeismicUnixGui/big_streams/BackupProject.pl' 'blib/lib/App/SeismicUnixGui/big_streams/BackupProject.pl' \
	  'lib/App/SeismicUnixGui/big_streams/Project.pl' 'blib/lib/App/SeismicUnixGui/big_streams/Project.pl' \
	  'lib/App/SeismicUnixGui/big_streams/RestoreProject.pl' 'blib/lib/App/SeismicUnixGui/big_streams/RestoreProject.pl' \
	  'lib/App/SeismicUnixGui/big_streams/SetProject.pl' 'blib/lib/App/SeismicUnixGui/big_streams/SetProject.pl' \
	  'lib/App/SeismicUnixGui/big_streams/Sseg2su.pl' 'blib/lib/App/SeismicUnixGui/big_streams/Sseg2su.pl' \
	  'lib/App/SeismicUnixGui/big_streams/Sucat.pl' 'blib/lib/App/SeismicUnixGui/big_streams/Sucat.pl' \
	  'lib/App/SeismicUnixGui/big_streams/Sudipfilt.pl' 'blib/lib/App/SeismicUnixGui/big_streams/Sudipfilt.pl' \
	  'lib/App/SeismicUnixGui/big_streams/Synseis.pl' 'blib/lib/App/SeismicUnixGui/big_streams/Synseis.pl' \
	  'lib/App/SeismicUnixGui/big_streams/Synseis.pm' 'blib/lib/App/SeismicUnixGui/big_streams/Synseis.pm' \
	  'lib/App/SeismicUnixGui/big_streams/archive/iBottomMute_config.pm' 'blib/lib/App/SeismicUnixGui/big_streams/archive/iBottomMute_config.pm' \
	  'lib/App/SeismicUnixGui/big_streams/check.pm' 'blib/lib/App/SeismicUnixGui/big_streams/check.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iApply_bottom_mute.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iApply_bottom_mute.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iApply_mute.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iApply_mute.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iApply_top_mute.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iApply_top_mute.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iBottomMute.pl' 'blib/lib/App/SeismicUnixGui/big_streams/iBottomMute.pl' \
	  'lib/App/SeismicUnixGui/big_streams/iBottomMute.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iBottomMute.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iBottomMutePicks2par.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iBottomMutePicks2par.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iPick.pl' 'blib/lib/App/SeismicUnixGui/big_streams/iPick.pl' \
	  'lib/App/SeismicUnixGui/big_streams/iPick.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iPick.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iPicks2par.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iPicks2par.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iPicks2sort.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iPicks2sort.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iSave_bottom_mute_picks.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iSave_bottom_mute_picks.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/big_streams/iSave_mute_picks.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iSave_mute_picks.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iSave_picks.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iSave_picks.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iSave_top_mute_picks.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iSave_top_mute_picks.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iSelect_tr_Sumute.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iSelect_tr_Sumute.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iSelect_tr_Sumute_bottom.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iSelect_tr_Sumute_bottom.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iSelect_tr_Sumute_top.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iSelect_tr_Sumute_top.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iSelect_xt.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iSelect_xt.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iShowNselect_picks.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iShowNselect_picks.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iShow_picks.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iShow_picks.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iSpectralAnalysis.pl' 'blib/lib/App/SeismicUnixGui/big_streams/iSpectralAnalysis.pl' \
	  'lib/App/SeismicUnixGui/big_streams/iSpectralAnalysis.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iSpectralAnalysis.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iSunmo.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iSunmo.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iSuvelan.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iSuvelan.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iTopMute.pl' 'blib/lib/App/SeismicUnixGui/big_streams/iTopMute.pl' \
	  'lib/App/SeismicUnixGui/big_streams/iTopMute.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iTopMute.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iTopMutePicks2par.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iTopMutePicks2par.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iVA.pl' 'blib/lib/App/SeismicUnixGui/big_streams/iVA.pl' \
	  'lib/App/SeismicUnixGui/big_streams/iVA.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iVA.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iVelocityAnalysis.pl' 'blib/lib/App/SeismicUnixGui/big_streams/iVelocityAnalysis.pl' \
	  'lib/App/SeismicUnixGui/big_streams/iVpicks2par.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iVpicks2par.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iVrms2Vint.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iVrms2Vint.pm' \
	  'lib/App/SeismicUnixGui/big_streams/iWrite_All_iva_out.pm' 'blib/lib/App/SeismicUnixGui/big_streams/iWrite_All_iva_out.pm' \
	  'lib/App/SeismicUnixGui/big_streams/immodpg.pl' 'blib/lib/App/SeismicUnixGui/big_streams/immodpg.pl' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/big_streams/immodpg.pm' 'blib/lib/App/SeismicUnixGui/big_streams/immodpg.pm' \
	  'lib/App/SeismicUnixGui/big_streams/immodpg_global_constants.pm' 'blib/lib/App/SeismicUnixGui/big_streams/immodpg_global_constants.pm' \
	  'lib/App/SeismicUnixGui/big_streams/pre_built_big_stream.pm' 'blib/lib/App/SeismicUnixGui/big_streams/pre_built_big_stream.pm' \
	  'lib/App/SeismicUnixGui/big_streams/test.pl' 'blib/lib/App/SeismicUnixGui/big_streams/test.pl' \
	  'lib/App/SeismicUnixGui/c/bin/synseis' 'blib/lib/App/SeismicUnixGui/c/bin/synseis' \
	  'lib/App/SeismicUnixGui/c/bin/synseis_old' 'blib/lib/App/SeismicUnixGui/c/bin/synseis_old' \
	  'lib/App/SeismicUnixGui/c/bin/tbd' 'blib/lib/App/SeismicUnixGui/c/bin/tbd' \
	  'lib/App/SeismicUnixGui/c/bin/test' 'blib/lib/App/SeismicUnixGui/c/bin/test' \
	  'lib/App/SeismicUnixGui/c/bin/zrhov' 'blib/lib/App/SeismicUnixGui/c/bin/zrhov' \
	  'lib/App/SeismicUnixGui/c/obj/keep' 'blib/lib/App/SeismicUnixGui/c/obj/keep' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/1027.source' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/1027.source' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/1027.source.su' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/1027.source.su' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/mk' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/mk' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/mod' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/mod' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/plot_rc.sh' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/plot_rc.sh' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/plot_ss.sh' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/plot_ss.sh' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/plot_zrhoreg.sh' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/plot_zrhoreg.sh' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/plot_zvreg.sh' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/plot_zvreg.sh' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/rc_t' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/rc_t' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/rc_t.bin' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/rc_t.bin' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/rc_z' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/rc_z' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/rc_z.bin' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/rc_z.bin' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/source.out' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/source.out' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/ss' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/ss' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/ss.bin' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/ss.bin' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/c/synseis/archive/sufft_source.sh' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/sufft_source.sh' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/synseis' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/synseis' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/synseis.c.bck' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/synseis.c.bck' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/synseis.sh' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/synseis.sh' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/synseis.tz' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/synseis.tz' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/synseis_bck' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/synseis_bck' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/xk' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/xk' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/zrho.reg' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/zrho.reg' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/zrho.reg.bin' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/zrho.reg.bin' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/zrhov' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/zrhov' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/zrhov.904' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/zrhov.904' \
	  'lib/App/SeismicUnixGui/c/synseis/archive/zv.reg' 'blib/lib/App/SeismicUnixGui/c/synseis/archive/zv.reg' \
	  'lib/App/SeismicUnixGui/c/synseis/makefile' 'blib/lib/App/SeismicUnixGui/c/synseis/makefile' \
	  'lib/App/SeismicUnixGui/c/synseis/run_me_only.sh' 'blib/lib/App/SeismicUnixGui/c/synseis/run_me_only.sh' \
	  'lib/App/SeismicUnixGui/c/synseis/set_env_variables.sh' 'blib/lib/App/SeismicUnixGui/c/synseis/set_env_variables.sh' \
	  'lib/App/SeismicUnixGui/c/synseis/src/synseis.c' 'blib/lib/App/SeismicUnixGui/c/synseis/src/synseis.c' \
	  'lib/App/SeismicUnixGui/c/synseis/src/synseis_bck.c' 'blib/lib/App/SeismicUnixGui/c/synseis/src/synseis_bck.c' \
	  'lib/App/SeismicUnixGui/c/synseis/src/tbd.c' 'blib/lib/App/SeismicUnixGui/c/synseis/src/tbd.c' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/dzdv.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/dzdv.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sucvs4fowler.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sucvs4fowler.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudivstack.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudivstack.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmofk.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmofk.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmofkcw.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmofkcw.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmotivz.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmotivz.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmotx.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmotx.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmovz.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sudmovz.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suilog.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suilog.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suintvel.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suintvel.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sulog.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sulog.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sunmo.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sunmo.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sunmo021020.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sunmo021020.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sunmo_a.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sunmo_a.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/supws.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/supws.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/surecip.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/surecip.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sureduce.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sureduce.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/surelan.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/surelan.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/surelanan.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/surelanan.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suresamp.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suresamp.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sushift.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sushift.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sustack.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sustack.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sustkvel.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sustkvel.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sutaupnmo.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sutaupnmo.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sutihaledmo.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sutihaledmo.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sutivel.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sutivel.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sutsq.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/sutsq.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suttoz.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suttoz.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suvel2df.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suvel2df.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suvelan.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suvelan.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suvelan_nccs.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suvelan_nccs.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suvelan_nsel.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suvelan_nsel.config' \
	  'lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suztot.config' 'blib/lib/App/SeismicUnixGui/configs/NMO_Vel_Stk/suztot.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/BackupProject.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/BackupProject.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/BackupProject_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/BackupProject_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/Project.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/Project.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/Project_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/Project_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/RestoreProject.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/RestoreProject.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/RestoreProject_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/RestoreProject_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/Sseg2su.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/Sseg2su.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/Sseg2su_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/Sseg2su_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/Sucat.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/Sucat.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/Sucat_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/Sucat_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/Sudipfilt.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/Sudipfilt.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/Sudipfilt_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/Sudipfilt_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/Synseis.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/Synseis.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/big_streams/Synseis_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/Synseis_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iBottomMute.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iBottomMute.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iBottomMute_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iBottomMute_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iBottom_Mute3.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iBottom_Mute3.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iPick.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iPick.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iPick_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iPick_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iSpectralAnalysis.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iSpectralAnalysis.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iSpectralAnalysis_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iSpectralAnalysis_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iSurf4_bottom_right_wiggle.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iSurf4_bottom_right_wiggle.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iSurf4_top_left_image.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iSurf4_top_left_image.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iSurf4_top_middle_wiggle.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iSurf4_top_middle_wiggle.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iSurf4_top_right_image.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iSurf4_top_right_image.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iSurf4_top_right_wiggle.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iSurf4_top_right_wiggle.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iTopMute.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iTopMute.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iTopMute_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iTopMute_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iTop_Mute3.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iTop_Mute3.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iVA.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iVA.config' \
	  'lib/App/SeismicUnixGui/configs/big_streams/iVA_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/iVA_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/immodpg.config' 'blib/lib/App/SeismicUnixGui/configs/big_streams/immodpg.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/big_streams/immodpg.out' 'blib/lib/App/SeismicUnixGui/configs/big_streams/immodpg.out' \
	  'lib/App/SeismicUnixGui/configs/big_streams/immodpg_config.pm' 'blib/lib/App/SeismicUnixGui/configs/big_streams/immodpg_config.pm' \
	  'lib/App/SeismicUnixGui/configs/big_streams/model.txt' 'blib/lib/App/SeismicUnixGui/configs/big_streams/model.txt' \
	  'lib/App/SeismicUnixGui/configs/data/ctrlstrip.config' 'blib/lib/App/SeismicUnixGui/configs/data/ctrlstrip.config' \
	  'lib/App/SeismicUnixGui/configs/data/data_in.config' 'blib/lib/App/SeismicUnixGui/configs/data/data_in.config' \
	  'lib/App/SeismicUnixGui/configs/data/data_out.config' 'blib/lib/App/SeismicUnixGui/configs/data/data_out.config' \
	  'lib/App/SeismicUnixGui/configs/data/dt1tosu.config' 'blib/lib/App/SeismicUnixGui/configs/data/dt1tosu.config' \
	  'lib/App/SeismicUnixGui/configs/data/segbread.config' 'blib/lib/App/SeismicUnixGui/configs/data/segbread.config' \
	  'lib/App/SeismicUnixGui/configs/data/segdread.config' 'blib/lib/App/SeismicUnixGui/configs/data/segdread.config' \
	  'lib/App/SeismicUnixGui/configs/data/segyread.config' 'blib/lib/App/SeismicUnixGui/configs/data/segyread.config' \
	  'lib/App/SeismicUnixGui/configs/data/segyscan.config' 'blib/lib/App/SeismicUnixGui/configs/data/segyscan.config' \
	  'lib/App/SeismicUnixGui/configs/data/segywrite.config' 'blib/lib/App/SeismicUnixGui/configs/data/segywrite.config' \
	  'lib/App/SeismicUnixGui/configs/data/suoldtonew.config' 'blib/lib/App/SeismicUnixGui/configs/data/suoldtonew.config' \
	  'lib/App/SeismicUnixGui/configs/data/supack1.config' 'blib/lib/App/SeismicUnixGui/configs/data/supack1.config' \
	  'lib/App/SeismicUnixGui/configs/data/supack2.config' 'blib/lib/App/SeismicUnixGui/configs/data/supack2.config' \
	  'lib/App/SeismicUnixGui/configs/data/suswapbytes.config' 'blib/lib/App/SeismicUnixGui/configs/data/suswapbytes.config' \
	  'lib/App/SeismicUnixGui/configs/data/suunpack1.config' 'blib/lib/App/SeismicUnixGui/configs/data/suunpack1.config' \
	  'lib/App/SeismicUnixGui/configs/data/suunpack2.config' 'blib/lib/App/SeismicUnixGui/configs/data/suunpack2.config' \
	  'lib/App/SeismicUnixGui/configs/data/wpc1uncomp2.config' 'blib/lib/App/SeismicUnixGui/configs/data/wpc1uncomp2.config' \
	  'lib/App/SeismicUnixGui/configs/data/wpccompress.config' 'blib/lib/App/SeismicUnixGui/configs/data/wpccompress.config' \
	  'lib/App/SeismicUnixGui/configs/data/wpcuncompress.config' 'blib/lib/App/SeismicUnixGui/configs/data/wpcuncompress.config' \
	  'lib/App/SeismicUnixGui/configs/data/wptcomp.config' 'blib/lib/App/SeismicUnixGui/configs/data/wptcomp.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/data/wptuncomp.config' 'blib/lib/App/SeismicUnixGui/configs/data/wptuncomp.config' \
	  'lib/App/SeismicUnixGui/configs/data/wtcomp.config' 'blib/lib/App/SeismicUnixGui/configs/data/wtcomp.config' \
	  'lib/App/SeismicUnixGui/configs/data/wtuncomp.config' 'blib/lib/App/SeismicUnixGui/configs/data/wtuncomp.config' \
	  'lib/App/SeismicUnixGui/configs/datum/sudatumk2dr.config' 'blib/lib/App/SeismicUnixGui/configs/datum/sudatumk2dr.config' \
	  'lib/App/SeismicUnixGui/configs/datum/sudatumk2ds.config' 'blib/lib/App/SeismicUnixGui/configs/datum/sudatumk2ds.config' \
	  'lib/App/SeismicUnixGui/configs/datum/sukdmdcr.config' 'blib/lib/App/SeismicUnixGui/configs/datum/sukdmdcr.config' \
	  'lib/App/SeismicUnixGui/configs/datum/sukdmdcs.config' 'blib/lib/App/SeismicUnixGui/configs/datum/sukdmdcs.config' \
	  'lib/App/SeismicUnixGui/configs/filter/subfilt.config' 'blib/lib/App/SeismicUnixGui/configs/filter/subfilt.config' \
	  'lib/App/SeismicUnixGui/configs/filter/succfilt.config' 'blib/lib/App/SeismicUnixGui/configs/filter/succfilt.config' \
	  'lib/App/SeismicUnixGui/configs/filter/sucddecon.config' 'blib/lib/App/SeismicUnixGui/configs/filter/sucddecon.config' \
	  'lib/App/SeismicUnixGui/configs/filter/sudipfilt.config' 'blib/lib/App/SeismicUnixGui/configs/filter/sudipfilt.config' \
	  'lib/App/SeismicUnixGui/configs/filter/sueipofi.config' 'blib/lib/App/SeismicUnixGui/configs/filter/sueipofi.config' \
	  'lib/App/SeismicUnixGui/configs/filter/sufilter.config' 'blib/lib/App/SeismicUnixGui/configs/filter/sufilter.config' \
	  'lib/App/SeismicUnixGui/configs/filter/sufrac.config' 'blib/lib/App/SeismicUnixGui/configs/filter/sufrac.config' \
	  'lib/App/SeismicUnixGui/configs/filter/sufwatrim.config' 'blib/lib/App/SeismicUnixGui/configs/filter/sufwatrim.config' \
	  'lib/App/SeismicUnixGui/configs/filter/sufxdecon.config' 'blib/lib/App/SeismicUnixGui/configs/filter/sufxdecon.config' \
	  'lib/App/SeismicUnixGui/configs/filter/sugroll.config' 'blib/lib/App/SeismicUnixGui/configs/filter/sugroll.config' \
	  'lib/App/SeismicUnixGui/configs/filter/suk1k2filter.config' 'blib/lib/App/SeismicUnixGui/configs/filter/suk1k2filter.config' \
	  'lib/App/SeismicUnixGui/configs/filter/sukfilter.config' 'blib/lib/App/SeismicUnixGui/configs/filter/sukfilter.config' \
	  'lib/App/SeismicUnixGui/configs/filter/sulfaf.config' 'blib/lib/App/SeismicUnixGui/configs/filter/sulfaf.config' \
	  'lib/App/SeismicUnixGui/configs/filter/sumedian.config' 'blib/lib/App/SeismicUnixGui/configs/filter/sumedian.config' \
	  'lib/App/SeismicUnixGui/configs/filter/supef.config' 'blib/lib/App/SeismicUnixGui/configs/filter/supef.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/filter/suphase.config' 'blib/lib/App/SeismicUnixGui/configs/filter/suphase.config' \
	  'lib/App/SeismicUnixGui/configs/filter/suphidecon.config' 'blib/lib/App/SeismicUnixGui/configs/filter/suphidecon.config' \
	  'lib/App/SeismicUnixGui/configs/filter/supofilt.config' 'blib/lib/App/SeismicUnixGui/configs/filter/supofilt.config' \
	  'lib/App/SeismicUnixGui/configs/filter/supolar.config' 'blib/lib/App/SeismicUnixGui/configs/filter/supolar.config' \
	  'lib/App/SeismicUnixGui/configs/filter/susmgauss2.config' 'blib/lib/App/SeismicUnixGui/configs/filter/susmgauss2.config' \
	  'lib/App/SeismicUnixGui/configs/filter/sutvband.config' 'blib/lib/App/SeismicUnixGui/configs/filter/sutvband.config' \
	  'lib/App/SeismicUnixGui/configs/header/segyclean.config' 'blib/lib/App/SeismicUnixGui/configs/header/segyclean.config' \
	  'lib/App/SeismicUnixGui/configs/header/segyhdrmod.config' 'blib/lib/App/SeismicUnixGui/configs/header/segyhdrmod.config' \
	  'lib/App/SeismicUnixGui/configs/header/segyhdrs.config' 'blib/lib/App/SeismicUnixGui/configs/header/segyhdrs.config' \
	  'lib/App/SeismicUnixGui/configs/header/setbhed.config' 'blib/lib/App/SeismicUnixGui/configs/header/setbhed.config' \
	  'lib/App/SeismicUnixGui/configs/header/su3dchart.config' 'blib/lib/App/SeismicUnixGui/configs/header/su3dchart.config' \
	  'lib/App/SeismicUnixGui/configs/header/suabshw.config' 'blib/lib/App/SeismicUnixGui/configs/header/suabshw.config' \
	  'lib/App/SeismicUnixGui/configs/header/suaddhead.config' 'blib/lib/App/SeismicUnixGui/configs/header/suaddhead.config' \
	  'lib/App/SeismicUnixGui/configs/header/suaddstatics.config' 'blib/lib/App/SeismicUnixGui/configs/header/suaddstatics.config' \
	  'lib/App/SeismicUnixGui/configs/header/suahw.config' 'blib/lib/App/SeismicUnixGui/configs/header/suahw.config' \
	  'lib/App/SeismicUnixGui/configs/header/suascii.config' 'blib/lib/App/SeismicUnixGui/configs/header/suascii.config' \
	  'lib/App/SeismicUnixGui/configs/header/suazimuth.config' 'blib/lib/App/SeismicUnixGui/configs/header/suazimuth.config' \
	  'lib/App/SeismicUnixGui/configs/header/sucdpbin.config' 'blib/lib/App/SeismicUnixGui/configs/header/sucdpbin.config' \
	  'lib/App/SeismicUnixGui/configs/header/suchart.config' 'blib/lib/App/SeismicUnixGui/configs/header/suchart.config' \
	  'lib/App/SeismicUnixGui/configs/header/suchw.config' 'blib/lib/App/SeismicUnixGui/configs/header/suchw.config' \
	  'lib/App/SeismicUnixGui/configs/header/sucliphead.config' 'blib/lib/App/SeismicUnixGui/configs/header/sucliphead.config' \
	  'lib/App/SeismicUnixGui/configs/header/sucountkey.config' 'blib/lib/App/SeismicUnixGui/configs/header/sucountkey.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/header/sudumptrace.config' 'blib/lib/App/SeismicUnixGui/configs/header/sudumptrace.config' \
	  'lib/App/SeismicUnixGui/configs/header/suedit.config' 'blib/lib/App/SeismicUnixGui/configs/header/suedit.config' \
	  'lib/App/SeismicUnixGui/configs/header/sugethw.config' 'blib/lib/App/SeismicUnixGui/configs/header/sugethw.config' \
	  'lib/App/SeismicUnixGui/configs/header/suhtmath.config' 'blib/lib/App/SeismicUnixGui/configs/header/suhtmath.config' \
	  'lib/App/SeismicUnixGui/configs/header/sukeycount.config' 'blib/lib/App/SeismicUnixGui/configs/header/sukeycount.config' \
	  'lib/App/SeismicUnixGui/configs/header/sulcthw.config' 'blib/lib/App/SeismicUnixGui/configs/header/sulcthw.config' \
	  'lib/App/SeismicUnixGui/configs/header/sulhead.config' 'blib/lib/App/SeismicUnixGui/configs/header/sulhead.config' \
	  'lib/App/SeismicUnixGui/configs/header/supaste.config' 'blib/lib/App/SeismicUnixGui/configs/header/supaste.config' \
	  'lib/App/SeismicUnixGui/configs/header/surandhw.config' 'blib/lib/App/SeismicUnixGui/configs/header/surandhw.config' \
	  'lib/App/SeismicUnixGui/configs/header/surange.config' 'blib/lib/App/SeismicUnixGui/configs/header/surange.config' \
	  'lib/App/SeismicUnixGui/configs/header/suresstat.config' 'blib/lib/App/SeismicUnixGui/configs/header/suresstat.config' \
	  'lib/App/SeismicUnixGui/configs/header/susehw.config' 'blib/lib/App/SeismicUnixGui/configs/header/susehw.config' \
	  'lib/App/SeismicUnixGui/configs/header/sushw.config' 'blib/lib/App/SeismicUnixGui/configs/header/sushw.config' \
	  'lib/App/SeismicUnixGui/configs/header/sustatic.config' 'blib/lib/App/SeismicUnixGui/configs/header/sustatic.config' \
	  'lib/App/SeismicUnixGui/configs/header/sustaticB.config' 'blib/lib/App/SeismicUnixGui/configs/header/sustaticB.config' \
	  'lib/App/SeismicUnixGui/configs/header/sustaticrrs.config' 'blib/lib/App/SeismicUnixGui/configs/header/sustaticrrs.config' \
	  'lib/App/SeismicUnixGui/configs/header/sustrip.config' 'blib/lib/App/SeismicUnixGui/configs/header/sustrip.config' \
	  'lib/App/SeismicUnixGui/configs/header/sutrcount.config' 'blib/lib/App/SeismicUnixGui/configs/header/sutrcount.config' \
	  'lib/App/SeismicUnixGui/configs/header/suutm.config' 'blib/lib/App/SeismicUnixGui/configs/header/suutm.config' \
	  'lib/App/SeismicUnixGui/configs/header/suxedit.config' 'blib/lib/App/SeismicUnixGui/configs/header/suxedit.config' \
	  'lib/App/SeismicUnixGui/configs/header/swapbhed.config' 'blib/lib/App/SeismicUnixGui/configs/header/swapbhed.config' \
	  'lib/App/SeismicUnixGui/configs/inversion/suinvco3d.config' 'blib/lib/App/SeismicUnixGui/configs/inversion/suinvco3d.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/inversion/suinvvxzco.config' 'blib/lib/App/SeismicUnixGui/configs/inversion/suinvvxzco.config' \
	  'lib/App/SeismicUnixGui/configs/inversion/suinvzco3d.config' 'blib/lib/App/SeismicUnixGui/configs/inversion/suinvzco3d.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sudatumfd.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sudatumfd.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sugazmig.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sugazmig.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sukdmig2d.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sukdmig2d.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sukdmig3d.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sukdmig3d.config' \
	  'lib/App/SeismicUnixGui/configs/migration/suktmig2d.config' 'blib/lib/App/SeismicUnixGui/configs/migration/suktmig2d.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumigfd.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumigfd.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumigffd.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumigffd.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumiggbzo.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumiggbzo.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumiggbzoan.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumiggbzoan.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumigprefd.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumigprefd.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumigpreffd.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumigpreffd.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumigprepspi.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumigprepspi.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumigpresp.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumigpresp.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumigps.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumigps.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumigpspi.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumigpspi.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumigpsti.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumigpsti.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumigsplit.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumigsplit.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumigtk.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumigtk.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sumigtopo2d.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sumigtopo2d.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/migration/sunmo.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sunmo.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sustolt.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sustolt.config' \
	  'lib/App/SeismicUnixGui/configs/migration/sutifowler.config' 'blib/lib/App/SeismicUnixGui/configs/migration/sutifowler.config' \
	  'lib/App/SeismicUnixGui/configs/model/addrvl3d.config' 'blib/lib/App/SeismicUnixGui/configs/model/addrvl3d.config' \
	  'lib/App/SeismicUnixGui/configs/model/cellauto.config' 'blib/lib/App/SeismicUnixGui/configs/model/cellauto.config' \
	  'lib/App/SeismicUnixGui/configs/model/elacheck.config' 'blib/lib/App/SeismicUnixGui/configs/model/elacheck.config' \
	  'lib/App/SeismicUnixGui/configs/model/elamodel.config' 'blib/lib/App/SeismicUnixGui/configs/model/elamodel.config' \
	  'lib/App/SeismicUnixGui/configs/model/elaray.config' 'blib/lib/App/SeismicUnixGui/configs/model/elaray.config' \
	  'lib/App/SeismicUnixGui/configs/model/elasyn.config' 'blib/lib/App/SeismicUnixGui/configs/model/elasyn.config' \
	  'lib/App/SeismicUnixGui/configs/model/elatriuni.config' 'blib/lib/App/SeismicUnixGui/configs/model/elatriuni.config' \
	  'lib/App/SeismicUnixGui/configs/model/gbbeam.config' 'blib/lib/App/SeismicUnixGui/configs/model/gbbeam.config' \
	  'lib/App/SeismicUnixGui/configs/model/grm.config' 'blib/lib/App/SeismicUnixGui/configs/model/grm.config' \
	  'lib/App/SeismicUnixGui/configs/model/normray.config' 'blib/lib/App/SeismicUnixGui/configs/model/normray.config' \
	  'lib/App/SeismicUnixGui/configs/model/raydata.config' 'blib/lib/App/SeismicUnixGui/configs/model/raydata.config' \
	  'lib/App/SeismicUnixGui/configs/model/suaddevent.config' 'blib/lib/App/SeismicUnixGui/configs/model/suaddevent.config' \
	  'lib/App/SeismicUnixGui/configs/model/suaddnoise.config' 'blib/lib/App/SeismicUnixGui/configs/model/suaddnoise.config' \
	  'lib/App/SeismicUnixGui/configs/model/sudgwaveform.config' 'blib/lib/App/SeismicUnixGui/configs/model/sudgwaveform.config' \
	  'lib/App/SeismicUnixGui/configs/model/suea2df.config' 'blib/lib/App/SeismicUnixGui/configs/model/suea2df.config' \
	  'lib/App/SeismicUnixGui/configs/model/sufctanismod.config' 'blib/lib/App/SeismicUnixGui/configs/model/sufctanismod.config' \
	  'lib/App/SeismicUnixGui/configs/model/sufdmod1.config' 'blib/lib/App/SeismicUnixGui/configs/model/sufdmod1.config' \
	  'lib/App/SeismicUnixGui/configs/model/sufdmod2.config' 'blib/lib/App/SeismicUnixGui/configs/model/sufdmod2.config' \
	  'lib/App/SeismicUnixGui/configs/model/sufdmod2_pml.config' 'blib/lib/App/SeismicUnixGui/configs/model/sufdmod2_pml.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/model/sugoupillaud.config' 'blib/lib/App/SeismicUnixGui/configs/model/sugoupillaud.config' \
	  'lib/App/SeismicUnixGui/configs/model/sugoupillaudpo.config' 'blib/lib/App/SeismicUnixGui/configs/model/sugoupillaudpo.config' \
	  'lib/App/SeismicUnixGui/configs/model/suimp2d.config' 'blib/lib/App/SeismicUnixGui/configs/model/suimp2d.config' \
	  'lib/App/SeismicUnixGui/configs/model/suimp3d.config' 'blib/lib/App/SeismicUnixGui/configs/model/suimp3d.config' \
	  'lib/App/SeismicUnixGui/configs/model/suimpedance.config' 'blib/lib/App/SeismicUnixGui/configs/model/suimpedance.config' \
	  'lib/App/SeismicUnixGui/configs/model/sujitter.config' 'blib/lib/App/SeismicUnixGui/configs/model/sujitter.config' \
	  'lib/App/SeismicUnixGui/configs/model/sukdsyn2d.config' 'blib/lib/App/SeismicUnixGui/configs/model/sukdsyn2d.config' \
	  'lib/App/SeismicUnixGui/configs/model/sunull.config' 'blib/lib/App/SeismicUnixGui/configs/model/sunull.config' \
	  'lib/App/SeismicUnixGui/configs/model/suplane.config' 'blib/lib/App/SeismicUnixGui/configs/model/suplane.config' \
	  'lib/App/SeismicUnixGui/configs/model/surandspike.config' 'blib/lib/App/SeismicUnixGui/configs/model/surandspike.config' \
	  'lib/App/SeismicUnixGui/configs/model/surandstat.config' 'blib/lib/App/SeismicUnixGui/configs/model/surandstat.config' \
	  'lib/App/SeismicUnixGui/configs/model/suremac2d.config' 'blib/lib/App/SeismicUnixGui/configs/model/suremac2d.config' \
	  'lib/App/SeismicUnixGui/configs/model/suremel2dan.config' 'blib/lib/App/SeismicUnixGui/configs/model/suremel2dan.config' \
	  'lib/App/SeismicUnixGui/configs/model/suspike.config' 'blib/lib/App/SeismicUnixGui/configs/model/suspike.config' \
	  'lib/App/SeismicUnixGui/configs/model/susyncz.config' 'blib/lib/App/SeismicUnixGui/configs/model/susyncz.config' \
	  'lib/App/SeismicUnixGui/configs/model/susynlv.config' 'blib/lib/App/SeismicUnixGui/configs/model/susynlv.config' \
	  'lib/App/SeismicUnixGui/configs/model/susynlvcw.config' 'blib/lib/App/SeismicUnixGui/configs/model/susynlvcw.config' \
	  'lib/App/SeismicUnixGui/configs/model/susynlvfti.config' 'blib/lib/App/SeismicUnixGui/configs/model/susynlvfti.config' \
	  'lib/App/SeismicUnixGui/configs/model/susynvxz.config' 'blib/lib/App/SeismicUnixGui/configs/model/susynvxz.config' \
	  'lib/App/SeismicUnixGui/configs/model/susynvxzcs.config' 'blib/lib/App/SeismicUnixGui/configs/model/susynvxzcs.config' \
	  'lib/App/SeismicUnixGui/configs/par/a2b.config' 'blib/lib/App/SeismicUnixGui/configs/par/a2b.config' \
	  'lib/App/SeismicUnixGui/configs/par/a2i.config' 'blib/lib/App/SeismicUnixGui/configs/par/a2i.config' \
	  'lib/App/SeismicUnixGui/configs/par/b2a.config' 'blib/lib/App/SeismicUnixGui/configs/par/b2a.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/par/bhedtopar.config' 'blib/lib/App/SeismicUnixGui/configs/par/bhedtopar.config' \
	  'lib/App/SeismicUnixGui/configs/par/cshotplot.config' 'blib/lib/App/SeismicUnixGui/configs/par/cshotplot.config' \
	  'lib/App/SeismicUnixGui/configs/par/float2ibm.config' 'blib/lib/App/SeismicUnixGui/configs/par/float2ibm.config' \
	  'lib/App/SeismicUnixGui/configs/par/ftnstrip.config' 'blib/lib/App/SeismicUnixGui/configs/par/ftnstrip.config' \
	  'lib/App/SeismicUnixGui/configs/par/ftnunstrip.config' 'blib/lib/App/SeismicUnixGui/configs/par/ftnunstrip.config' \
	  'lib/App/SeismicUnixGui/configs/par/makevel.config' 'blib/lib/App/SeismicUnixGui/configs/par/makevel.config' \
	  'lib/App/SeismicUnixGui/configs/par/mkparfile.config' 'blib/lib/App/SeismicUnixGui/configs/par/mkparfile.config' \
	  'lib/App/SeismicUnixGui/configs/par/transp.config' 'blib/lib/App/SeismicUnixGui/configs/par/transp.config' \
	  'lib/App/SeismicUnixGui/configs/par/unif2.config' 'blib/lib/App/SeismicUnixGui/configs/par/unif2.config' \
	  'lib/App/SeismicUnixGui/configs/par/unif2aniso.config' 'blib/lib/App/SeismicUnixGui/configs/par/unif2aniso.config' \
	  'lib/App/SeismicUnixGui/configs/par/unisam.config' 'blib/lib/App/SeismicUnixGui/configs/par/unisam.config' \
	  'lib/App/SeismicUnixGui/configs/par/unisam2.config' 'blib/lib/App/SeismicUnixGui/configs/par/unisam2.config' \
	  'lib/App/SeismicUnixGui/configs/par/vel2stiff.config' 'blib/lib/App/SeismicUnixGui/configs/par/vel2stiff.config' \
	  'lib/App/SeismicUnixGui/configs/plot/elaps.config' 'blib/lib/App/SeismicUnixGui/configs/plot/elaps.config' \
	  'lib/App/SeismicUnixGui/configs/plot/lcmap.config' 'blib/lib/App/SeismicUnixGui/configs/plot/lcmap.config' \
	  'lib/App/SeismicUnixGui/configs/plot/lprop.config' 'blib/lib/App/SeismicUnixGui/configs/plot/lprop.config' \
	  'lib/App/SeismicUnixGui/configs/plot/psbbox.config' 'blib/lib/App/SeismicUnixGui/configs/plot/psbbox.config' \
	  'lib/App/SeismicUnixGui/configs/plot/pscontour.config' 'blib/lib/App/SeismicUnixGui/configs/plot/pscontour.config' \
	  'lib/App/SeismicUnixGui/configs/plot/pscube.config' 'blib/lib/App/SeismicUnixGui/configs/plot/pscube.config' \
	  'lib/App/SeismicUnixGui/configs/plot/pscubecontour.config' 'blib/lib/App/SeismicUnixGui/configs/plot/pscubecontour.config' \
	  'lib/App/SeismicUnixGui/configs/plot/psepsi.config' 'blib/lib/App/SeismicUnixGui/configs/plot/psepsi.config' \
	  'lib/App/SeismicUnixGui/configs/plot/psgraph.config' 'blib/lib/App/SeismicUnixGui/configs/plot/psgraph.config' \
	  'lib/App/SeismicUnixGui/configs/plot/psimage.config' 'blib/lib/App/SeismicUnixGui/configs/plot/psimage.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/plot/pslabel.config' 'blib/lib/App/SeismicUnixGui/configs/plot/pslabel.config' \
	  'lib/App/SeismicUnixGui/configs/plot/psmanager.config' 'blib/lib/App/SeismicUnixGui/configs/plot/psmanager.config' \
	  'lib/App/SeismicUnixGui/configs/plot/psmerge.config' 'blib/lib/App/SeismicUnixGui/configs/plot/psmerge.config' \
	  'lib/App/SeismicUnixGui/configs/plot/psmovie.config' 'blib/lib/App/SeismicUnixGui/configs/plot/psmovie.config' \
	  'lib/App/SeismicUnixGui/configs/plot/pswigb.config' 'blib/lib/App/SeismicUnixGui/configs/plot/pswigb.config' \
	  'lib/App/SeismicUnixGui/configs/plot/pswigp.config' 'blib/lib/App/SeismicUnixGui/configs/plot/pswigp.config' \
	  'lib/App/SeismicUnixGui/configs/plot/scmap.config' 'blib/lib/App/SeismicUnixGui/configs/plot/scmap.config' \
	  'lib/App/SeismicUnixGui/configs/plot/spsplot.config' 'blib/lib/App/SeismicUnixGui/configs/plot/spsplot.config' \
	  'lib/App/SeismicUnixGui/configs/plot/supscontour.config' 'blib/lib/App/SeismicUnixGui/configs/plot/supscontour.config' \
	  'lib/App/SeismicUnixGui/configs/plot/supscube.config' 'blib/lib/App/SeismicUnixGui/configs/plot/supscube.config' \
	  'lib/App/SeismicUnixGui/configs/plot/supscubecontour.config' 'blib/lib/App/SeismicUnixGui/configs/plot/supscubecontour.config' \
	  'lib/App/SeismicUnixGui/configs/plot/supsgraph.config' 'blib/lib/App/SeismicUnixGui/configs/plot/supsgraph.config' \
	  'lib/App/SeismicUnixGui/configs/plot/supsimage.config' 'blib/lib/App/SeismicUnixGui/configs/plot/supsimage.config' \
	  'lib/App/SeismicUnixGui/configs/plot/supsmax.config' 'blib/lib/App/SeismicUnixGui/configs/plot/supsmax.config' \
	  'lib/App/SeismicUnixGui/configs/plot/supsmovie.config' 'blib/lib/App/SeismicUnixGui/configs/plot/supsmovie.config' \
	  'lib/App/SeismicUnixGui/configs/plot/supswigb.config' 'blib/lib/App/SeismicUnixGui/configs/plot/supswigb.config' \
	  'lib/App/SeismicUnixGui/configs/plot/supswigp.config' 'blib/lib/App/SeismicUnixGui/configs/plot/supswigp.config' \
	  'lib/App/SeismicUnixGui/configs/plot/suxcontour.config' 'blib/lib/App/SeismicUnixGui/configs/plot/suxcontour.config' \
	  'lib/App/SeismicUnixGui/configs/plot/suxgraph.config' 'blib/lib/App/SeismicUnixGui/configs/plot/suxgraph.config' \
	  'lib/App/SeismicUnixGui/configs/plot/suximage.config' 'blib/lib/App/SeismicUnixGui/configs/plot/suximage.config' \
	  'lib/App/SeismicUnixGui/configs/plot/suxmax.config' 'blib/lib/App/SeismicUnixGui/configs/plot/suxmax.config' \
	  'lib/App/SeismicUnixGui/configs/plot/suxmovie.config' 'blib/lib/App/SeismicUnixGui/configs/plot/suxmovie.config' \
	  'lib/App/SeismicUnixGui/configs/plot/suxpicker.config' 'blib/lib/App/SeismicUnixGui/configs/plot/suxpicker.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/plot/suxwigb.config' 'blib/lib/App/SeismicUnixGui/configs/plot/suxwigb.config' \
	  'lib/App/SeismicUnixGui/configs/plot/xcontour.config' 'blib/lib/App/SeismicUnixGui/configs/plot/xcontour.config' \
	  'lib/App/SeismicUnixGui/configs/plot/xgraph.config' 'blib/lib/App/SeismicUnixGui/configs/plot/xgraph.config' \
	  'lib/App/SeismicUnixGui/configs/plot/ximage.config' 'blib/lib/App/SeismicUnixGui/configs/plot/ximage.config' \
	  'lib/App/SeismicUnixGui/configs/plot/xmovie.config' 'blib/lib/App/SeismicUnixGui/configs/plot/xmovie.config' \
	  'lib/App/SeismicUnixGui/configs/plot/xpicker.config' 'blib/lib/App/SeismicUnixGui/configs/plot/xpicker.config' \
	  'lib/App/SeismicUnixGui/configs/plot/xwigb.config' 'blib/lib/App/SeismicUnixGui/configs/plot/xwigb.config' \
	  'lib/App/SeismicUnixGui/configs/shapeNcut/suflip.config' 'blib/lib/App/SeismicUnixGui/configs/shapeNcut/suflip.config' \
	  'lib/App/SeismicUnixGui/configs/shapeNcut/sugain.config' 'blib/lib/App/SeismicUnixGui/configs/shapeNcut/sugain.config' \
	  'lib/App/SeismicUnixGui/configs/shapeNcut/sugprfb.config' 'blib/lib/App/SeismicUnixGui/configs/shapeNcut/sugprfb.config' \
	  'lib/App/SeismicUnixGui/configs/shapeNcut/sukill.config' 'blib/lib/App/SeismicUnixGui/configs/shapeNcut/sukill.config' \
	  'lib/App/SeismicUnixGui/configs/shapeNcut/sumute.config' 'blib/lib/App/SeismicUnixGui/configs/shapeNcut/sumute.config' \
	  'lib/App/SeismicUnixGui/configs/shapeNcut/supad.config' 'blib/lib/App/SeismicUnixGui/configs/shapeNcut/supad.config' \
	  'lib/App/SeismicUnixGui/configs/shapeNcut/suramp.config' 'blib/lib/App/SeismicUnixGui/configs/shapeNcut/suramp.config' \
	  'lib/App/SeismicUnixGui/configs/shapeNcut/susort.config' 'blib/lib/App/SeismicUnixGui/configs/shapeNcut/susort.config' \
	  'lib/App/SeismicUnixGui/configs/shapeNcut/susplit.config' 'blib/lib/App/SeismicUnixGui/configs/shapeNcut/susplit.config' \
	  'lib/App/SeismicUnixGui/configs/shapeNcut/suvcat.config' 'blib/lib/App/SeismicUnixGui/configs/shapeNcut/suvcat.config' \
	  'lib/App/SeismicUnixGui/configs/shapeNcut/suwind.config' 'blib/lib/App/SeismicUnixGui/configs/shapeNcut/suwind.config' \
	  'lib/App/SeismicUnixGui/configs/shell/cat_su.config' 'blib/lib/App/SeismicUnixGui/configs/shell/cat_su.config' \
	  'lib/App/SeismicUnixGui/configs/shell/evince.config' 'blib/lib/App/SeismicUnixGui/configs/shell/evince.config' \
	  'lib/App/SeismicUnixGui/configs/shell/par/a2b.config' 'blib/lib/App/SeismicUnixGui/configs/shell/par/a2b.config' \
	  'lib/App/SeismicUnixGui/configs/shell/par/b2a.config' 'blib/lib/App/SeismicUnixGui/configs/shell/par/b2a.config' \
	  'lib/App/SeismicUnixGui/configs/shell/par/makevel.config' 'blib/lib/App/SeismicUnixGui/configs/shell/par/makevel.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/shell/par/mkparfile.config' 'blib/lib/App/SeismicUnixGui/configs/shell/par/mkparfile.config' \
	  'lib/App/SeismicUnixGui/configs/shell/par/unisam.config' 'blib/lib/App/SeismicUnixGui/configs/shell/par/unisam.config' \
	  'lib/App/SeismicUnixGui/configs/shell/par/unisam2.config' 'blib/lib/App/SeismicUnixGui/configs/shell/par/unisam2.config' \
	  'lib/App/SeismicUnixGui/configs/shell/sugetgthr.config' 'blib/lib/App/SeismicUnixGui/configs/shell/sugetgthr.config' \
	  'lib/App/SeismicUnixGui/configs/shell/suputgthr.config' 'blib/lib/App/SeismicUnixGui/configs/shell/suputgthr.config' \
	  'lib/App/SeismicUnixGui/configs/shell/xk.config' 'blib/lib/App/SeismicUnixGui/configs/shell/xk.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/cpftrend.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/cpftrend.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/entropy.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/entropy.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/farith.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/farith.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/suacor.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/suacor.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/suacorfrac.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/suacorfrac.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/sualford.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/sualford.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/suattributes.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/suattributes.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/suconv.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/suconv.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/sufwmix.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/sufwmix.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/suhistogram.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/suhistogram.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/suhrot.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/suhrot.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/suinterp.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/suinterp.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/sumax.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/sumax.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/sumean.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/sumean.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/sumix.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/sumix.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/suop.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/suop.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/statsMath/suop2.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/suop2.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/suxcor.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/suxcor.config' \
	  'lib/App/SeismicUnixGui/configs/statsMath/suxmax.config' 'blib/lib/App/SeismicUnixGui/configs/statsMath/suxmax.config' \
	  'lib/App/SeismicUnixGui/configs/transform/dctcomp.config' 'blib/lib/App/SeismicUnixGui/configs/transform/dctcomp.config' \
	  'lib/App/SeismicUnixGui/configs/transform/suamp.config' 'blib/lib/App/SeismicUnixGui/configs/transform/suamp.config' \
	  'lib/App/SeismicUnixGui/configs/transform/succepstrum.config' 'blib/lib/App/SeismicUnixGui/configs/transform/succepstrum.config' \
	  'lib/App/SeismicUnixGui/configs/transform/succwt.config' 'blib/lib/App/SeismicUnixGui/configs/transform/succwt.config' \
	  'lib/App/SeismicUnixGui/configs/transform/sucepstrum.config' 'blib/lib/App/SeismicUnixGui/configs/transform/sucepstrum.config' \
	  'lib/App/SeismicUnixGui/configs/transform/sucwt.config' 'blib/lib/App/SeismicUnixGui/configs/transform/sucwt.config' \
	  'lib/App/SeismicUnixGui/configs/transform/sufft.config' 'blib/lib/App/SeismicUnixGui/configs/transform/sufft.config' \
	  'lib/App/SeismicUnixGui/configs/transform/sugabor.config' 'blib/lib/App/SeismicUnixGui/configs/transform/sugabor.config' \
	  'lib/App/SeismicUnixGui/configs/transform/suicepstrum.config' 'blib/lib/App/SeismicUnixGui/configs/transform/suicepstrum.config' \
	  'lib/App/SeismicUnixGui/configs/transform/suifft.config' 'blib/lib/App/SeismicUnixGui/configs/transform/suifft.config' \
	  'lib/App/SeismicUnixGui/configs/transform/suminphase.config' 'blib/lib/App/SeismicUnixGui/configs/transform/suminphase.config' \
	  'lib/App/SeismicUnixGui/configs/transform/suphasevel.config' 'blib/lib/App/SeismicUnixGui/configs/transform/suphasevel.config' \
	  'lib/App/SeismicUnixGui/configs/transform/suspecfk.config' 'blib/lib/App/SeismicUnixGui/configs/transform/suspecfk.config' \
	  'lib/App/SeismicUnixGui/configs/transform/suspecfx.config' 'blib/lib/App/SeismicUnixGui/configs/transform/suspecfx.config' \
	  'lib/App/SeismicUnixGui/configs/transform/sutaup.config' 'blib/lib/App/SeismicUnixGui/configs/transform/sutaup.config' \
	  'lib/App/SeismicUnixGui/configs/well/las2su.config' 'blib/lib/App/SeismicUnixGui/configs/well/las2su.config' \
	  'lib/App/SeismicUnixGui/configs/well/subackus.config' 'blib/lib/App/SeismicUnixGui/configs/well/subackus.config' \
	  'lib/App/SeismicUnixGui/configs/well/subackush.config' 'blib/lib/App/SeismicUnixGui/configs/well/subackush.config' \
	  'lib/App/SeismicUnixGui/configs/well/sugassman.config' 'blib/lib/App/SeismicUnixGui/configs/well/sugassman.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/configs/well/sulprime.config' 'blib/lib/App/SeismicUnixGui/configs/well/sulprime.config' \
	  'lib/App/SeismicUnixGui/configs/well/suwellrf.config' 'blib/lib/App/SeismicUnixGui/configs/well/suwellrf.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/dzdv.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/dzdv.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/dzdv_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/dzdv_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sucvs4fowler.su.main.stacking' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sucvs4fowler.su.main.stacking' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudivstack.su.main.stacking' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudivstack.su.main.stacking' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmofk.su.main.dip_moveout' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmofk.su.main.dip_moveout' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmofkcw.su.main.dip_moveout' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmofkcw.su.main.dip_moveout' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmotivz.su.main.dip_moveout' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmotivz.su.main.dip_moveout' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmotx.su.main.dip_moveout' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmotx.su.main.dip_moveout' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmovz.su.main.dip_moveout' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sudmovz.su.main.dip_moveout' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suilog.su.main.stretching_moveout_resamp' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suilog.su.main.stretching_moveout_resamp' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suintvel.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suintvel.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sulog.su.main.stretching_moveout_resamp' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sulog.su.main.stretching_moveout_resamp' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sunmo.su.main.stretching_moveout_resamp' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sunmo.su.main.stretching_moveout_resamp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sunmo_a.su.main.stretching_moveout_resamp' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sunmo_a.su.main.stretching_moveout_resamp' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/supws.su.main.stacking' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/supws.su.main.stacking' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/surecip.su.main.stacking' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/surecip.su.main.stacking' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sureduce.su.main.stretching_moveout_resamp' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sureduce.su.main.stretching_moveout_resamp' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/surelan.su.main.velocity_analysis' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/surelan.su.main.velocity_analysis' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/surelanan.su.main.velocity_analysis' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/surelanan.su.main.velocity_analysis' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suresamp.su.main.stretching_moveout_resamp' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suresamp.su.main.stretching_moveout_resamp' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sushift.su.main.stretching_moveout_resamp' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sushift.su.main.stretching_moveout_resamp' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sustack.su.main.stacking' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sustack.su.main.stacking' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sustkvel.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sustkvel.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sustkvel_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sustkvel_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutaupnmo.su.main.stretching_moveout_resamp' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutaupnmo.su.main.stretching_moveout_resamp' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutaupnmo_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutaupnmo_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutihaledmo.su.main.dip_moveout' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutihaledmo.su.main.dip_moveout' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutihaledmo_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutihaledmo_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutivel.su.main.velocity_analysis' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutivel.su.main.velocity_analysis' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutivel_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutivel_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutsq.su.main.stretching_moveout_resamp' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutsq.su.main.stretching_moveout_resamp' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutsq_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/sutsq_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suttoz.su.main.stretching_moveout_resamp' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suttoz.su.main.stretching_moveout_resamp' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suttoz_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suttoz_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvel2df.su.main.velocity_analysis' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvel2df.su.main.velocity_analysis' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvel2df_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvel2df_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan.su.main.velocity_analysis' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan.su.main.velocity_analysis' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_nccs.su.main.velocity_analysis' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_nccs.su.main.velocity_analysis' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_nccs_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_nccs_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_nsel.su.main.velocity_analysis' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_nsel.su.main.velocity_analysis' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_nsel_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_nsel_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_uccs.su.main.velocity_analysis' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_uccs.su.main.velocity_analysis' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_usel.su.main.velocity_analysis' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suvelan_usel.su.main.velocity_analysis' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suztot.su.main.stretching_moveout_resamp' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suztot.su.main.stretching_moveout_resamp' \
	  'lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suztot_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/NMO_Vel_Stk/suztot_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/ctrlstrip.cwp.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/ctrlstrip.cwp.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/dt1tosu.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/dt1tosu.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/seg2segy.ThirdParty' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/seg2segy.ThirdParty' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/segbread.Sfio.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/segbread.Sfio.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/segdread.Sfio.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/segdread.Sfio.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/segyclean.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/segyclean.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/segyhdrs.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/segyhdrs.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/segyhdrs_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/segyhdrs_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/segyread.c.hold.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/segyread.c.hold.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/segyread.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/segyread.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/segyread_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/segyread_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/segyscan.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/segyscan.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/segywrite.c.hold.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/segywrite.c.hold.su.main.data_conversion' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/segywrite.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/segywrite.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/segywrite_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/segywrite_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/suoldtonew.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/suoldtonew.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/supack1.su.main.data_compression' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/supack1.su.main.data_compression' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/supack2.su.main.data_compression' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/supack2.su.main.data_compression' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/suswapbytes.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/suswapbytes.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/suunpack1.su.main.data_compression' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/suunpack1.su.main.data_compression' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/suunpack2.su.main.data_compression' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/suunpack2.su.main.data_compression' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/wpc1uncomp2.comp.dwpt.1d.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/wpc1uncomp2.comp.dwpt.1d.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/wpccompress.comp.dwpt.2d.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/wpccompress.comp.dwpt.2d.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/wpcuncompress.comp.dwpt.2d.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/wpcuncompress.comp.dwpt.2d.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/wptcomp.comp.dct.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/wptcomp.comp.dct.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/wptuncomp.comp.dct.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/wptuncomp.comp.dct.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/wtcomp.comp.dct.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/wtcomp.comp.dct.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/data/wtuncomp.comp.dct.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/data/wtuncomp.comp.dct.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/datum/sudatumk2dr.su.main.datuming' 'blib/lib/App/SeismicUnixGui/developer/Stripped/datum/sudatumk2dr.su.main.datuming' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/datum/sudatumk2ds.su.main.datuming' 'blib/lib/App/SeismicUnixGui/developer/Stripped/datum/sudatumk2ds.su.main.datuming' \
	  'lib/App/SeismicUnixGui/developer/Stripped/datum/sukdmdcr.su.main.datuming' 'blib/lib/App/SeismicUnixGui/developer/Stripped/datum/sukdmdcr.su.main.datuming' \
	  'lib/App/SeismicUnixGui/developer/Stripped/datum/sukdmdcs.su.main.datuming' 'blib/lib/App/SeismicUnixGui/developer/Stripped/datum/sukdmdcs.su.main.datuming' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/subfilt.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/subfilt.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/succfilt.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/succfilt.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sucddecon.su.main.decon_shaping' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sucddecon.su.main.decon_shaping' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sudipfilt.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sudipfilt.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sueipofi.su.main.multicomponent' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sueipofi.su.main.multicomponent' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sufilter.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sufilter.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sufrac.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sufrac.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sufwatrim.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sufwatrim.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sufxdecon.su.main.decon_shaping' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sufxdecon.su.main.decon_shaping' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sugroll.su.main.noise' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sugroll.su.main.noise' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sugroll_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sugroll_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/suk1k2filter.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/suk1k2filter.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sukfilter.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sukfilter.su.main.filters' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sukfrac.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sukfrac.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sulfaf.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sulfaf.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sumedian.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sumedian.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/supef.su.main.decon_shaping' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/supef.su.main.decon_shaping' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/suphase.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/suphase.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/suphidecon.su.main.decon_shaping' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/suphidecon.su.main.decon_shaping' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/supofilt.su.main.multicomponent' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/supofilt.su.main.multicomponent' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/supolar.su.main.multicomponent' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/supolar.su.main.multicomponent' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/susmgauss2.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/susmgauss2.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/filter/sutvband.su.main.filters' 'blib/lib/App/SeismicUnixGui/developer/Stripped/filter/sutvband.su.main.filters' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/segyhdrmod.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/segyhdrmod.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/setbhed.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/setbhed.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/su3dchart.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/su3dchart.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suabshw.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suabshw.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suaddhead.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suaddhead.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suaddstatics.su.main.statics' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suaddstatics.su.main.statics' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suahw.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suahw.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suascii.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suascii.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suazimuth.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suazimuth.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sucdpbin.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sucdpbin.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suchart.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suchart.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suchw.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suchw.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sucliphead.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sucliphead.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sucountkey.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sucountkey.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sudumptrace.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sudumptrace.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suedit.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suedit.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sugethw.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sugethw.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suhtmath.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suhtmath.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sukeycount.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sukeycount.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sulcthw.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sulcthw.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sulhead.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sulhead.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/supaste.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/supaste.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/surandhw.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/surandhw.su.main.headers' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/surange.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/surange.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suresstat.su.main.statics' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suresstat.su.main.statics' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suresstat_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suresstat_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/susehw.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/susehw.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sushw.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sushw.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sustatic.su.main.statics' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sustatic.su.main.statics' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sustaticB.su.main.statics' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sustaticB.su.main.statics' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sustaticrrs.su.main.statics' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sustaticrrs.su.main.statics' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sustrip.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sustrip.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/sutrcount.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/sutrcount.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suutm.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suutm.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/suxedit.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/suxedit.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/swapbhed.su.main.data_conversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/swapbhed.su.main.data_conversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/header/zebc.cwp.lib' 'blib/lib/App/SeismicUnixGui/developer/Stripped/header/zebc.cwp.lib' \
	  'lib/App/SeismicUnixGui/developer/Stripped/inversion/suinvco3d.3D.Suinvco3d' 'blib/lib/App/SeismicUnixGui/developer/Stripped/inversion/suinvco3d.3D.Suinvco3d' \
	  'lib/App/SeismicUnixGui/developer/Stripped/inversion/suinvvxzco.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/inversion/suinvvxzco.su.main.migration_inversion' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/inversion/suinvzco3d.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/inversion/suinvzco3d.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sudatumfd.su.main.datuming' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sudatumfd.su.main.datuming' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sugazmig.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sugazmig.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sukdmig2d.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sukdmig2d.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sukdmig3d.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sukdmig3d.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sukdmig3d_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sukdmig3d_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/suktmig2d.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/suktmig2d.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigfd.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigfd.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigffd.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigffd.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumiggbzo.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumiggbzo.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumiggbzoan.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumiggbzoan.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigprefd.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigprefd.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigpreffd.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigpreffd.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigprepspi.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigprepspi.su.main.migration_inversion' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigpresp.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigpresp.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigps.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigps.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigps_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigps_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigpspi.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigpspi.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigpsti.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigpsti.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigsplit.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigsplit.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigtk.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigtk.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sumigtopo2d.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sumigtopo2d.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sustolt.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sustolt.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/migration/sutifowler.su.main.migration_inversion' 'blib/lib/App/SeismicUnixGui/developer/Stripped/migration/sutifowler.su.main.migration_inversion' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/CWPGrep.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/CWPGrep.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/argv.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/argv.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/copyright.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/copyright.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/cpall.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/cpall.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/cpusec.cwputils' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/cpusec.cwputils' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/cputime.cwputils' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/cputime.cwputils' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/cwpfind.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/cwpfind.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/dirtree.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/dirtree.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/downfort.cwp.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/downfort.cwp.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/fcat.cwp.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/fcat.cwp.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/filetype.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/filetype.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/gendocs.par.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/gendocs.par.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/isatty.cwp.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/isatty.cwp.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/lookpar.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/lookpar.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/maxdiff.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/maxdiff.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/maxints.cwp.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/maxints.cwp.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/merge2.psplot.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/merge2.psplot.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/merge4.psplot.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/merge4.psplot.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/newcase.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/newcase.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/overwrite.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/overwrite.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/pause.cwp.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/pause.cwp.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/precedence.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/precedence.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/recip.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/recip.su.shell' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/replace.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/replace.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/rmaxdiff.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/rmaxdiff.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/striptotxt.par.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/striptotxt.par.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suagc.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suagc.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suband.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suband.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sucmp.su.main.attributes_parameter_estimation' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sucmp.su.main.attributes_parameter_estimation' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sudiff.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sudiff.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sudoc.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sudoc.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suenv.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suenv.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sufind.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sufind.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sufind2.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sufind2.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sugendocs.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sugendocs.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suget.su.main.supromax' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suget.su.main.supromax' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sugetgthr.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sugetgthr.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sugprfb.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sugprfb.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suhelp.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suhelp.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sukeyword.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/sukeyword.su.shell' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suname.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suname.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suput.su.main.supromax' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/suput.su.main.supromax' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/t.cwp.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/t.cwp.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/this_year.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/this_year.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/time_now.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/time_now.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/todays_date.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/todays_date.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/unglitch.su.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/unglitch.su.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/updatedoc.par.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/updatedoc.par.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/updatedocall.par.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/updatedocall.par.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/updatehead.par.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/updatehead.par.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/upfort.cwp.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/upfort.cwp.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/usernames.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/usernames.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/varlist.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/varlist.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/wallsec.cwputils' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/wallsec.cwputils' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/walltime.cwputils' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/walltime.cwputils' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/weekday.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/weekday.cwp.shell' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/xrects.Xtcwp.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/xrects.Xtcwp.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/misc/bck/zap.cwp.shell' 'blib/lib/App/SeismicUnixGui/developer/Stripped/misc/bck/zap.cwp.shell' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/addrvl3d.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/addrvl3d.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/addrvl3d_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/addrvl3d_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/cellauto.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/cellauto.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/cellauto_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/cellauto_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/elacheck.Trielas.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/elacheck.Trielas.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/elamodel.Trielas.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/elamodel.Trielas.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/elaray.Trielas.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/elaray.Trielas.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/elasyn.Trielas.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/elasyn.Trielas.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/elatriuni.Trielas.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/elatriuni.Trielas.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/gbbeam.Trielas.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/gbbeam.Trielas.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/gbbeam.tri.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/gbbeam.tri.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/grm.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/grm.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/grm_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/grm_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/normray.tri.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/normray.tri.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/raydata.Trielas.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/raydata.Trielas.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/suaddevent.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/suaddevent.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/suaddnoise.su.main.noise' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/suaddnoise.su.main.noise' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sudgwaveform.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sudgwaveform.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/suea2df.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/suea2df.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sufctanismod.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sufctanismod.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sufdmod1.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sufdmod1.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sufdmod2.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sufdmod2.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sufdmod2_pml.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sufdmod2_pml.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sugoupillaud.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sugoupillaud.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sugoupillaudpo.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sugoupillaudpo.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/suimp2d.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/suimp2d.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/suimp3d.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/suimp3d.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/suimpedance.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/suimpedance.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sujitter.su.main.noise' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sujitter.su.main.noise' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sukdsyn2d.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sukdsyn2d.su.main.synthetics_waveforms_testpatterns' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sunhmospike.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sunhmospike.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sunull.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sunull.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/suplane.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/suplane.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/surandspike.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/surandspike.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/surandstat.su.main.statics' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/surandstat.su.main.statics' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/suremac2d.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/suremac2d.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/suremel2dan.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/suremel2dan.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/suspike.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/suspike.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/susyncz.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/susyncz.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/susynlv.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/susynlv.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/susynlvcw.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/susynlvcw.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/susynlvfti.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/susynlvfti.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/susynvxz.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/susynvxz.su.main.synthetics_waveforms_testpatterns' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/susynvxzcs.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/susynvxzcs.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sutetraray.tetra.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sutetraray.tetra.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/suvibro.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/suvibro.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/suwaveform.su.main.synthetics_waveforms_testpatterns' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/suwaveform.su.main.synthetics_waveforms_testpatterns' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/sxplot.xtri' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/sxplot.xtri' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/tetramod.tetra.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/tetramod.tetra.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/tri2uni.tri.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/tri2uni.tri.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/trimodel.tri.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/trimodel.tri.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/trip.Mesa.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/trip.Mesa.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/triray.tri.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/triray.tri.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/triseis.tri.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/triseis.tri.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/uni2tri.tri.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/uni2tri.tri.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/model/unif2.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/model/unif2.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/.FileHistory.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/.FileHistory.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/a2i.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/a2i.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/a2i_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/a2i_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/b2a.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/b2a.par.main' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/bhedtopar.su.main.headers' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/bhedtopar.su.main.headers' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/bhedtopar_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/bhedtopar_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/cshotplot.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/cshotplot.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/cshotplot_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/cshotplot_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/float2ibm.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/float2ibm.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/float2ibm_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/float2ibm_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/ftnstrip.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/ftnstrip.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/ftnstrip_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/ftnstrip_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/ftnunstrip.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/ftnunstrip.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/ftnunstrip_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/ftnunstrip_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/h2b.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/h2b.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/hti2stiff.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/hti2stiff.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/hudson.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/hudson.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/i2a.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/i2a.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/ibm2float.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/ibm2float.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/kaperture.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/kaperture.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/linrort.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/linrort.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/lorenz.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/lorenz.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/makevel.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/makevel.par.main' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/mkparfile.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/mkparfile.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/mrafxzwt.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/mrafxzwt.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/pdfhistogram.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/pdfhistogram.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/prplot.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/prplot.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/randvel3d.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/randvel3d.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/rayt2d.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/rayt2d.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/rayt2dan.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/rayt2dan.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/recast.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/recast.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/refRealAziHTI.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/refRealAziHTI.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/refRealVTI.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/refRealVTI.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/regrid3.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/regrid3.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/resamp.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/resamp.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/rossler.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/rossler.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/smooth2.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/smooth2.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/smooth3d.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/smooth3d.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/smoothint2.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/smoothint2.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/stiff2vel.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/stiff2vel.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/subset.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/subset.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/swapbytes.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/swapbytes.par.main' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/thom2hti.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/thom2hti.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/thom2stiff.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/thom2stiff.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/transp.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/transp.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/transp3d.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/transp3d.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/tvnmoqc.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/tvnmoqc.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/unif2aniso.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/unif2aniso.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/unif2ti2.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/unif2ti2.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/unisam.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/unisam.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/unisam2.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/unisam2.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/unisam2_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/unisam2_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/utmconv.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/utmconv.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/vel2stiff.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/vel2stiff.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/velconv.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/velconv.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/velpert.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/velpert.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/velpertan.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/velpertan.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/verhulst.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/verhulst.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/vtlvz.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/vtlvz.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/wkbj.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/wkbj.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/xy2z.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/xy2z.par.main' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/par/z2xyz.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/par/z2xyz.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/picking/sufbpickw.su.main.picking' 'blib/lib/App/SeismicUnixGui/developer/Stripped/picking/sufbpickw.su.main.picking' \
	  'lib/App/SeismicUnixGui/developer/Stripped/picking/sufnzero.su.main.picking' 'blib/lib/App/SeismicUnixGui/developer/Stripped/picking/sufnzero.su.main.picking' \
	  'lib/App/SeismicUnixGui/developer/Stripped/picking/supickamp.su.main.picking' 'blib/lib/App/SeismicUnixGui/developer/Stripped/picking/supickamp.su.main.picking' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/elaps.Trielas.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/elaps.Trielas.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/junk' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/junk' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/lcmap.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/lcmap.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/list' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/list' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/lprop.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/lprop.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psbbox.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psbbox.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pscontour.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pscontour.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pscube.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pscube.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pscubecontour.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pscubecontour.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psepsi.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psepsi.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psgraph.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psgraph.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psimage.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psimage.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pslabel.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pslabel.psplot.main' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psmanager.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psmanager.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psmerge.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psmerge.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psmovie.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/psmovie.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pswigb.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pswigb.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pswigp.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/pswigp.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/scmap.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/scmap.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/spsplot.tri.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/spsplot.tri.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supscontour.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supscontour.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supscube.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supscube.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supscubecontour.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supscubecontour.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supsgraph.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supsgraph.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supsimage.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supsimage.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supsmax.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supsmax.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supsmovie.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supsmovie.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supswigb.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supswigb.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supswigp.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/supswigp.su.graphics.psplot' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxcontour.su.graphics.xplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxcontour.su.graphics.xplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxgraph.su.graphics.xplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxgraph.su.graphics.xplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suximage.su.graphics.xplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suximage.su.graphics.xplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxmax.su.graphics.xplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxmax.su.graphics.xplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxmovie.su.graphics.xplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxmovie.su.graphics.xplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxpicker.su.graphics.xplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxpicker.su.graphics.xplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxwigb.su.graphics.xplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/suxwigb.su.graphics.xplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/viewer3.Mesa.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/viewer3.Mesa.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xcontour.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xcontour.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xepsb.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xepsb.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xepsp.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xepsp.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xgraph.Xtcwp.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xgraph.Xtcwp.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/ximage.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/ximage.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xmovie.Xtcwp.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xmovie.Xtcwp.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xpicker.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xpicker.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xpsp.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xpsp.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xwigb.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/bck/xwigb.xplot.main' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/elaps.Trielas.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/elaps.Trielas.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/lcmap.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/lcmap.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/lprop.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/lprop.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/psbbox.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/psbbox.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/pscontour.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/pscontour.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/pscube.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/pscube.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/pscubecontour.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/pscubecontour.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/psepsi.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/psepsi.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/psgraph.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/psgraph.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/psimage.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/psimage.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/pslabel.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/pslabel.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/psmanager.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/psmanager.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/psmerge.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/psmerge.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/psmovie.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/psmovie.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/pswigb.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/pswigb.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/pswigp.psplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/pswigp.psplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/scmap.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/scmap.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/spsplot.tri.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/spsplot.tri.graphics.psplot' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/supscontour.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/supscontour.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/supscube.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/supscube.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/supscubecontour.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/supscubecontour.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/supsgraph.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/supsgraph.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/supsimage.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/supsimage.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/supsmax.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/supsmax.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/supsmovie.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/supsmovie.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/supswigb.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/supswigb.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/supswigp.su.graphics.psplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/supswigp.su.graphics.psplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/suxcontour.su.graphics.xplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/suxcontour.su.graphics.xplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/suxmax.su.graphics.xplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/suxmax.su.graphics.xplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/suxpicker.su.graphics.xplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/suxpicker.su.graphics.xplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/suxwigb.su.graphics.xplot' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/suxwigb.su.graphics.xplot' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/viewer3.Mesa.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/viewer3.Mesa.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/xcontour.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/xcontour.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/xcontour_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/xcontour_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/xepsb.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/xepsb.xplot.main' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/xepsp.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/xepsp.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/xpicker.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/xpicker.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/xpicker_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/xpicker_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/plot/xpsp.xplot.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/plot/xpsp.xplot.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sucentsamp.su.main.amplitudes' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sucentsamp.su.main.amplitudes' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sucommand.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sucommand.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sudipdivcor.su.main.amplitudes' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sudipdivcor.su.main.amplitudes' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sudivcor.su.main.amplitudes' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sudivcor.su.main.amplitudes' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suflip.su.main.operations' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suflip.su.main.operations' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sugain.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sugain.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sugain.su.main.amplitudes' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sugain.su.main.amplitudes' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sugausstaper.su.main.tapering' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sugausstaper.su.main.tapering' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sukill.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sukill.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sumute.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sumute.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sumute_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sumute_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sunan.su.main.amplitudes' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sunan.su.main.amplitudes' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/supad.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/supad.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/supad_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/supad_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/supermute.su.main.operations' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/supermute.su.main.operations' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/supgc.su.main.amplitudes' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/supgc.su.main.amplitudes' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suputgthr.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suputgthr.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suramp.su.main.tapering' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suramp.su.main.tapering' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suresstat.su.main.statics' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suresstat.su.main.statics' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sushape.su.main.decon_shaping' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sushape.su.main.decon_shaping' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/susort.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/susort.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/susorty.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/susorty.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/susplit.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/susplit.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sutxtaper.su.main.tapering' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/sutxtaper.su.main.tapering' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suvcat.su.main.operations' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suvcat.su.main.operations' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suvcat_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suvcat_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suvlength.su.main.operations' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suvlength.su.main.operations' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suwind.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suwind.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suwindpoly.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suwindpoly.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suzero.su.main.amplitudes' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shapeNcut/suzero.su.main.amplitudes' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shell/catsu.par' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shell/catsu.par' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shell/sugetgthr.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shell/sugetgthr.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/shell/suputgthr.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/shell/suputgthr.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/cpftrend.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/cpftrend.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/cpftrend_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/cpftrend_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/entropy.comp.dct.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/entropy.comp.dct.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/farith.par.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/farith.par.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/farith_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/farith_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/list' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/list' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suacor.su.main.convolution_correlation' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suacor.su.main.convolution_correlation' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suacorfrac.su.main.convolution_correlation' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suacorfrac.su.main.convolution_correlation' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/sualford.su.main.multicomponent' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/sualford.su.main.multicomponent' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suattributes.su.main.attributes_parameter_estimation' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suattributes.su.main.attributes_parameter_estimation' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suattributes_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suattributes_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suconv.su.main.convolution_correlation' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suconv.su.main.convolution_correlation' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/sufwmix.su.main.operations' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/sufwmix.su.main.operations' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suharlan.su.main.noise' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suharlan.su.main.noise' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suhistogram.su.main.attributes_parameter_estimation' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suhistogram.su.main.attributes_parameter_estimation' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suhrot.su.main.multicomponent' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suhrot.su.main.multicomponent' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suinterp.su.main.interp_extrap' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suinterp.su.main.interp_extrap' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suinterpfowler.su.main.interp_extrap' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suinterpfowler.su.main.interp_extrap' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/sultt.su.main.multicomponent' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/sultt.su.main.multicomponent' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumath.su.main.operations' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumath.su.main.operations' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumax.su.main.attributes_parameter_estimation' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumax.su.main.attributes_parameter_estimation' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumean.su.main.attributes_parameter_estimation' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumean.su.main.attributes_parameter_estimation' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumix.su.main.operations' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumix.su.main.operations' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumixgathers.su.main.windowing_sorting_muting' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/sumixgathers.su.main.windowing_sorting_muting' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/sunormalize.su.main.amplitudes' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/sunormalize.su.main.amplitudes' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suocext.su.main.interp_extrap' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suocext.su.main.interp_extrap' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suop.su.main.operations' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suop.su.main.operations' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suop2.su.main.operations' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suop2.su.main.operations' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suop_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suop_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suquantile.su.main.attributes_parameter_estimation' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suquantile.su.main.attributes_parameter_estimation' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/surefcon.su.main.convolution_correlation' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/surefcon.su.main.convolution_correlation' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/sutaper.su.main.tapering' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/sutaper.su.main.tapering' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suweight.su.main.amplitudes' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suweight.su.main.amplitudes' \
	  'lib/App/SeismicUnixGui/developer/Stripped/statsMath/suxcor.su.main.convolution_correlation' 'blib/lib/App/SeismicUnixGui/developer/Stripped/statsMath/suxcor.su.main.convolution_correlation' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/dctcomp.comp.dct.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/dctcomp.comp.dct.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/dctuncomp.comp.dct.main' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/dctuncomp.comp.dct.main' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suamp.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suamp.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suamp.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suamp.su.main.transforms' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suanalytic.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suanalytic.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suanalytic.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suanalytic.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/succepstrum.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/succepstrum.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/succwt.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/succwt.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/sucepstrum.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/sucepstrum.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suclogfft.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suclogfft.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suclogfft.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suclogfft.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/sucwt.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/sucwt.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/sucwt_changes.txt' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/sucwt_changes.txt' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/sufft.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/sufft.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/sufft.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/sufft.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/sugabor.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/sugabor.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suhilb.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suhilb.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suicepstrum.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suicepstrum.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suiclogfft.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suiclogfft.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suiclogfft.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suiclogfft.su.main.transforms' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suifft.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suifft.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suminphase.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suminphase.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suminphase.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suminphase.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suphasevel.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suphasevel.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suphasevel.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suphasevel.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suradon.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suradon.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suradon.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suradon.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suslowft.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suslowft.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suslowft.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suslowft.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suslowift.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suslowift.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suslowift.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suslowift.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suspecfk.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suspecfk.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suspecfk.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suspecfk.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suspecfx.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suspecfx.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suspecfx.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suspecfx.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suspeck1k2.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suspeck1k2.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suspeck1k2.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suspeck1k2.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/sutaup.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/sutaup.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suwfft.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suwfft.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suwfft.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suwfft.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suzerophase.config' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suzerophase.config' \
	  'lib/App/SeismicUnixGui/developer/Stripped/transform/suzerophase.su.main.transforms' 'blib/lib/App/SeismicUnixGui/developer/Stripped/transform/suzerophase.su.main.transforms' \
	  'lib/App/SeismicUnixGui/developer/Stripped/well/las2su.su.main.well_logs' 'blib/lib/App/SeismicUnixGui/developer/Stripped/well/las2su.su.main.well_logs' \
	  'lib/App/SeismicUnixGui/developer/Stripped/well/subackus.su.main.well_logs' 'blib/lib/App/SeismicUnixGui/developer/Stripped/well/subackus.su.main.well_logs' \
	  'lib/App/SeismicUnixGui/developer/Stripped/well/subackush.su.main.well_logs' 'blib/lib/App/SeismicUnixGui/developer/Stripped/well/subackush.su.main.well_logs' \
	  'lib/App/SeismicUnixGui/developer/Stripped/well/sugassman.main.well_logs' 'blib/lib/App/SeismicUnixGui/developer/Stripped/well/sugassman.main.well_logs' \
	  'lib/App/SeismicUnixGui/developer/Stripped/well/sulprime.su.main.well_logs' 'blib/lib/App/SeismicUnixGui/developer/Stripped/well/sulprime.su.main.well_logs' \
	  'lib/App/SeismicUnixGui/developer/Stripped/well/suwellrf.su.main.well_logs' 'blib/lib/App/SeismicUnixGui/developer/Stripped/well/suwellrf.su.main.well_logs' \
	  'lib/App/SeismicUnixGui/developer/archive/pod/Dialog.pod' 'blib/lib/App/SeismicUnixGui/developer/archive/pod/Dialog.pod' \
	  'lib/App/SeismicUnixGui/developer/archive/pod/perl5004delta.pod' 'blib/lib/App/SeismicUnixGui/developer/archive/pod/perl5004delta.pod' \
	  'lib/App/SeismicUnixGui/developer/archive/studio/test_file_read.pl' 'blib/lib/App/SeismicUnixGui/developer/archive/studio/test_file_read.pl' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/README' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/README' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/bck/perltidy.config' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/bck/perltidy.config' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_all.sh' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_all.sh' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_big_streams.sh' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_big_streams.sh' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_configs.sh' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_configs.sh' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_geopsy.sh' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_geopsy.sh' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_gmt.sh' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_gmt.sh' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_main.sh' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_main.sh' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_messages.sh' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_messages.sh' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_misc.sh' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_misc.sh' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_specs.sh' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_specs.sh' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_sqlite.sh' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_sqlite.sh' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_sunix.sh' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_sunix.sh' \
	  'lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_unix.sh' 'blib/lib/App/SeismicUnixGui/developer/archive/tidy_perl/perltidy_unix.sh' \
	  'lib/App/SeismicUnixGui/developer/code/archive/change_a_line.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/change_a_line.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/convert2V07.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/convert2V07.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_clear.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_clear.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_declare.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_declare.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_encapsulated.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_encapsulated.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_header.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_header.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_instantiation.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_instantiation.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_pod.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_pod.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_subroutine.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_subroutine.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_tail.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/gmt/gmt_package_tail.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/immodpg/kill4mmodpg_development.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/immodpg/kill4mmodpg_development.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/insert_line_in_file.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/insert_line_in_file.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/insert_manylines2_in_file.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/insert_manylines2_in_file.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/insert_manylines3_in_file.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/insert_manylines3_in_file.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/insert_manylines_in_file.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/insert_manylines_in_file.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/insert_two_lines_in_file.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/insert_two_lines_in_file.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/plotting_project/L_su_plot.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/plotting_project/L_su_plot.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/plotting_project/PerlTk_plot.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/plotting_project/PerlTk_plot.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/plotting_project/l_suplot' 'blib/lib/App/SeismicUnixGui/developer/code/archive/plotting_project/l_suplot' \
	  'lib/App/SeismicUnixGui/developer/code/archive/search_directories.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/search_directories.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/.FileHistory.txt' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/.FileHistory.txt' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/create_evince_doc.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/create_evince_doc.pl' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/evince.config' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/evince.config' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/evince.par' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/evince.par' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/evince.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/evince.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/evince_doc.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/evince_doc.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/evince_doc2pm.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/evince_doc2pm.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/evince_package.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/evince_package.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/evince_spec.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/evince_spec.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/log.txt' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/log.txt' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/prog_doc2pm.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/prog_doc2pm.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/sudoc2pm.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/sudoc2pm.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/sudoc2pm_updates.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/sudoc2pm_updates.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/sunix_package.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/sunix_package.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/shell/update.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/shell/update.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/test_incompatibles.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/test_incompatibles.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/2.view_1_126_clean.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/2.view_1_126_clean.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/My_SeismicUnix.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/My_SeismicUnix.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/change_a_line.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/change_a_line.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/log.txt' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/log.txt' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/map.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/map.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_Exporter.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_Exporter.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_INC.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_INC.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_L_SU_project_selector.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_L_SU_project_selector.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_SeismicUnix.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_SeismicUnix.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_config_superflows.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_config_superflows.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_extends.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_extends.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_extends_v2.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_extends_v2.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_extends_v3.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_extends_v3.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_file.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_file.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_file_orig.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_file_orig.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_global_libs.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_global_libs.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_project_selector.pm' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_project_selector.pm' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_quotem.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_quotem.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_quotem1.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_quotem1.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_quotem2.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_quotem2.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_require.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_require.pl' \
	  'lib/App/SeismicUnixGui/developer/code/archive/tests/test_split.pl' 'blib/lib/App/SeismicUnixGui/developer/code/archive/tests/test_split.pl' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/code/sunix/README.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/README.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/change_a_line_everywhere.pl' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/change_a_line_everywhere.pl' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/convert2V08.pl' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/convert2V08.pl' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/copyNclean_sgy_up.pl' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/copyNclean_sgy_up.pl' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/nameNnumber.txt' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/nameNnumber.txt' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/prog_doc2pm.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/prog_doc2pm.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/replacelines.pl' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/replacelines.pl' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sudoc.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sudoc.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sudoc2pm_nameNnumber.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sudoc2pm_nameNnumber.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sudoc2pm_pt1.pl' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sudoc2pm_pt1.pl' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sudoc2pm_pt2.pl' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sudoc2pm_pt2.pl' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_Step.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_Step.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_clear.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_clear.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_declaration.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_declaration.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_encapsulated.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_encapsulated.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_header.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_header.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_instantiation.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_instantiation.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_note.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_note.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_pod.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_pod.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_pod_header.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_pod_header.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_subroutine.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_subroutine.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_tail.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_tail.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_use.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_package_use.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sunix_spec.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sunix_spec.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/sustkvel_changes.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/sustkvel_changes.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/update.pm' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/update.pm' \
	  'lib/App/SeismicUnixGui/developer/code/sunix/update_main_version_number.pl' 'blib/lib/App/SeismicUnixGui/developer/code/sunix/update_main_version_number.pl' \
	  'lib/App/SeismicUnixGui/doc/FAQ_SeismicUnixGui' 'blib/lib/App/SeismicUnixGui/doc/FAQ_SeismicUnixGui' \
	  'lib/App/SeismicUnixGui/doc/FAQ_immodpg' 'blib/lib/App/SeismicUnixGui/doc/FAQ_immodpg' \
	  'lib/App/SeismicUnixGui/doc/README_to_INSTALL' 'blib/lib/App/SeismicUnixGui/doc/README_to_INSTALL' \
	  'lib/App/SeismicUnixGui/doc/SeismicUnixGuiInstallationGuide0.87.2.pdf' 'blib/lib/App/SeismicUnixGui/doc/SeismicUnixGuiInstallationGuide0.87.2.pdf' \
	  'lib/App/SeismicUnixGui/doc/SeismicUnixGuiTutorial0.87.2.pdf' 'blib/lib/App/SeismicUnixGui/doc/SeismicUnixGuiTutorial0.87.2.pdf' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU Tutorial_0.3.6-1.pdf' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU Tutorial_0.3.6-1.pdf' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU Tutorial_0.3.9.1.docx' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU Tutorial_0.3.9.1.docx' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU Tutorial_0.3.9.1.pdf' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU Tutorial_0.3.9.1.pdf' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU Tutorial_0.4.0.1.pdf' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU Tutorial_0.4.0.1.pdf' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU Tutorial_0.5.0.pdf' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU Tutorial_0.5.0.pdf' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU_Installation Guide 0.3.9.1.docx' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU_Installation Guide 0.3.9.1.docx' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU_Installation Guide 0.3.9.1.pdf' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU_Installation Guide 0.3.9.1.pdf' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU_Installation Guide 0.4.0.0.docx' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU_Installation Guide 0.4.0.0.docx' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU_Installation Guide 0.4.0.1.docx' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU_Installation Guide 0.4.0.1.docx' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU_Installation Guide 0.4.0.2.pdf' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU_Installation Guide 0.4.0.2.pdf' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU_Installation Guide 0.4.5.0.pdf' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU_Installation Guide 0.4.5.0.pdf' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU_Installation and Developer Guide_0.3.7-1.pdf' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU_Installation and Developer Guide_0.3.7-1.pdf' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU_Installation_Guide_0.6.6.3.docx' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU_Installation_Guide_0.6.6.3.docx' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU_Installation_Guide_0.7.0.0.docx' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU_Installation_Guide_0.7.0.0.docx' \
	  'lib/App/SeismicUnixGui/doc/archive/L_SU_Installation_Guide_0.7.0.0.pdf' 'blib/lib/App/SeismicUnixGui/doc/archive/L_SU_Installation_Guide_0.7.0.0.pdf' \
	  'lib/App/SeismicUnixGui/doc/archive/Notes_V0' 'blib/lib/App/SeismicUnixGui/doc/archive/Notes_V0' \
	  'lib/App/SeismicUnixGui/doc/archive/Notes_V1' 'blib/lib/App/SeismicUnixGui/doc/archive/Notes_V1' \
	  'lib/App/SeismicUnixGui/doc/archive/README' 'blib/lib/App/SeismicUnixGui/doc/archive/README' \
	  'lib/App/SeismicUnixGui/doc/documentation_conversion/.FileHistory.txt' 'blib/lib/App/SeismicUnixGui/doc/documentation_conversion/.FileHistory.txt' \
	  'lib/App/SeismicUnixGui/doc/documentation_conversion/pod2htmd.tmp' 'blib/lib/App/SeismicUnixGui/doc/documentation_conversion/pod2htmd.tmp' \
	  'lib/App/SeismicUnixGui/doc/documentation_conversion/pod2rst.sh' 'blib/lib/App/SeismicUnixGui/doc/documentation_conversion/pod2rst.sh' \
	  'lib/App/SeismicUnixGui/doc/documentation_conversion/suop.html' 'blib/lib/App/SeismicUnixGui/doc/documentation_conversion/suop.html' \
	  'lib/App/SeismicUnixGui/doc/documentation_conversion/suop.markdown' 'blib/lib/App/SeismicUnixGui/doc/documentation_conversion/suop.markdown' \
	  'lib/App/SeismicUnixGui/doc/documentation_conversion/suop.pm' 'blib/lib/App/SeismicUnixGui/doc/documentation_conversion/suop.pm' \
	  'lib/App/SeismicUnixGui/doc/documentation_conversion/suop.rst' 'blib/lib/App/SeismicUnixGui/doc/documentation_conversion/suop.rst' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/doc/documentation_conversion/suop_2.rst' 'blib/lib/App/SeismicUnixGui/doc/documentation_conversion/suop_2.rst' \
	  'lib/App/SeismicUnixGui/fortran/.FileHistory.txt' 'blib/lib/App/SeismicUnixGui/fortran/.FileHistory.txt' \
	  'lib/App/SeismicUnixGui/fortran/Makefile' 'blib/lib/App/SeismicUnixGui/fortran/Makefile' \
	  'lib/App/SeismicUnixGui/fortran/archive/P2' 'blib/lib/App/SeismicUnixGui/fortran/archive/P2' \
	  'lib/App/SeismicUnixGui/fortran/archive/ar' 'blib/lib/App/SeismicUnixGui/fortran/archive/ar' \
	  'lib/App/SeismicUnixGui/fortran/archive/immodpg.out' 'blib/lib/App/SeismicUnixGui/fortran/archive/immodpg.out' \
	  'lib/App/SeismicUnixGui/fortran/archive/mmodpg.config' 'blib/lib/App/SeismicUnixGui/fortran/archive/mmodpg.config' \
	  'lib/App/SeismicUnixGui/fortran/archive/mmodpg.config_bck' 'blib/lib/App/SeismicUnixGui/fortran/archive/mmodpg.config_bck' \
	  'lib/App/SeismicUnixGui/fortran/archive/mmodpg_config_master' 'blib/lib/App/SeismicUnixGui/fortran/archive/mmodpg_config_master' \
	  'lib/App/SeismicUnixGui/fortran/archive/model1' 'blib/lib/App/SeismicUnixGui/fortran/archive/model1' \
	  'lib/App/SeismicUnixGui/fortran/archive/process_P.pl' 'blib/lib/App/SeismicUnixGui/fortran/archive/process_P.pl' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/bck/Makefile' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/bck/Makefile' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/bck/data1.dat' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/bck/data1.dat' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/bck/main.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/bck/main.f' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/bck/makefile' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/bck/makefile' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/bck/read.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/bck/read.f' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/bck/read_1col.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/bck/read_1col.f' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/bck/run.sh' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/bck/run.sh' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/bck/write_1col.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/bck/write_1col.f' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/data1.dat' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/data1.dat' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/denfvp.for' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/denfvp.for' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/main.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/main.f' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/fortran/archive/src/main_read_from_fifo.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/main_read_from_fifo.f' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/messa.for' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/messa.for' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/mmodpg.for' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/mmodpg.for' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/pgzoom.for' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/pgzoom.for' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/read_1col.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/read_1col.f' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/read_1col_int.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/read_1col_int.f' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/read_layer_file.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/read_layer_file.f' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/read_mmodpg_config.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/read_mmodpg_config.f' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/read_option_file.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/read_option_file.f' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/read_yes_no_file.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/read_yes_no_file.f' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/readmmod.for' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/readmmod.for' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/readpar.for' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/readpar.for' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/thi.for' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/thi.for' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/txgrd.for' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/txgrd.for' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/txpr.for' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/txpr.for' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/wrimod2.for' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/wrimod2.for' \
	  'lib/App/SeismicUnixGui/fortran/archive/src/write_1col.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/src/write_1col.f' \
	  'lib/App/SeismicUnixGui/fortran/archive/sw' 'blib/lib/App/SeismicUnixGui/fortran/archive/sw' \
	  'lib/App/SeismicUnixGui/fortran/archive/write_2fifo.pl' 'blib/lib/App/SeismicUnixGui/fortran/archive/write_2fifo.pl' \
	  'lib/App/SeismicUnixGui/fortran/archive/write_test.pl' 'blib/lib/App/SeismicUnixGui/fortran/archive/write_test.pl' \
	  'lib/App/SeismicUnixGui/fortran/archive/xtra_code/read.f' 'blib/lib/App/SeismicUnixGui/fortran/archive/xtra_code/read.f' \
	  'lib/App/SeismicUnixGui/fortran/bin/immodpg1.1' 'blib/lib/App/SeismicUnixGui/fortran/bin/immodpg1.1' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/fortran/bin/stdsleep' 'blib/lib/App/SeismicUnixGui/fortran/bin/stdsleep' \
	  'lib/App/SeismicUnixGui/fortran/obj/Project_config.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/Project_config.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/denfvp.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/denfvp.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/immodpg.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/immodpg.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/messa.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/messa.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/moveNzoom.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/moveNzoom.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/rdata.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/rdata.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/readVbotNtop_factor_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/readVbotNtop_factor_file.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/readVbot_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/readVbot_file.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/readVbot_upper_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/readVbot_upper_file.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/readVincrement_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/readVincrement_file.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/readVtop_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/readVtop_file.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/readVtop_lower_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/readVtop_lower_file.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/read_bin_data.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/read_bin_data.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/read_clip_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/read_clip_file.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/read_dataxy.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/read_dataxy.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/read_immodpg_config.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/read_immodpg_config.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/read_layer_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/read_layer_file.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/read_option_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/read_option_file.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/read_parmmod_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/read_parmmod_file.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/read_thickness_increment_m_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/read_thickness_increment_m_file.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/read_thickness_m_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/read_thickness_m_file.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/read_yes_no_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/read_yes_no_file.o' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/fortran/obj/readmmod.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/readmmod.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/readpar.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/readpar.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/stdsleep.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/stdsleep.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/thi.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/thi.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/txgrd.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/txgrd.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/txpr.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/txpr.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/wrimod2.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/wrimod2.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/write_model_file_text.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/write_model_file_text.o' \
	  'lib/App/SeismicUnixGui/fortran/obj/write_yes_no_file.o' 'blib/lib/App/SeismicUnixGui/fortran/obj/write_yes_no_file.o' \
	  'lib/App/SeismicUnixGui/fortran/pl/.mmodpg/change' 'blib/lib/App/SeismicUnixGui/fortran/pl/.mmodpg/change' \
	  'lib/App/SeismicUnixGui/fortran/pl/datammod' 'blib/lib/App/SeismicUnixGui/fortran/pl/datammod' \
	  'lib/App/SeismicUnixGui/fortran/pl/mmodpg.config' 'blib/lib/App/SeismicUnixGui/fortran/pl/mmodpg.config' \
	  'lib/App/SeismicUnixGui/fortran/pl/mmodpg.out' 'blib/lib/App/SeismicUnixGui/fortran/pl/mmodpg.out' \
	  'lib/App/SeismicUnixGui/fortran/pl/model1' 'blib/lib/App/SeismicUnixGui/fortran/pl/model1' \
	  'lib/App/SeismicUnixGui/fortran/pl/parmmod' 'blib/lib/App/SeismicUnixGui/fortran/pl/parmmod' \
	  'lib/App/SeismicUnixGui/fortran/posix.mod' 'blib/lib/App/SeismicUnixGui/fortran/posix.mod' \
	  'lib/App/SeismicUnixGui/fortran/run_me_only.sh' 'blib/lib/App/SeismicUnixGui/fortran/run_me_only.sh' \
	  'lib/App/SeismicUnixGui/fortran/src/Project_config.f' 'blib/lib/App/SeismicUnixGui/fortran/src/Project_config.f' \
	  'lib/App/SeismicUnixGui/fortran/src/archive/Makefile' 'blib/lib/App/SeismicUnixGui/fortran/src/archive/Makefile' \
	  'lib/App/SeismicUnixGui/fortran/src/archive/main.f' 'blib/lib/App/SeismicUnixGui/fortran/src/archive/main.f' \
	  'lib/App/SeismicUnixGui/fortran/src/archive/main_read_from_fifo.f' 'blib/lib/App/SeismicUnixGui/fortran/src/archive/main_read_from_fifo.f' \
	  'lib/App/SeismicUnixGui/fortran/src/archive/makefile' 'blib/lib/App/SeismicUnixGui/fortran/src/archive/makefile' \
	  'lib/App/SeismicUnixGui/fortran/src/archive/panNzoom.for' 'blib/lib/App/SeismicUnixGui/fortran/src/archive/panNzoom.for' \
	  'lib/App/SeismicUnixGui/fortran/src/archive/readVtop_lower_file_bck.f' 'blib/lib/App/SeismicUnixGui/fortran/src/archive/readVtop_lower_file_bck.f' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/fortran/src/archive/read_1col.f' 'blib/lib/App/SeismicUnixGui/fortran/src/archive/read_1col.f' \
	  'lib/App/SeismicUnixGui/fortran/src/archive/read_1col_int.f' 'blib/lib/App/SeismicUnixGui/fortran/src/archive/read_1col_int.f' \
	  'lib/App/SeismicUnixGui/fortran/src/archive/read_bin_data_bck2.f' 'blib/lib/App/SeismicUnixGui/fortran/src/archive/read_bin_data_bck2.f' \
	  'lib/App/SeismicUnixGui/fortran/src/archive/write_1col.f' 'blib/lib/App/SeismicUnixGui/fortran/src/archive/write_1col.f' \
	  'lib/App/SeismicUnixGui/fortran/src/archive/write_option_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/archive/write_option_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/denfvp.for' 'blib/lib/App/SeismicUnixGui/fortran/src/denfvp.for' \
	  'lib/App/SeismicUnixGui/fortran/src/immodpg.for' 'blib/lib/App/SeismicUnixGui/fortran/src/immodpg.for' \
	  'lib/App/SeismicUnixGui/fortran/src/messa.for' 'blib/lib/App/SeismicUnixGui/fortran/src/messa.for' \
	  'lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/mmodpg.for' 'blib/lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/mmodpg.for' \
	  'lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/mmodpg2.for' 'blib/lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/mmodpg2.for' \
	  'lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/ns_y_sn.su' 'blib/lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/ns_y_sn.su' \
	  'lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/ns_y_sn.xt' 'blib/lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/ns_y_sn.xt' \
	  'lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/pgplot.inc' 'blib/lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/pgplot.inc' \
	  'lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/pgpolyev.for' 'blib/lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/pgpolyev.for' \
	  'lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/vmodns_sn' 'blib/lib/App/SeismicUnixGui/fortran/src/mmodpg4L_SU_Aug27_20_emilio/vmodns_sn' \
	  'lib/App/SeismicUnixGui/fortran/src/moveNzoom.for' 'blib/lib/App/SeismicUnixGui/fortran/src/moveNzoom.for' \
	  'lib/App/SeismicUnixGui/fortran/src/pgzoom.for' 'blib/lib/App/SeismicUnixGui/fortran/src/pgzoom.for' \
	  'lib/App/SeismicUnixGui/fortran/src/rdata.for' 'blib/lib/App/SeismicUnixGui/fortran/src/rdata.for' \
	  'lib/App/SeismicUnixGui/fortran/src/readVbotNtop_factor_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/readVbotNtop_factor_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/readVbot_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/readVbot_file.f' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/fortran/src/readVbot_upper_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/readVbot_upper_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/readVincrement_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/readVincrement_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/readVtop_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/readVtop_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/readVtop_lower_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/readVtop_lower_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/read_bin_data.f' 'blib/lib/App/SeismicUnixGui/fortran/src/read_bin_data.f' \
	  'lib/App/SeismicUnixGui/fortran/src/read_clip_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/read_clip_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/read_dataxy.for' 'blib/lib/App/SeismicUnixGui/fortran/src/read_dataxy.for' \
	  'lib/App/SeismicUnixGui/fortran/src/read_immodpg_config.f' 'blib/lib/App/SeismicUnixGui/fortran/src/read_immodpg_config.f' \
	  'lib/App/SeismicUnixGui/fortran/src/read_layer_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/read_layer_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/read_option_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/read_option_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/read_panNzoom_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/read_panNzoom_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/read_parmmod_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/read_parmmod_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/read_thickness_increment_m_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/read_thickness_increment_m_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/read_thickness_m_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/read_thickness_m_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/read_yes_no_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/read_yes_no_file.f' \
	  'lib/App/SeismicUnixGui/fortran/src/readmmod.for' 'blib/lib/App/SeismicUnixGui/fortran/src/readmmod.for' \
	  'lib/App/SeismicUnixGui/fortran/src/readpar.for' 'blib/lib/App/SeismicUnixGui/fortran/src/readpar.for' \
	  'lib/App/SeismicUnixGui/fortran/src/stdsleep.f' 'blib/lib/App/SeismicUnixGui/fortran/src/stdsleep.f' \
	  'lib/App/SeismicUnixGui/fortran/src/thi.for' 'blib/lib/App/SeismicUnixGui/fortran/src/thi.for' \
	  'lib/App/SeismicUnixGui/fortran/src/txgrd.for' 'blib/lib/App/SeismicUnixGui/fortran/src/txgrd.for' \
	  'lib/App/SeismicUnixGui/fortran/src/txpr.for' 'blib/lib/App/SeismicUnixGui/fortran/src/txpr.for' \
	  'lib/App/SeismicUnixGui/fortran/src/wrimod2.for' 'blib/lib/App/SeismicUnixGui/fortran/src/wrimod2.for' \
	  'lib/App/SeismicUnixGui/fortran/src/write_model_file_text.f' 'blib/lib/App/SeismicUnixGui/fortran/src/write_model_file_text.f' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/fortran/src/write_yes_no_file.f' 'blib/lib/App/SeismicUnixGui/fortran/src/write_yes_no_file.f' \
	  'lib/App/SeismicUnixGui/geopsy/dinver.pm' 'blib/lib/App/SeismicUnixGui/geopsy/dinver.pm' \
	  'lib/App/SeismicUnixGui/geopsy/gpdcreport.pm' 'blib/lib/App/SeismicUnixGui/geopsy/gpdcreport.pm' \
	  'lib/App/SeismicUnixGui/geopsy/gphistogram.pm' 'blib/lib/App/SeismicUnixGui/geopsy/gphistogram.pm' \
	  'lib/App/SeismicUnixGui/geopsy/gpprofile.pm' 'blib/lib/App/SeismicUnixGui/geopsy/gpprofile.pm' \
	  'lib/App/SeismicUnixGui/geopsy/gpviewdcreport.pm' 'blib/lib/App/SeismicUnixGui/geopsy/gpviewdcreport.pm' \
	  'lib/App/SeismicUnixGui/images/cross.ppm' 'blib/lib/App/SeismicUnixGui/images/cross.ppm' \
	  'lib/App/SeismicUnixGui/images/cross.xpm' 'blib/lib/App/SeismicUnixGui/images/cross.xpm' \
	  'lib/App/SeismicUnixGui/images/file_item_down_arrow-mask.xbm' 'blib/lib/App/SeismicUnixGui/images/file_item_down_arrow-mask.xbm' \
	  'lib/App/SeismicUnixGui/images/file_item_down_arrow.xbm' 'blib/lib/App/SeismicUnixGui/images/file_item_down_arrow.xbm' \
	  'lib/App/SeismicUnixGui/images/file_item_down_arrow.xcf' 'blib/lib/App/SeismicUnixGui/images/file_item_down_arrow.xcf' \
	  'lib/App/SeismicUnixGui/images/file_item_up_arrow-mask.xbm' 'blib/lib/App/SeismicUnixGui/images/file_item_up_arrow-mask.xbm' \
	  'lib/App/SeismicUnixGui/images/file_item_up_arrow.xbm' 'blib/lib/App/SeismicUnixGui/images/file_item_up_arrow.xbm' \
	  'lib/App/SeismicUnixGui/images/file_item_up_arrow.xcf' 'blib/lib/App/SeismicUnixGui/images/file_item_up_arrow.xcf' \
	  'lib/App/SeismicUnixGui/images/file_item_up_arrow.xpm' 'blib/lib/App/SeismicUnixGui/images/file_item_up_arrow.xpm' \
	  'lib/App/SeismicUnixGui/images/minus.xbm' 'blib/lib/App/SeismicUnixGui/images/minus.xbm' \
	  'lib/App/SeismicUnixGui/images/minus.xcf' 'blib/lib/App/SeismicUnixGui/images/minus.xcf' \
	  'lib/App/SeismicUnixGui/images/minus.xpm' 'blib/lib/App/SeismicUnixGui/images/minus.xpm' \
	  'lib/App/SeismicUnixGui/images/working images/Screenshot from 2019-08-28 17-45-12.png' 'blib/lib/App/SeismicUnixGui/images/working images/Screenshot from 2019-08-28 17-45-12.png' \
	  'lib/App/SeismicUnixGui/images/working images/Untitled.xbm' 'blib/lib/App/SeismicUnixGui/images/working images/Untitled.xbm' \
	  'lib/App/SeismicUnixGui/images/working images/cross.ppm' 'blib/lib/App/SeismicUnixGui/images/working images/cross.ppm' \
	  'lib/App/SeismicUnixGui/images/working images/cross.svg' 'blib/lib/App/SeismicUnixGui/images/working images/cross.svg' \
	  'lib/App/SeismicUnixGui/images/working images/cross.xcf' 'blib/lib/App/SeismicUnixGui/images/working images/cross.xcf' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/images/working images/lightning-mask.xbm' 'blib/lib/App/SeismicUnixGui/images/working images/lightning-mask.xbm' \
	  'lib/App/SeismicUnixGui/images/working images/lightning.pbm' 'blib/lib/App/SeismicUnixGui/images/working images/lightning.pbm' \
	  'lib/App/SeismicUnixGui/images/working images/lightning.png' 'blib/lib/App/SeismicUnixGui/images/working images/lightning.png' \
	  'lib/App/SeismicUnixGui/images/working images/lightning.svg' 'blib/lib/App/SeismicUnixGui/images/working images/lightning.svg' \
	  'lib/App/SeismicUnixGui/images/working images/lightning.xbm' 'blib/lib/App/SeismicUnixGui/images/working images/lightning.xbm' \
	  'lib/App/SeismicUnixGui/images/working images/lightning.xcf' 'blib/lib/App/SeismicUnixGui/images/working images/lightning.xcf' \
	  'lib/App/SeismicUnixGui/images/working images/lightning.xpm' 'blib/lib/App/SeismicUnixGui/images/working images/lightning.xpm' \
	  'lib/App/SeismicUnixGui/messages/About.pm' 'blib/lib/App/SeismicUnixGui/messages/About.pm' \
	  'lib/App/SeismicUnixGui/messages/FileDialog_button_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/FileDialog_button_messages.pm' \
	  'lib/App/SeismicUnixGui/messages/FileDialog_close_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/FileDialog_close_messages.pm' \
	  'lib/App/SeismicUnixGui/messages/SuMessages.pm' 'blib/lib/App/SeismicUnixGui/messages/SuMessages.pm' \
	  'lib/App/SeismicUnixGui/messages/archive/About.pm_bck' 'blib/lib/App/SeismicUnixGui/messages/archive/About.pm_bck' \
	  'lib/App/SeismicUnixGui/messages/archive/help_button_messages.pm_bck' 'blib/lib/App/SeismicUnixGui/messages/archive/help_button_messages.pm_bck' \
	  'lib/App/SeismicUnixGui/messages/archive/help_button_messages_old.pm' 'blib/lib/App/SeismicUnixGui/messages/archive/help_button_messages_old.pm' \
	  'lib/App/SeismicUnixGui/messages/backup_project_selector_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/backup_project_selector_messages.pm' \
	  'lib/App/SeismicUnixGui/messages/color_listbox_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/color_listbox_messages.pm' \
	  'lib/App/SeismicUnixGui/messages/flows_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/flows_messages.pm' \
	  'lib/App/SeismicUnixGui/messages/help_button_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/help_button_messages.pm' \
	  'lib/App/SeismicUnixGui/messages/iPick_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/iPick_messages.pm' \
	  'lib/App/SeismicUnixGui/messages/immodpg_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/immodpg_messages.pm' \
	  'lib/App/SeismicUnixGui/messages/message_director.pm' 'blib/lib/App/SeismicUnixGui/messages/message_director.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/messages/notes.pl' 'blib/lib/App/SeismicUnixGui/messages/notes.pl' \
	  'lib/App/SeismicUnixGui/messages/null_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/null_messages.pm' \
	  'lib/App/SeismicUnixGui/messages/project_selector_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/project_selector_messages.pm' \
	  'lib/App/SeismicUnixGui/messages/run_button_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/run_button_messages.pm' \
	  'lib/App/SeismicUnixGui/messages/save_button_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/save_button_messages.pm' \
	  'lib/App/SeismicUnixGui/messages/superflow_messages.pm' 'blib/lib/App/SeismicUnixGui/messages/superflow_messages.pm' \
	  'lib/App/SeismicUnixGui/misc/L_SU.pm' 'blib/lib/App/SeismicUnixGui/misc/L_SU.pm' \
	  'lib/App/SeismicUnixGui/misc/L_SU_global_constants.pm' 'blib/lib/App/SeismicUnixGui/misc/L_SU_global_constants.pm' \
	  'lib/App/SeismicUnixGui/misc/L_SU_local_user_constants.pm' 'blib/lib/App/SeismicUnixGui/misc/L_SU_local_user_constants.pm' \
	  'lib/App/SeismicUnixGui/misc/L_SU_path.pm' 'blib/lib/App/SeismicUnixGui/misc/L_SU_path.pm' \
	  'lib/App/SeismicUnixGui/misc/Math.pm' 'blib/lib/App/SeismicUnixGui/misc/Math.pm' \
	  'lib/App/SeismicUnixGui/misc/PID.pm' 'blib/lib/App/SeismicUnixGui/misc/PID.pm' \
	  'lib/App/SeismicUnixGui/misc/Project_Variables.pm' 'blib/lib/App/SeismicUnixGui/misc/Project_Variables.pm' \
	  'lib/App/SeismicUnixGui/misc/SeismicUnix.pm' 'blib/lib/App/SeismicUnixGui/misc/SeismicUnix.pm' \
	  'lib/App/SeismicUnixGui/misc/a2su.pm' 'blib/lib/App/SeismicUnixGui/misc/a2su.pm' \
	  'lib/App/SeismicUnixGui/misc/algebra_by.pm' 'blib/lib/App/SeismicUnixGui/misc/algebra_by.pm' \
	  'lib/App/SeismicUnixGui/misc/archive/L_SU_global_constants.pm' 'blib/lib/App/SeismicUnixGui/misc/archive/L_SU_global_constants.pm' \
	  'lib/App/SeismicUnixGui/misc/archive/L_SU_global_constants.pm_bck' 'blib/lib/App/SeismicUnixGui/misc/archive/L_SU_global_constants.pm_bck' \
	  'lib/App/SeismicUnixGui/misc/archive/Point.pm' 'blib/lib/App/SeismicUnixGui/misc/archive/Point.pm' \
	  'lib/App/SeismicUnixGui/misc/archive/backup_project_selector.pm' 'blib/lib/App/SeismicUnixGui/misc/archive/backup_project_selector.pm' \
	  'lib/App/SeismicUnixGui/misc/archive/binding2.pm' 'blib/lib/App/SeismicUnixGui/misc/archive/binding2.pm' \
	  'lib/App/SeismicUnixGui/misc/archive/canvas_data.pm' 'blib/lib/App/SeismicUnixGui/misc/archive/canvas_data.pm' \
	  'lib/App/SeismicUnixGui/misc/archive/canvas_graph.pm' 'blib/lib/App/SeismicUnixGui/misc/archive/canvas_graph.pm' \
	  'lib/App/SeismicUnixGui/misc/archive/control.pm' 'blib/lib/App/SeismicUnixGui/misc/archive/control.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/misc/archive/pdl_su.pm' 'blib/lib/App/SeismicUnixGui/misc/archive/pdl_su.pm' \
	  'lib/App/SeismicUnixGui/misc/archive/segdread.pm' 'blib/lib/App/SeismicUnixGui/misc/archive/segdread.pm' \
	  'lib/App/SeismicUnixGui/misc/archive/t' 'blib/lib/App/SeismicUnixGui/misc/archive/t' \
	  'lib/App/SeismicUnixGui/misc/array.pm' 'blib/lib/App/SeismicUnixGui/misc/array.pm' \
	  'lib/App/SeismicUnixGui/misc/big_streams_param.pm' 'blib/lib/App/SeismicUnixGui/misc/big_streams_param.pm' \
	  'lib/App/SeismicUnixGui/misc/binding.pm' 'blib/lib/App/SeismicUnixGui/misc/binding.pm' \
	  'lib/App/SeismicUnixGui/misc/blue_flow.pm' 'blib/lib/App/SeismicUnixGui/misc/blue_flow.pm' \
	  'lib/App/SeismicUnixGui/misc/check_buttons.pm' 'blib/lib/App/SeismicUnixGui/misc/check_buttons.pm' \
	  'lib/App/SeismicUnixGui/misc/cmpcc.pm' 'blib/lib/App/SeismicUnixGui/misc/cmpcc.pm' \
	  'lib/App/SeismicUnixGui/misc/color_listbox.pm' 'blib/lib/App/SeismicUnixGui/misc/color_listbox.pm' \
	  'lib/App/SeismicUnixGui/misc/conditions4big_streams.pm' 'blib/lib/App/SeismicUnixGui/misc/conditions4big_streams.pm' \
	  'lib/App/SeismicUnixGui/misc/conditions4flows.pm' 'blib/lib/App/SeismicUnixGui/misc/conditions4flows.pm' \
	  'lib/App/SeismicUnixGui/misc/config_superflows.pm' 'blib/lib/App/SeismicUnixGui/misc/config_superflows.pm' \
	  'lib/App/SeismicUnixGui/misc/control.pm' 'blib/lib/App/SeismicUnixGui/misc/control.pm' \
	  'lib/App/SeismicUnixGui/misc/copyNclean_sgy_up.pl' 'blib/lib/App/SeismicUnixGui/misc/copyNclean_sgy_up.pl' \
	  'lib/App/SeismicUnixGui/misc/count.pm' 'blib/lib/App/SeismicUnixGui/misc/count.pm' \
	  'lib/App/SeismicUnixGui/misc/cps.pm' 'blib/lib/App/SeismicUnixGui/misc/cps.pm' \
	  'lib/App/SeismicUnixGui/misc/decisions.pm' 'blib/lib/App/SeismicUnixGui/misc/decisions.pm' \
	  'lib/App/SeismicUnixGui/misc/developer.pm' 'blib/lib/App/SeismicUnixGui/misc/developer.pm' \
	  'lib/App/SeismicUnixGui/misc/dirs.pm' 'blib/lib/App/SeismicUnixGui/misc/dirs.pm' \
	  'lib/App/SeismicUnixGui/misc/error.pm' 'blib/lib/App/SeismicUnixGui/misc/error.pm' \
	  'lib/App/SeismicUnixGui/misc/file_dialog.pm' 'blib/lib/App/SeismicUnixGui/misc/file_dialog.pm' \
	  'lib/App/SeismicUnixGui/misc/files_LSU.pm' 'blib/lib/App/SeismicUnixGui/misc/files_LSU.pm' \
	  'lib/App/SeismicUnixGui/misc/flow.pm' 'blib/lib/App/SeismicUnixGui/misc/flow.pm' \
	  'lib/App/SeismicUnixGui/misc/flow_widgets.pm' 'blib/lib/App/SeismicUnixGui/misc/flow_widgets.pm' \
	  'lib/App/SeismicUnixGui/misc/geometry_pack.pm' 'blib/lib/App/SeismicUnixGui/misc/geometry_pack.pm' \
	  'lib/App/SeismicUnixGui/misc/get_pod_run_flows.pm' 'blib/lib/App/SeismicUnixGui/misc/get_pod_run_flows.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/misc/green_flow.pm' 'blib/lib/App/SeismicUnixGui/misc/green_flow.pm' \
	  'lib/App/SeismicUnixGui/misc/grey_flow.pm' 'blib/lib/App/SeismicUnixGui/misc/grey_flow.pm' \
	  'lib/App/SeismicUnixGui/misc/gui_history.pm' 'blib/lib/App/SeismicUnixGui/misc/gui_history.pm' \
	  'lib/App/SeismicUnixGui/misc/help.pm' 'blib/lib/App/SeismicUnixGui/misc/help.pm' \
	  'lib/App/SeismicUnixGui/misc/iFile.pm' 'blib/lib/App/SeismicUnixGui/misc/iFile.pm' \
	  'lib/App/SeismicUnixGui/misc/junk' 'blib/lib/App/SeismicUnixGui/misc/junk' \
	  'lib/App/SeismicUnixGui/misc/label_boxes.pm' 'blib/lib/App/SeismicUnixGui/misc/label_boxes.pm' \
	  'lib/App/SeismicUnixGui/misc/manage_dirs_by.pm' 'blib/lib/App/SeismicUnixGui/misc/manage_dirs_by.pm' \
	  'lib/App/SeismicUnixGui/misc/manage_files_by.pm' 'blib/lib/App/SeismicUnixGui/misc/manage_files_by.pm' \
	  'lib/App/SeismicUnixGui/misc/manage_files_by2.pm' 'blib/lib/App/SeismicUnixGui/misc/manage_files_by2.pm' \
	  'lib/App/SeismicUnixGui/misc/message.pm' 'blib/lib/App/SeismicUnixGui/misc/message.pm' \
	  'lib/App/SeismicUnixGui/misc/mkparfile.pm' 'blib/lib/App/SeismicUnixGui/misc/mkparfile.pm' \
	  'lib/App/SeismicUnixGui/misc/name.pm' 'blib/lib/App/SeismicUnixGui/misc/name.pm' \
	  'lib/App/SeismicUnixGui/misc/neutral_flow.pm' 'blib/lib/App/SeismicUnixGui/misc/neutral_flow.pm' \
	  'lib/App/SeismicUnixGui/misc/new_pkg.pm' 'blib/lib/App/SeismicUnixGui/misc/new_pkg.pm' \
	  'lib/App/SeismicUnixGui/misc/old_data.pm' 'blib/lib/App/SeismicUnixGui/misc/old_data.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_declaration_defaults.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_declaration_defaults.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_declare_data_in.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_declare_data_in.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_declare_data_out.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_declare_data_out.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_declare_pkg.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_declare_pkg.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_flows.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_flows.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_inbound.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_inbound.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_instantiation_defaults.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_instantiation_defaults.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_log_flows.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_log_flows.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_pod_header.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_pod_header.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_print_flows.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_print_flows.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_prog_params.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_prog_params.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/misc/oop_run_flows.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_run_flows.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_text.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_text.pm' \
	  'lib/App/SeismicUnixGui/misc/oop_use_pkg.pm' 'blib/lib/App/SeismicUnixGui/misc/oop_use_pkg.pm' \
	  'lib/App/SeismicUnixGui/misc/param.pm' 'blib/lib/App/SeismicUnixGui/misc/param.pm' \
	  'lib/App/SeismicUnixGui/misc/param_flow.pm' 'blib/lib/App/SeismicUnixGui/misc/param_flow.pm' \
	  'lib/App/SeismicUnixGui/misc/param_flow_blue.pm' 'blib/lib/App/SeismicUnixGui/misc/param_flow_blue.pm' \
	  'lib/App/SeismicUnixGui/misc/param_flow_green.pm' 'blib/lib/App/SeismicUnixGui/misc/param_flow_green.pm' \
	  'lib/App/SeismicUnixGui/misc/param_flow_grey.pm' 'blib/lib/App/SeismicUnixGui/misc/param_flow_grey.pm' \
	  'lib/App/SeismicUnixGui/misc/param_flow_neutral.pm' 'blib/lib/App/SeismicUnixGui/misc/param_flow_neutral.pm' \
	  'lib/App/SeismicUnixGui/misc/param_flow_pink.pm' 'blib/lib/App/SeismicUnixGui/misc/param_flow_pink.pm' \
	  'lib/App/SeismicUnixGui/misc/param_sunix.pm' 'blib/lib/App/SeismicUnixGui/misc/param_sunix.pm' \
	  'lib/App/SeismicUnixGui/misc/param_widgets.pm' 'blib/lib/App/SeismicUnixGui/misc/param_widgets.pm' \
	  'lib/App/SeismicUnixGui/misc/param_widgets4pre_built_streams.pm' 'blib/lib/App/SeismicUnixGui/misc/param_widgets4pre_built_streams.pm' \
	  'lib/App/SeismicUnixGui/misc/param_widgets_blue.pm' 'blib/lib/App/SeismicUnixGui/misc/param_widgets_blue.pm' \
	  'lib/App/SeismicUnixGui/misc/param_widgets_green.pm' 'blib/lib/App/SeismicUnixGui/misc/param_widgets_green.pm' \
	  'lib/App/SeismicUnixGui/misc/param_widgets_grey.pm' 'blib/lib/App/SeismicUnixGui/misc/param_widgets_grey.pm' \
	  'lib/App/SeismicUnixGui/misc/param_widgets_neutral.pm' 'blib/lib/App/SeismicUnixGui/misc/param_widgets_neutral.pm' \
	  'lib/App/SeismicUnixGui/misc/param_widgets_pink.pm' 'blib/lib/App/SeismicUnixGui/misc/param_widgets_pink.pm' \
	  'lib/App/SeismicUnixGui/misc/perl_declare.pm' 'blib/lib/App/SeismicUnixGui/misc/perl_declare.pm' \
	  'lib/App/SeismicUnixGui/misc/perl_flow.pm' 'blib/lib/App/SeismicUnixGui/misc/perl_flow.pm' \
	  'lib/App/SeismicUnixGui/misc/perl_header.pm' 'blib/lib/App/SeismicUnixGui/misc/perl_header.pm' \
	  'lib/App/SeismicUnixGui/misc/perl_inbound.pm' 'blib/lib/App/SeismicUnixGui/misc/perl_inbound.pm' \
	  'lib/App/SeismicUnixGui/misc/perl_instantiate.pm' 'blib/lib/App/SeismicUnixGui/misc/perl_instantiate.pm' \
	  'lib/App/SeismicUnixGui/misc/perl_use_pkg.pm' 'blib/lib/App/SeismicUnixGui/misc/perl_use_pkg.pm' \
	  'lib/App/SeismicUnixGui/misc/pink_flow.pm' 'blib/lib/App/SeismicUnixGui/misc/pink_flow.pm' \
	  'lib/App/SeismicUnixGui/misc/plot.pm' 'blib/lib/App/SeismicUnixGui/misc/plot.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/misc/pm_io.pm' 'blib/lib/App/SeismicUnixGui/misc/pm_io.pm' \
	  'lib/App/SeismicUnixGui/misc/pod_declare.pm' 'blib/lib/App/SeismicUnixGui/misc/pod_declare.pm' \
	  'lib/App/SeismicUnixGui/misc/pod_flows.pm' 'blib/lib/App/SeismicUnixGui/misc/pod_flows.pm' \
	  'lib/App/SeismicUnixGui/misc/pod_log_flows.pm' 'blib/lib/App/SeismicUnixGui/misc/pod_log_flows.pm' \
	  'lib/App/SeismicUnixGui/misc/pod_prog_param_setup.pm' 'blib/lib/App/SeismicUnixGui/misc/pod_prog_param_setup.pm' \
	  'lib/App/SeismicUnixGui/misc/pod_run_flows.pm' 'blib/lib/App/SeismicUnixGui/misc/pod_run_flows.pm' \
	  'lib/App/SeismicUnixGui/misc/premmod.pm' 'blib/lib/App/SeismicUnixGui/misc/premmod.pm' \
	  'lib/App/SeismicUnixGui/misc/program_name.pm' 'blib/lib/App/SeismicUnixGui/misc/program_name.pm' \
	  'lib/App/SeismicUnixGui/misc/project_selector.pm' 'blib/lib/App/SeismicUnixGui/misc/project_selector.pm' \
	  'lib/App/SeismicUnixGui/misc/read_psunix.pm' 'blib/lib/App/SeismicUnixGui/misc/read_psunix.pm' \
	  'lib/App/SeismicUnixGui/misc/readfiles.pm' 'blib/lib/App/SeismicUnixGui/misc/readfiles.pm' \
	  'lib/App/SeismicUnixGui/misc/redisplay.pm' 'blib/lib/App/SeismicUnixGui/misc/redisplay.pm' \
	  'lib/App/SeismicUnixGui/misc/run_button.pm' 'blib/lib/App/SeismicUnixGui/misc/run_button.pm' \
	  'lib/App/SeismicUnixGui/misc/save.pm' 'blib/lib/App/SeismicUnixGui/misc/save.pm' \
	  'lib/App/SeismicUnixGui/misc/save_button.pm' 'blib/lib/App/SeismicUnixGui/misc/save_button.pm' \
	  'lib/App/SeismicUnixGui/misc/save_button_messages.pm' 'blib/lib/App/SeismicUnixGui/misc/save_button_messages.pm' \
	  'lib/App/SeismicUnixGui/misc/seismics.pm' 'blib/lib/App/SeismicUnixGui/misc/seismics.pm' \
	  'lib/App/SeismicUnixGui/misc/smooth2.pm' 'blib/lib/App/SeismicUnixGui/misc/smooth2.pm' \
	  'lib/App/SeismicUnixGui/misc/su_param.pm' 'blib/lib/App/SeismicUnixGui/misc/su_param.pm' \
	  'lib/App/SeismicUnixGui/misc/su_select_waveform.pm' 'blib/lib/App/SeismicUnixGui/misc/su_select_waveform.pm' \
	  'lib/App/SeismicUnixGui/misc/su_spectral_analysis.pm' 'blib/lib/App/SeismicUnixGui/misc/su_spectral_analysis.pm' \
	  'lib/App/SeismicUnixGui/misc/su_xtract_waveform.pm' 'blib/lib/App/SeismicUnixGui/misc/su_xtract_waveform.pm' \
	  'lib/App/SeismicUnixGui/misc/sudata_in.pm' 'blib/lib/App/SeismicUnixGui/misc/sudata_in.pm' \
	  'lib/App/SeismicUnixGui/misc/sunix_pl.pm' 'blib/lib/App/SeismicUnixGui/misc/sunix_pl.pm' \
	  'lib/App/SeismicUnixGui/misc/superflows_config.pm' 'blib/lib/App/SeismicUnixGui/misc/superflows_config.pm' \
	  'lib/App/SeismicUnixGui/misc/system.pm' 'blib/lib/App/SeismicUnixGui/misc/system.pm' \
	  'lib/App/SeismicUnixGui/misc/tbd.pl' 'blib/lib/App/SeismicUnixGui/misc/tbd.pl' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/misc/unif2.pm' 'blib/lib/App/SeismicUnixGui/misc/unif2.pm' \
	  'lib/App/SeismicUnixGui/misc/use_pkg.pm' 'blib/lib/App/SeismicUnixGui/misc/use_pkg.pm' \
	  'lib/App/SeismicUnixGui/misc/value_boxes.pm' 'blib/lib/App/SeismicUnixGui/misc/value_boxes.pm' \
	  'lib/App/SeismicUnixGui/misc/whereami.pm' 'blib/lib/App/SeismicUnixGui/misc/whereami.pm' \
	  'lib/App/SeismicUnixGui/misc/whereami2.pm' 'blib/lib/App/SeismicUnixGui/misc/whereami2.pm' \
	  'lib/App/SeismicUnixGui/misc/wipe.pm' 'blib/lib/App/SeismicUnixGui/misc/wipe.pm' \
	  'lib/App/SeismicUnixGui/misc/write_LSU.pm' 'blib/lib/App/SeismicUnixGui/misc/write_LSU.pm' \
	  'lib/App/SeismicUnixGui/misc/writefiles.pm' 'blib/lib/App/SeismicUnixGui/misc/writefiles.pm' \
	  'lib/App/SeismicUnixGui/script/.FileHistory.txt' 'blib/lib/App/SeismicUnixGui/script/.FileHistory.txt' \
	  'lib/App/SeismicUnixGui/script/BackupProject' 'blib/lib/App/SeismicUnixGui/script/BackupProject' \
	  'lib/App/SeismicUnixGui/script/LICENSE' 'blib/lib/App/SeismicUnixGui/script/LICENSE' \
	  'lib/App/SeismicUnixGui/script/L_SU.pl' 'blib/lib/App/SeismicUnixGui/script/L_SU.pl' \
	  'lib/App/SeismicUnixGui/script/L_SU_project_selector.pl' 'blib/lib/App/SeismicUnixGui/script/L_SU_project_selector.pl' \
	  'lib/App/SeismicUnixGui/script/Project' 'blib/lib/App/SeismicUnixGui/script/Project' \
	  'lib/App/SeismicUnixGui/script/RestoreProject' 'blib/lib/App/SeismicUnixGui/script/RestoreProject' \
	  'lib/App/SeismicUnixGui/script/RestoreTutorial' 'blib/lib/App/SeismicUnixGui/script/RestoreTutorial' \
	  'lib/App/SeismicUnixGui/script/SeismicUnixGui' 'blib/lib/App/SeismicUnixGui/script/SeismicUnixGui' \
	  'lib/App/SeismicUnixGui/script/SetProject' 'blib/lib/App/SeismicUnixGui/script/SetProject' \
	  'lib/App/SeismicUnixGui/script/Sseg2su' 'blib/lib/App/SeismicUnixGui/script/Sseg2su' \
	  'lib/App/SeismicUnixGui/script/Sucat' 'blib/lib/App/SeismicUnixGui/script/Sucat' \
	  'lib/App/SeismicUnixGui/script/Sudipfilt' 'blib/lib/App/SeismicUnixGui/script/Sudipfilt' \
	  'lib/App/SeismicUnixGui/script/Synseis' 'blib/lib/App/SeismicUnixGui/script/Synseis' \
	  'lib/App/SeismicUnixGui/script/archive/L_SU.pl' 'blib/lib/App/SeismicUnixGui/script/archive/L_SU.pl' \
	  'lib/App/SeismicUnixGui/script/archive/L_SU.pl_bck' 'blib/lib/App/SeismicUnixGui/script/archive/L_SU.pl_bck' \
	  'lib/App/SeismicUnixGui/script/archive/set_env_variables.sh' 'blib/lib/App/SeismicUnixGui/script/archive/set_env_variables.sh' \
	  'lib/App/SeismicUnixGui/script/archive/tbd.pl' 'blib/lib/App/SeismicUnixGui/script/archive/tbd.pl' \
	  'lib/App/SeismicUnixGui/script/convert2V08' 'blib/lib/App/SeismicUnixGui/script/convert2V08' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/script/copyNclean_sgy_up' 'blib/lib/App/SeismicUnixGui/script/copyNclean_sgy_up' \
	  'lib/App/SeismicUnixGui/script/iBottomMute' 'blib/lib/App/SeismicUnixGui/script/iBottomMute' \
	  'lib/App/SeismicUnixGui/script/iPick' 'blib/lib/App/SeismicUnixGui/script/iPick' \
	  'lib/App/SeismicUnixGui/script/iSA' 'blib/lib/App/SeismicUnixGui/script/iSA' \
	  'lib/App/SeismicUnixGui/script/iSpectralAnalysis' 'blib/lib/App/SeismicUnixGui/script/iSpectralAnalysis' \
	  'lib/App/SeismicUnixGui/script/iTopMute' 'blib/lib/App/SeismicUnixGui/script/iTopMute' \
	  'lib/App/SeismicUnixGui/script/iVA' 'blib/lib/App/SeismicUnixGui/script/iVA' \
	  'lib/App/SeismicUnixGui/script/immodpg' 'blib/lib/App/SeismicUnixGui/script/immodpg' \
	  'lib/App/SeismicUnixGui/script/post_install_c_compile.pl' 'blib/lib/App/SeismicUnixGui/script/post_install_c_compile.pl' \
	  'lib/App/SeismicUnixGui/script/post_install_env.pl' 'blib/lib/App/SeismicUnixGui/script/post_install_env.pl' \
	  'lib/App/SeismicUnixGui/script/post_install_fortran_compile.pl' 'blib/lib/App/SeismicUnixGui/script/post_install_fortran_compile.pl' \
	  'lib/App/SeismicUnixGui/script/post_install_scripts.sh' 'blib/lib/App/SeismicUnixGui/script/post_install_scripts.sh' \
	  'lib/App/SeismicUnixGui/script/set_env_variables.sh' 'blib/lib/App/SeismicUnixGui/script/set_env_variables.sh' \
	  'lib/App/SeismicUnixGui/script/tbd' 'blib/lib/App/SeismicUnixGui/script/tbd' \
	  'lib/App/SeismicUnixGui/script/xk' 'blib/lib/App/SeismicUnixGui/script/xk' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/dzdv_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/dzdv_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sucvs4fowler_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sucvs4fowler_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudivstack_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudivstack_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmofk_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmofk_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmofkcw_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmofkcw_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmotivz_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmotivz_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmotx_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmotx_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmovz_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sudmovz_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suilog_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suilog_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suintvel_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suintvel_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sulog_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sulog_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sunmo_a_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sunmo_a_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sunmo_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sunmo_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/supws_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/supws_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/surecip_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/surecip_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sureduce_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sureduce_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/surelan_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/surelan_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/surelanan_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/surelanan_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suresamp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suresamp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sushift_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sushift_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sustack_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sustack_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sustkvel_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sustkvel_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sutaupnmo_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sutaupnmo_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sutihaledmo_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sutihaledmo_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sutivel_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sutivel_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sutsq_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/sutsq_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suttoz_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suttoz_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suvel2df_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suvel2df_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suvelan_nccs_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suvelan_nccs_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suvelan_nsel_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suvelan_nsel_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suvelan_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suvelan_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suztot_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/NMO_Vel_Stk/suztot_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/BackupProject_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/BackupProject_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/Project_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/Project_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/RestoreProject_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/RestoreProject_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/Sseg2su_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/Sseg2su_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/Sucat_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/Sucat_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/Sucat_specB.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/Sucat_specB.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/Sudipfilt_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/Sudipfilt_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/Synseis_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/Synseis_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/iBottomMute_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/iBottomMute_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/iPick_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/iPick_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/iPick_specB.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/iPick_specB.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/iPick_specC.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/iPick_specC.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/iPick_specD.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/iPick_specD.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/iSpectralAnalysis_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/iSpectralAnalysis_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/iTopMute_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/iTopMute_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/iVA_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/iVA_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/big_streams/immodpg_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/big_streams/immodpg_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/ctrlstrip_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/ctrlstrip_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/data_in_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/data_in_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/data/data_out_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/data_out_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/dt1tosu_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/dt1tosu_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/segbread_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/segbread_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/segdread_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/segdread_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/segyread_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/segyread_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/segyscan_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/segyscan_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/segywrite_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/segywrite_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/suoldtonew_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/suoldtonew_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/supack1_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/supack1_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/supack2_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/supack2_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/suswapbytes_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/suswapbytes_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/suunpack1_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/suunpack1_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/suunpack2_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/suunpack2_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/wpc1uncomp2_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/wpc1uncomp2_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/wpccompress_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/wpccompress_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/wpcuncompress_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/wpcuncompress_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/wptcomp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/wptcomp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/wptuncomp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/wptuncomp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/wtcomp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/wtcomp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/data/wtuncomp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/data/wtuncomp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/datum/sudatumk2dr_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/datum/sudatumk2dr_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/datum/sudatumk2ds_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/datum/sudatumk2ds_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/datum/sukdmdcr_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/datum/sukdmdcr_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/datum/sukdmdcs_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/datum/sukdmdcs_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/subfilt_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/subfilt_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/succfilt_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/succfilt_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/sucddecon_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/sucddecon_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/sudipfilt_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/sudipfilt_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/sueipofi_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/sueipofi_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/sufilter_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/sufilter_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/sufrac_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/sufrac_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/sufwatrim_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/sufwatrim_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/sufxdecon_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/sufxdecon_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/sugroll_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/sugroll_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/suk1k2filter_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/suk1k2filter_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/sukfilter_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/sukfilter_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/sulfaf_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/sulfaf_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/sumedian_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/sumedian_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/supef_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/supef_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/suphase_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/suphase_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/suphidecon_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/suphidecon_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/supofilt_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/supofilt_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/supolar_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/supolar_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/susmgauss2_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/susmgauss2_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/filter/sutvband_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/filter/sutvband_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/segyclean_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/segyclean_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/header/segyhdrmod_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/segyhdrmod_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/segyhdrs_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/segyhdrs_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/setbhed_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/setbhed_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/su3dchart_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/su3dchart_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suabshw_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suabshw_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suaddhead_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suaddhead_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suaddstatics_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suaddstatics_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suahw_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suahw_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suascii_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suascii_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suazimuth_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suazimuth_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sucdpbin_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sucdpbin_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suchart_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suchart_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suchw_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suchw_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sucliphead_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sucliphead_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sucountkey_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sucountkey_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sudumptrace_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sudumptrace_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suedit_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suedit_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sugethw_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sugethw_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suhtmath_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suhtmath_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sukeycount_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sukeycount_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sulcthw_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sulcthw_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sulhead_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sulhead_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/supaste_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/supaste_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/header/surandhw_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/surandhw_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/surange_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/surange_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suresstat_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suresstat_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/susehw_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/susehw_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sushw_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sushw_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sustaticB_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sustaticB_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sustatic_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sustatic_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sustaticrrs_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sustaticrrs_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sustrip_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sustrip_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/sutrcount_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/sutrcount_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suutm_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suutm_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/suxedit_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/suxedit_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/header/swapbhed_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/header/swapbhed_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/inversion/suinvco3d_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/inversion/suinvco3d_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/inversion/suinvvxzco_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/inversion/suinvvxzco_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/inversion/suinvzco3d_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/inversion/suinvzco3d_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sudatumfd_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sudatumfd_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sugazmig_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sugazmig_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sukdmig2d_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sukdmig2d_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sukdmig3d_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sukdmig3d_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/suktmig2d_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/suktmig2d_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumigfd_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumigfd_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/migration/sumigffd_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumigffd_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumiggbzo_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumiggbzo_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumiggbzoan_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumiggbzoan_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumigprefd_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumigprefd_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumigpreffd_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumigpreffd_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumigprepspi_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumigprepspi_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumigpresp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumigpresp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumigps_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumigps_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumigpspi_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumigpspi_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumigpsti_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumigpsti_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumigsplit_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumigsplit_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumigtk_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumigtk_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sumigtopo2d_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sumigtopo2d_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sustolt_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sustolt_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/migration/sutifowler_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/migration/sutifowler_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/addrvl3d_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/addrvl3d_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/cellauto_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/cellauto_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/elacheck_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/elacheck_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/elamodel_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/elamodel_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/elaray_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/elaray_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/elasyn_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/elasyn_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/elatriuni_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/elatriuni_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/model/gbbeam_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/gbbeam_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/grm_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/grm_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/normray_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/normray_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/raydata_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/raydata_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/suaddevent_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/suaddevent_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/suaddnoise_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/suaddnoise_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/sudgwaveform_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/sudgwaveform_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/suea2df_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/suea2df_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/sufctanismod_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/sufctanismod_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/sufdmod1_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/sufdmod1_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/sufdmod2_pml_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/sufdmod2_pml_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/sufdmod2_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/sufdmod2_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/sugoupillaud_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/sugoupillaud_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/sugoupillaudpo_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/sugoupillaudpo_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/suimp2d_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/suimp2d_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/suimp3d_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/suimp3d_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/suimpedance_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/suimpedance_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/sujitter_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/sujitter_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/sukdsyn2d_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/sukdsyn2d_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/sunull_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/sunull_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/suplane_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/suplane_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/surandspike_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/surandspike_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/surandstat_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/surandstat_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/model/suremac2d_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/suremac2d_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/suremel2dan_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/suremel2dan_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/suspike_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/suspike_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/susyncz_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/susyncz_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/susynlv_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/susynlv_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/susynlvcw_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/susynlvcw_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/susynlvfti_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/susynlvfti_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/susynvxz_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/susynvxz_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/model/susynvxzcs_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/model/susynvxzcs_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/a2b_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/a2b_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/a2i_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/a2i_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/b2a_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/b2a_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/bhedtopar_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/bhedtopar_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/cshotplot_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/cshotplot_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/float2ibm_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/float2ibm_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/ftnstrip_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/ftnstrip_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/ftnunstrip_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/ftnunstrip_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/makevel_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/makevel_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/mkparfile_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/mkparfile_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/transp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/transp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/unif2_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/unif2_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/unif2aniso_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/unif2aniso_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/unisam2_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/unisam2_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/par/unisam_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/unisam_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/par/vel2stiff_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/par/vel2stiff_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/elaps_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/elaps_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/lcmap_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/lcmap_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/lprop_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/lprop_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/psbbox_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/psbbox_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/pscontour_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/pscontour_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/pscube_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/pscube_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/pscubecontour_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/pscubecontour_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/psepsi_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/psepsi_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/psgraph_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/psgraph_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/psimage_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/psimage_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/pslabel_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/pslabel_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/psmanager_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/psmanager_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/psmerge_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/psmerge_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/psmovie_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/psmovie_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/pswigb_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/pswigb_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/pswigp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/pswigp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/scmap_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/scmap_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/spsplot_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/spsplot_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/supscontour_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/supscontour_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/supscube_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/supscube_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/supscubecontour_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/supscubecontour_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/supsgraph_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/supsgraph_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/supsimage_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/supsimage_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/plot/supsmax_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/supsmax_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/supsmovie_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/supsmovie_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/supswigb_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/supswigb_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/supswigp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/supswigp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/suxcontour_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/suxcontour_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/suxgraph_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/suxgraph_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/suximage_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/suximage_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/suxmax_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/suxmax_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/suxmovie_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/suxmovie_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/suxpicker_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/suxpicker_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/suxwigb_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/suxwigb_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/xcontour_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/xcontour_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/xgraph_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/xgraph_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/ximage_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/ximage_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/xmovie_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/xmovie_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/xpicker_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/xpicker_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/plot/xwigb_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/plot/xwigb_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shapeNcut/archive/sumute_spec_old.pm' 'blib/lib/App/SeismicUnixGui/specs/shapeNcut/archive/sumute_spec_old.pm' \
	  'lib/App/SeismicUnixGui/specs/shapeNcut/suflip_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shapeNcut/suflip_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shapeNcut/sugain_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shapeNcut/sugain_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shapeNcut/sugprfb_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shapeNcut/sugprfb_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shapeNcut/sukill_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shapeNcut/sukill_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shapeNcut/sumute_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shapeNcut/sumute_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/shapeNcut/supad_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shapeNcut/supad_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shapeNcut/suramp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shapeNcut/suramp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shapeNcut/susort_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shapeNcut/susort_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shapeNcut/susplit_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shapeNcut/susplit_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shapeNcut/suvcat_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shapeNcut/suvcat_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shapeNcut/suwind_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shapeNcut/suwind_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shell/cat_su_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shell/cat_su_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shell/evince_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shell/evince_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shell/sugetgthr_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shell/sugetgthr_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shell/suputgthr_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shell/suputgthr_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/shell/xk_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/shell/xk_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/cpftrend_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/cpftrend_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/entropy_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/entropy_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/farith_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/farith_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/suacor_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/suacor_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/suacorfrac_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/suacorfrac_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/sualford_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/sualford_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/suattributes_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/suattributes_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/suconv_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/suconv_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/sufwmix_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/sufwmix_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/suhistogram_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/suhistogram_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/suhrot_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/suhrot_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/statsMath/suinterp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/suinterp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/sumax_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/sumax_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/sumean_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/sumean_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/sumix_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/sumix_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/suop2_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/suop2_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/suop_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/suop_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/susort_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/susort_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/suxcor_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/suxcor_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/statsMath/suxmax_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/statsMath/suxmax_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/dctcomp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/dctcomp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/suamp_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/suamp_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/succepstrum_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/succepstrum_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/succwt_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/succwt_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/sucepstrum_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/sucepstrum_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/sucwt_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/sucwt_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/sufft_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/sufft_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/sugabor_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/sugabor_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/suicepstrum_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/suicepstrum_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/suifft_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/suifft_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/suminphase_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/suminphase_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/suphasevel_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/suphasevel_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/transform/suspecfx_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/suspecfx_spec.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/specs/transform/sutaup_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/transform/sutaup_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/well/las2su_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/well/las2su_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/well/subackus_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/well/subackus_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/well/subackush_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/well/subackush_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/well/sugassman_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/well/sugassman_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/well/sulprime_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/well/sulprime_spec.pm' \
	  'lib/App/SeismicUnixGui/specs/well/suwellrf_spec.pm' 'blib/lib/App/SeismicUnixGui/specs/well/suwellrf_spec.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/dzdv.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/dzdv.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sucvs4fowler.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sucvs4fowler.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudivstack.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudivstack.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmofk.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmofk.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmofkcw.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmofkcw.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmotivz.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmotivz.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmotx.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmotx.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmovz.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sudmovz.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suilog.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suilog.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suintvel.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suintvel.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sulog.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sulog.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sunmo.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sunmo.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sunmo_a.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sunmo_a.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/supws.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/supws.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/surecip.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/surecip.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sureduce.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sureduce.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/surelan.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/surelan.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/surelanan.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/surelanan.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suresamp.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suresamp.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sushift.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sushift.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sustack.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sustack.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sustkvel.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sustkvel.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sutaupnmo.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sutaupnmo.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sutihaledmo.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sutihaledmo.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sutivel.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sutivel.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sutsq.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/sutsq.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suttoz.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suttoz.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suvel2df.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suvel2df.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suvelan.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suvelan.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suvelan_nccs.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suvelan_nccs.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suvelan_nsel.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suvelan_nsel.pm' \
	  'lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suztot.pm' 'blib/lib/App/SeismicUnixGui/sunix/NMO_Vel_Stk/suztot.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/ctrlstrip.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/ctrlstrip.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/data_in.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/data_in.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/data_out.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/data_out.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/dt1tosu.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/dt1tosu.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/segbread.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/segbread.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/segdread.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/segdread.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/segyread.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/segyread.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/sunix/data/segyread_old.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/segyread_old.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/segyscan.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/segyscan.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/segywrite.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/segywrite.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/suoldtonew.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/suoldtonew.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/supack1.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/supack1.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/supack2.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/supack2.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/suswapbytes.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/suswapbytes.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/suunpack1.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/suunpack1.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/suunpack2.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/suunpack2.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/wpc1uncomp2.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/wpc1uncomp2.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/wpccompress.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/wpccompress.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/wpcuncompress.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/wpcuncompress.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/wptcomp.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/wptcomp.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/wptuncomp.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/wptuncomp.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/wtcomp.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/wtcomp.pm' \
	  'lib/App/SeismicUnixGui/sunix/data/wtuncomp.pm' 'blib/lib/App/SeismicUnixGui/sunix/data/wtuncomp.pm' \
	  'lib/App/SeismicUnixGui/sunix/datum/sudatumk2dr.pm' 'blib/lib/App/SeismicUnixGui/sunix/datum/sudatumk2dr.pm' \
	  'lib/App/SeismicUnixGui/sunix/datum/sudatumk2ds.pm' 'blib/lib/App/SeismicUnixGui/sunix/datum/sudatumk2ds.pm' \
	  'lib/App/SeismicUnixGui/sunix/datum/sukdmdcr.pm' 'blib/lib/App/SeismicUnixGui/sunix/datum/sukdmdcr.pm' \
	  'lib/App/SeismicUnixGui/sunix/datum/sukdmdcs.pm' 'blib/lib/App/SeismicUnixGui/sunix/datum/sukdmdcs.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/subfilt.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/subfilt.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/succfilt.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/succfilt.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/sucddecon.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/sucddecon.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/sudipfilt.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/sudipfilt.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/sueipofi.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/sueipofi.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/sunix/filter/sufilter.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/sufilter.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/sufrac.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/sufrac.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/sufwatrim.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/sufwatrim.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/sufxdecon.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/sufxdecon.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/sugroll.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/sugroll.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/suk1k2filter.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/suk1k2filter.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/sukfilter.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/sukfilter.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/sulfaf.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/sulfaf.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/sumedian.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/sumedian.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/supef.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/supef.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/suphase.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/suphase.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/suphidecon.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/suphidecon.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/supofilt.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/supofilt.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/supolar.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/supolar.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/susmgauss2.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/susmgauss2.pm' \
	  'lib/App/SeismicUnixGui/sunix/filter/sutvband.pm' 'blib/lib/App/SeismicUnixGui/sunix/filter/sutvband.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/header_values.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/header_values.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/segyclean.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/segyclean.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/segyhdrmod.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/segyhdrmod.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/segyhdrs.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/segyhdrs.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/segyhdrs_old.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/segyhdrs_old.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/setbhed.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/setbhed.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/su3dchart.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/su3dchart.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suabshw.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suabshw.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/sunix/header/suaddhead.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suaddhead.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suaddstatics.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suaddstatics.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suahw.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suahw.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suascii.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suascii.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suazimuth.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suazimuth.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sucdpbin.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sucdpbin.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suchart.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suchart.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suchw.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suchw.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sucliphead.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sucliphead.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sucountkey.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sucountkey.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sudumptrace.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sudumptrace.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suedit.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suedit.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sugethw.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sugethw.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suhtmath.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suhtmath.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sukeycount.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sukeycount.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sulcthw.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sulcthw.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sulhead.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sulhead.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/supaste.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/supaste.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/surandhw.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/surandhw.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/surange.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/surange.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suresstat.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suresstat.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suresstat_old.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suresstat_old.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/susehw.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/susehw.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sushw.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sushw.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sustatic.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sustatic.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/sunix/header/sustaticB.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sustaticB.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sustatic_old.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sustatic_old.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sustaticrrs.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sustaticrrs.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sustrip.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sustrip.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/sutrcount.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/sutrcount.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suutm.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suutm.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/suxedit.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/suxedit.pm' \
	  'lib/App/SeismicUnixGui/sunix/header/swapbhed.pm' 'blib/lib/App/SeismicUnixGui/sunix/header/swapbhed.pm' \
	  'lib/App/SeismicUnixGui/sunix/inversion/suinvco3d.pm' 'blib/lib/App/SeismicUnixGui/sunix/inversion/suinvco3d.pm' \
	  'lib/App/SeismicUnixGui/sunix/inversion/suinvvxzco.pm' 'blib/lib/App/SeismicUnixGui/sunix/inversion/suinvvxzco.pm' \
	  'lib/App/SeismicUnixGui/sunix/inversion/suinvzco3d.pm' 'blib/lib/App/SeismicUnixGui/sunix/inversion/suinvzco3d.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sudatumfd.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sudatumfd.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sugazmig.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sugazmig.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sukdmig2d.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sukdmig2d.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sukdmig3d.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sukdmig3d.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/suktmig2d.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/suktmig2d.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumigfd.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumigfd.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumigffd.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumigffd.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumiggbzo.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumiggbzo.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumiggbzoan.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumiggbzoan.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumigprefd.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumigprefd.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumigpreffd.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumigpreffd.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumigprepspi.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumigprepspi.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/sunix/migration/sumigpresp.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumigpresp.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumigps.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumigps.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumigpspi.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumigpspi.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumigpsti.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumigpsti.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumigsplit.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumigsplit.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumigtk.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumigtk.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sumigtopo2d.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sumigtopo2d.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sustolt.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sustolt.pm' \
	  'lib/App/SeismicUnixGui/sunix/migration/sutifowler.pm' 'blib/lib/App/SeismicUnixGui/sunix/migration/sutifowler.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/addrvl3d.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/addrvl3d.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/cellauto.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/cellauto.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/elacheck.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/elacheck.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/elamodel.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/elamodel.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/elaray.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/elaray.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/elasyn.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/elasyn.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/elatriuni.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/elatriuni.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/gbbeam.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/gbbeam.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/grm.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/grm.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/normray.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/normray.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/raydata.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/raydata.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/suaddevent.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/suaddevent.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/suaddnoise.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/suaddnoise.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/sudgwaveform.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/sudgwaveform.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/suea2df.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/suea2df.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/sunix/model/sufctanismod.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/sufctanismod.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/sufdmod1.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/sufdmod1.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/sufdmod2.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/sufdmod2.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/sufdmod2_pml.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/sufdmod2_pml.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/sugoupillaud.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/sugoupillaud.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/sugoupillaudpo.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/sugoupillaudpo.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/suimp2d.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/suimp2d.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/suimp3d.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/suimp3d.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/suimpedance.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/suimpedance.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/sujitter.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/sujitter.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/sukdsyn2d.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/sukdsyn2d.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/sunull.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/sunull.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/suplane.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/suplane.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/surandspike.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/surandspike.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/surandstat.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/surandstat.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/suremac2d.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/suremac2d.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/suremel2dan.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/suremel2dan.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/suspike.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/suspike.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/susyncz.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/susyncz.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/susynlv.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/susynlv.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/susynlvcw.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/susynlvcw.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/susynlvfti.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/susynlvfti.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/susynvxz.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/susynvxz.pm' \
	  'lib/App/SeismicUnixGui/sunix/model/susynvxzcs.pm' 'blib/lib/App/SeismicUnixGui/sunix/model/susynvxzcs.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/a2b.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/a2b.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/sunix/par/a2i.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/a2i.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/b2a.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/b2a.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/bhedtopar.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/bhedtopar.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/cshotplot.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/cshotplot.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/float2ibm.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/float2ibm.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/ftnstrip.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/ftnstrip.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/ftnunstrip.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/ftnunstrip.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/makevel.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/makevel.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/mkparfile.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/mkparfile.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/transp.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/transp.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/unif2.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/unif2.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/unif2aniso.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/unif2aniso.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/unisam.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/unisam.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/unisam2.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/unisam2.pm' \
	  'lib/App/SeismicUnixGui/sunix/par/vel2stiff.pm' 'blib/lib/App/SeismicUnixGui/sunix/par/vel2stiff.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/elaps.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/elaps.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/lcmap.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/lcmap.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/lprop.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/lprop.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/psbbox.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/psbbox.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/pscontour.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/pscontour.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/pscube.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/pscube.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/pscubecontour.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/pscubecontour.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/psepsi.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/psepsi.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/psgraph.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/psgraph.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/psimage.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/psimage.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/pslabel.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/pslabel.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/sunix/plot/psmanager.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/psmanager.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/psmerge.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/psmerge.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/psmovie.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/psmovie.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/pswigb.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/pswigb.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/pswigp.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/pswigp.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/scmap.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/scmap.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/spsplot.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/spsplot.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/supscontour.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/supscontour.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/supscube.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/supscube.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/supscubecontour.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/supscubecontour.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/supsgraph.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/supsgraph.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/supsimage.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/supsimage.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/supsmax.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/supsmax.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/supsmovie.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/supsmovie.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/supswigb.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/supswigb.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/supswigp.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/supswigp.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/suxcontour.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/suxcontour.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/suxgraph.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/suxgraph.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/suximage.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/suximage.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/suxmax.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/suxmax.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/suxmovie.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/suxmovie.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/suxpicker.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/suxpicker.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/suxwigb.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/suxwigb.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/todo/viewer3.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/todo/viewer3.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/xcontour.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/xcontour.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/xgraph.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/xgraph.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/sunix/plot/ximage.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/ximage.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/xmovie.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/xmovie.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/xpicker.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/xpicker.pm' \
	  'lib/App/SeismicUnixGui/sunix/plot/xwigb.pm' 'blib/lib/App/SeismicUnixGui/sunix/plot/xwigb.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/archive/sumute_old.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/archive/sumute_old.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/archive/suresamp.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/archive/suresamp.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/suflip.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/suflip.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/sugain.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/sugain.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/sugprfb.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/sugprfb.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/sukill.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/sukill.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/sumute.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/sumute.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/supad.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/supad.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/suramp.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/suramp.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/susort.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/susort.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/susplit.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/susplit.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/suvcat.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/suvcat.pm' \
	  'lib/App/SeismicUnixGui/sunix/shapeNcut/suwind.pm' 'blib/lib/App/SeismicUnixGui/sunix/shapeNcut/suwind.pm' \
	  'lib/App/SeismicUnixGui/sunix/shell/cat_su.pm' 'blib/lib/App/SeismicUnixGui/sunix/shell/cat_su.pm' \
	  'lib/App/SeismicUnixGui/sunix/shell/cat_txt.pm' 'blib/lib/App/SeismicUnixGui/sunix/shell/cat_txt.pm' \
	  'lib/App/SeismicUnixGui/sunix/shell/cp.pm' 'blib/lib/App/SeismicUnixGui/sunix/shell/cp.pm' \
	  'lib/App/SeismicUnixGui/sunix/shell/evince.pm' 'blib/lib/App/SeismicUnixGui/sunix/shell/evince.pm' \
	  'lib/App/SeismicUnixGui/sunix/shell/sucat.pm' 'blib/lib/App/SeismicUnixGui/sunix/shell/sucat.pm' \
	  'lib/App/SeismicUnixGui/sunix/shell/sugetgthr.pm' 'blib/lib/App/SeismicUnixGui/sunix/shell/sugetgthr.pm' \
	  'lib/App/SeismicUnixGui/sunix/shell/suputgthr.pm' 'blib/lib/App/SeismicUnixGui/sunix/shell/suputgthr.pm' \
	  'lib/App/SeismicUnixGui/sunix/shell/xk.pm' 'blib/lib/App/SeismicUnixGui/sunix/shell/xk.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/sunix/statsMath/cpftrend.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/cpftrend.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/entropy.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/entropy.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/farith.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/farith.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/suacor.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/suacor.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/suacorfrac.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/suacorfrac.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/sualford.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/sualford.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/suattributes.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/suattributes.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/suconv.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/suconv.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/sufwmix.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/sufwmix.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/suhistogram.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/suhistogram.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/suhrot.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/suhrot.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/suinterp.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/suinterp.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/sumax.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/sumax.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/sumean.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/sumean.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/sumix.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/sumix.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/suop.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/suop.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/suop2.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/suop2.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/suxcor.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/suxcor.pm' \
	  'lib/App/SeismicUnixGui/sunix/statsMath/suxmax.pm' 'blib/lib/App/SeismicUnixGui/sunix/statsMath/suxmax.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/dctcomp.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/dctcomp.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/suamp.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/suamp.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/succepstrum.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/succepstrum.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/succwt.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/succwt.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/sucepstrum.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/sucepstrum.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/SeismicUnixGui/sunix/transform/sucwt.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/sucwt.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/sufft.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/sufft.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/sugabor.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/sugabor.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/suicepstrum.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/suicepstrum.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/suifft.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/suifft.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/suminphase.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/suminphase.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/suphasevel.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/suphasevel.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/suspecfk.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/suspecfk.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/suspecfx.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/suspecfx.pm' \
	  'lib/App/SeismicUnixGui/sunix/transform/sutaup.pm' 'blib/lib/App/SeismicUnixGui/sunix/transform/sutaup.pm' \
	  'lib/App/SeismicUnixGui/sunix/well/las2su.pm' 'blib/lib/App/SeismicUnixGui/sunix/well/las2su.pm' \
	  'lib/App/SeismicUnixGui/sunix/well/subackus.pm' 'blib/lib/App/SeismicUnixGui/sunix/well/subackus.pm' \
	  'lib/App/SeismicUnixGui/sunix/well/subackush.pm' 'blib/lib/App/SeismicUnixGui/sunix/well/subackush.pm' \
	  'lib/App/SeismicUnixGui/sunix/well/sugassman.pm' 'blib/lib/App/SeismicUnixGui/sunix/well/sugassman.pm' \
	  'lib/App/SeismicUnixGui/sunix/well/sulprime.pm' 'blib/lib/App/SeismicUnixGui/sunix/well/sulprime.pm' \
	  'lib/App/SeismicUnixGui/sunix/well/suwellrf.pm' 'blib/lib/App/SeismicUnixGui/sunix/well/suwellrf.pm' \
	  'lib/App/archive/BackupProjectSelector.pl' 'blib/lib/App/archive/BackupProjectSelector.pl' \
	  'lib/App/archive/SeismicUnixGui.pm_bck' 'blib/lib/App/archive/SeismicUnixGui.pm_bck' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/dzdv.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/dzdv.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sucvs4fowler.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sucvs4fowler.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sudivstack.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sudivstack.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sudmofk.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sudmofk.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sudmofkcw.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sudmofkcw.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sudmotivz.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sudmotivz.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sudmotx.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sudmotx.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sudmovz.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sudmovz.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/suilog.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/suilog.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/suintvel.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/suintvel.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sulog.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sulog.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sunmo.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sunmo.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sunmo_a.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sunmo_a.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/supws.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/supws.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/surecip.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/surecip.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sureduce.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sureduce.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/surelan.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/surelan.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/surelanan.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/surelanan.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/suresamp.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/suresamp.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sushift.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sushift.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sustack.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sustack.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sustkvel.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sustkvel.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sutaupnmo.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sutaupnmo.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sutihaledmo.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sutihaledmo.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sutivel.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sutivel.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/sutsq.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/sutsq.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/suttoz.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/suttoz.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/suvel2df.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/suvel2df.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/suvelan.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/suvelan.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/suvelan_nccs.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/suvelan_nccs.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/suvelan_nsel.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/suvelan_nsel.pm' \
	  'lib/App/archive/sunix/NMO_Vel_Stk/suztot.pm' 'blib/lib/App/archive/sunix/NMO_Vel_Stk/suztot.pm' \
	  'lib/App/archive/sunix/data/ctrlstrip.pm' 'blib/lib/App/archive/sunix/data/ctrlstrip.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/archive/sunix/data/data_in.pm' 'blib/lib/App/archive/sunix/data/data_in.pm' \
	  'lib/App/archive/sunix/data/data_out.pm' 'blib/lib/App/archive/sunix/data/data_out.pm' \
	  'lib/App/archive/sunix/data/dt1tosu.pm' 'blib/lib/App/archive/sunix/data/dt1tosu.pm' \
	  'lib/App/archive/sunix/data/segbread.pm' 'blib/lib/App/archive/sunix/data/segbread.pm' \
	  'lib/App/archive/sunix/data/segdread.pm' 'blib/lib/App/archive/sunix/data/segdread.pm' \
	  'lib/App/archive/sunix/data/segyread.pm' 'blib/lib/App/archive/sunix/data/segyread.pm' \
	  'lib/App/archive/sunix/data/segyread_old.pm' 'blib/lib/App/archive/sunix/data/segyread_old.pm' \
	  'lib/App/archive/sunix/data/segyscan.pm' 'blib/lib/App/archive/sunix/data/segyscan.pm' \
	  'lib/App/archive/sunix/data/segywrite.pm' 'blib/lib/App/archive/sunix/data/segywrite.pm' \
	  'lib/App/archive/sunix/data/suoldtonew.pm' 'blib/lib/App/archive/sunix/data/suoldtonew.pm' \
	  'lib/App/archive/sunix/data/supack1.pm' 'blib/lib/App/archive/sunix/data/supack1.pm' \
	  'lib/App/archive/sunix/data/supack2.pm' 'blib/lib/App/archive/sunix/data/supack2.pm' \
	  'lib/App/archive/sunix/data/suswapbytes.pm' 'blib/lib/App/archive/sunix/data/suswapbytes.pm' \
	  'lib/App/archive/sunix/data/suunpack1.pm' 'blib/lib/App/archive/sunix/data/suunpack1.pm' \
	  'lib/App/archive/sunix/data/suunpack2.pm' 'blib/lib/App/archive/sunix/data/suunpack2.pm' \
	  'lib/App/archive/sunix/data/wpc1uncomp2.pm' 'blib/lib/App/archive/sunix/data/wpc1uncomp2.pm' \
	  'lib/App/archive/sunix/data/wpccompress.pm' 'blib/lib/App/archive/sunix/data/wpccompress.pm' \
	  'lib/App/archive/sunix/data/wpcuncompress.pm' 'blib/lib/App/archive/sunix/data/wpcuncompress.pm' \
	  'lib/App/archive/sunix/data/wptcomp.pm' 'blib/lib/App/archive/sunix/data/wptcomp.pm' \
	  'lib/App/archive/sunix/data/wptuncomp.pm' 'blib/lib/App/archive/sunix/data/wptuncomp.pm' \
	  'lib/App/archive/sunix/data/wtcomp.pm' 'blib/lib/App/archive/sunix/data/wtcomp.pm' \
	  'lib/App/archive/sunix/data/wtuncomp.pm' 'blib/lib/App/archive/sunix/data/wtuncomp.pm' \
	  'lib/App/archive/sunix/datum/sudatumk2dr.pm' 'blib/lib/App/archive/sunix/datum/sudatumk2dr.pm' \
	  'lib/App/archive/sunix/datum/sudatumk2ds.pm' 'blib/lib/App/archive/sunix/datum/sudatumk2ds.pm' \
	  'lib/App/archive/sunix/datum/sukdmdcr.pm' 'blib/lib/App/archive/sunix/datum/sukdmdcr.pm' \
	  'lib/App/archive/sunix/datum/sukdmdcs.pm' 'blib/lib/App/archive/sunix/datum/sukdmdcs.pm' \
	  'lib/App/archive/sunix/filter/subfilt.pm' 'blib/lib/App/archive/sunix/filter/subfilt.pm' \
	  'lib/App/archive/sunix/filter/succfilt.pm' 'blib/lib/App/archive/sunix/filter/succfilt.pm' \
	  'lib/App/archive/sunix/filter/sucddecon.pm' 'blib/lib/App/archive/sunix/filter/sucddecon.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/archive/sunix/filter/sudipfilt.pm' 'blib/lib/App/archive/sunix/filter/sudipfilt.pm' \
	  'lib/App/archive/sunix/filter/sueipofi.pm' 'blib/lib/App/archive/sunix/filter/sueipofi.pm' \
	  'lib/App/archive/sunix/filter/sufilter.pm' 'blib/lib/App/archive/sunix/filter/sufilter.pm' \
	  'lib/App/archive/sunix/filter/sufrac.pm' 'blib/lib/App/archive/sunix/filter/sufrac.pm' \
	  'lib/App/archive/sunix/filter/sufwatrim.pm' 'blib/lib/App/archive/sunix/filter/sufwatrim.pm' \
	  'lib/App/archive/sunix/filter/sufxdecon.pm' 'blib/lib/App/archive/sunix/filter/sufxdecon.pm' \
	  'lib/App/archive/sunix/filter/sugroll.pm' 'blib/lib/App/archive/sunix/filter/sugroll.pm' \
	  'lib/App/archive/sunix/filter/suk1k2filter.pm' 'blib/lib/App/archive/sunix/filter/suk1k2filter.pm' \
	  'lib/App/archive/sunix/filter/sukfilter.pm' 'blib/lib/App/archive/sunix/filter/sukfilter.pm' \
	  'lib/App/archive/sunix/filter/sulfaf.pm' 'blib/lib/App/archive/sunix/filter/sulfaf.pm' \
	  'lib/App/archive/sunix/filter/sumedian.pm' 'blib/lib/App/archive/sunix/filter/sumedian.pm' \
	  'lib/App/archive/sunix/filter/supef.pm' 'blib/lib/App/archive/sunix/filter/supef.pm' \
	  'lib/App/archive/sunix/filter/suphase.pm' 'blib/lib/App/archive/sunix/filter/suphase.pm' \
	  'lib/App/archive/sunix/filter/suphidecon.pm' 'blib/lib/App/archive/sunix/filter/suphidecon.pm' \
	  'lib/App/archive/sunix/filter/supofilt.pm' 'blib/lib/App/archive/sunix/filter/supofilt.pm' \
	  'lib/App/archive/sunix/filter/supolar.pm' 'blib/lib/App/archive/sunix/filter/supolar.pm' \
	  'lib/App/archive/sunix/filter/susmgauss2.pm' 'blib/lib/App/archive/sunix/filter/susmgauss2.pm' \
	  'lib/App/archive/sunix/filter/sutvband.pm' 'blib/lib/App/archive/sunix/filter/sutvband.pm' \
	  'lib/App/archive/sunix/header/header_values.pm' 'blib/lib/App/archive/sunix/header/header_values.pm' \
	  'lib/App/archive/sunix/header/segyclean.pm' 'blib/lib/App/archive/sunix/header/segyclean.pm' \
	  'lib/App/archive/sunix/header/segyhdrmod.pm' 'blib/lib/App/archive/sunix/header/segyhdrmod.pm' \
	  'lib/App/archive/sunix/header/segyhdrs.pm' 'blib/lib/App/archive/sunix/header/segyhdrs.pm' \
	  'lib/App/archive/sunix/header/segyhdrs_old.pm' 'blib/lib/App/archive/sunix/header/segyhdrs_old.pm' \
	  'lib/App/archive/sunix/header/setbhed.pm' 'blib/lib/App/archive/sunix/header/setbhed.pm' \
	  'lib/App/archive/sunix/header/su3dchart.pm' 'blib/lib/App/archive/sunix/header/su3dchart.pm' \
	  'lib/App/archive/sunix/header/suabshw.pm' 'blib/lib/App/archive/sunix/header/suabshw.pm' \
	  'lib/App/archive/sunix/header/suaddhead.pm' 'blib/lib/App/archive/sunix/header/suaddhead.pm' \
	  'lib/App/archive/sunix/header/suaddstatics.pm' 'blib/lib/App/archive/sunix/header/suaddstatics.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/archive/sunix/header/suahw.pm' 'blib/lib/App/archive/sunix/header/suahw.pm' \
	  'lib/App/archive/sunix/header/suascii.pm' 'blib/lib/App/archive/sunix/header/suascii.pm' \
	  'lib/App/archive/sunix/header/suazimuth.pm' 'blib/lib/App/archive/sunix/header/suazimuth.pm' \
	  'lib/App/archive/sunix/header/sucdpbin.pm' 'blib/lib/App/archive/sunix/header/sucdpbin.pm' \
	  'lib/App/archive/sunix/header/suchart.pm' 'blib/lib/App/archive/sunix/header/suchart.pm' \
	  'lib/App/archive/sunix/header/suchw.pm' 'blib/lib/App/archive/sunix/header/suchw.pm' \
	  'lib/App/archive/sunix/header/sucliphead.pm' 'blib/lib/App/archive/sunix/header/sucliphead.pm' \
	  'lib/App/archive/sunix/header/sucountkey.pm' 'blib/lib/App/archive/sunix/header/sucountkey.pm' \
	  'lib/App/archive/sunix/header/sucwt.pm' 'blib/lib/App/archive/sunix/header/sucwt.pm' \
	  'lib/App/archive/sunix/header/sudumptrace.pm' 'blib/lib/App/archive/sunix/header/sudumptrace.pm' \
	  'lib/App/archive/sunix/header/suedit.pm' 'blib/lib/App/archive/sunix/header/suedit.pm' \
	  'lib/App/archive/sunix/header/sugethw.pm' 'blib/lib/App/archive/sunix/header/sugethw.pm' \
	  'lib/App/archive/sunix/header/suhtmath.pm' 'blib/lib/App/archive/sunix/header/suhtmath.pm' \
	  'lib/App/archive/sunix/header/sukeycount.pm' 'blib/lib/App/archive/sunix/header/sukeycount.pm' \
	  'lib/App/archive/sunix/header/sulcthw.pm' 'blib/lib/App/archive/sunix/header/sulcthw.pm' \
	  'lib/App/archive/sunix/header/sulhead.pm' 'blib/lib/App/archive/sunix/header/sulhead.pm' \
	  'lib/App/archive/sunix/header/supaste.pm' 'blib/lib/App/archive/sunix/header/supaste.pm' \
	  'lib/App/archive/sunix/header/surandhw.pm' 'blib/lib/App/archive/sunix/header/surandhw.pm' \
	  'lib/App/archive/sunix/header/surange.pm' 'blib/lib/App/archive/sunix/header/surange.pm' \
	  'lib/App/archive/sunix/header/suresstat.pm' 'blib/lib/App/archive/sunix/header/suresstat.pm' \
	  'lib/App/archive/sunix/header/susehw.pm' 'blib/lib/App/archive/sunix/header/susehw.pm' \
	  'lib/App/archive/sunix/header/sushw.pm' 'blib/lib/App/archive/sunix/header/sushw.pm' \
	  'lib/App/archive/sunix/header/sustatic.pm' 'blib/lib/App/archive/sunix/header/sustatic.pm' \
	  'lib/App/archive/sunix/header/sustaticB.pm' 'blib/lib/App/archive/sunix/header/sustaticB.pm' \
	  'lib/App/archive/sunix/header/sustatic_old.pm' 'blib/lib/App/archive/sunix/header/sustatic_old.pm' \
	  'lib/App/archive/sunix/header/sustaticrrs.pm' 'blib/lib/App/archive/sunix/header/sustaticrrs.pm' \
	  'lib/App/archive/sunix/header/sustrip.pm' 'blib/lib/App/archive/sunix/header/sustrip.pm' \
	  'lib/App/archive/sunix/header/sutrcount.pm' 'blib/lib/App/archive/sunix/header/sutrcount.pm' \
	  'lib/App/archive/sunix/header/suutm.pm' 'blib/lib/App/archive/sunix/header/suutm.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/archive/sunix/header/suxedit.pm' 'blib/lib/App/archive/sunix/header/suxedit.pm' \
	  'lib/App/archive/sunix/header/swapbhed.pm' 'blib/lib/App/archive/sunix/header/swapbhed.pm' \
	  'lib/App/archive/sunix/inversion/suinvco3d.pm' 'blib/lib/App/archive/sunix/inversion/suinvco3d.pm' \
	  'lib/App/archive/sunix/inversion/suinvvxzco.pm' 'blib/lib/App/archive/sunix/inversion/suinvvxzco.pm' \
	  'lib/App/archive/sunix/inversion/suinvzco3d.pm' 'blib/lib/App/archive/sunix/inversion/suinvzco3d.pm' \
	  'lib/App/archive/sunix/migration/sudatumfd.pm' 'blib/lib/App/archive/sunix/migration/sudatumfd.pm' \
	  'lib/App/archive/sunix/migration/sugazmig.pm' 'blib/lib/App/archive/sunix/migration/sugazmig.pm' \
	  'lib/App/archive/sunix/migration/sukdmig2d.pm' 'blib/lib/App/archive/sunix/migration/sukdmig2d.pm' \
	  'lib/App/archive/sunix/migration/sukdmig3d.pm' 'blib/lib/App/archive/sunix/migration/sukdmig3d.pm' \
	  'lib/App/archive/sunix/migration/suktmig2d.pm' 'blib/lib/App/archive/sunix/migration/suktmig2d.pm' \
	  'lib/App/archive/sunix/migration/sumigfd.pm' 'blib/lib/App/archive/sunix/migration/sumigfd.pm' \
	  'lib/App/archive/sunix/migration/sumigffd.pm' 'blib/lib/App/archive/sunix/migration/sumigffd.pm' \
	  'lib/App/archive/sunix/migration/sumiggbzo.pm' 'blib/lib/App/archive/sunix/migration/sumiggbzo.pm' \
	  'lib/App/archive/sunix/migration/sumiggbzoan.pm' 'blib/lib/App/archive/sunix/migration/sumiggbzoan.pm' \
	  'lib/App/archive/sunix/migration/sumigprefd.pm' 'blib/lib/App/archive/sunix/migration/sumigprefd.pm' \
	  'lib/App/archive/sunix/migration/sumigpreffd.pm' 'blib/lib/App/archive/sunix/migration/sumigpreffd.pm' \
	  'lib/App/archive/sunix/migration/sumigprepspi.pm' 'blib/lib/App/archive/sunix/migration/sumigprepspi.pm' \
	  'lib/App/archive/sunix/migration/sumigpresp.pm' 'blib/lib/App/archive/sunix/migration/sumigpresp.pm' \
	  'lib/App/archive/sunix/migration/sumigps.pm' 'blib/lib/App/archive/sunix/migration/sumigps.pm' \
	  'lib/App/archive/sunix/migration/sumigpspi.pm' 'blib/lib/App/archive/sunix/migration/sumigpspi.pm' \
	  'lib/App/archive/sunix/migration/sumigpsti.pm' 'blib/lib/App/archive/sunix/migration/sumigpsti.pm' \
	  'lib/App/archive/sunix/migration/sumigsplit.pm' 'blib/lib/App/archive/sunix/migration/sumigsplit.pm' \
	  'lib/App/archive/sunix/migration/sumigtk.pm' 'blib/lib/App/archive/sunix/migration/sumigtk.pm' \
	  'lib/App/archive/sunix/migration/sumigtopo2d.pm' 'blib/lib/App/archive/sunix/migration/sumigtopo2d.pm' \
	  'lib/App/archive/sunix/migration/sustolt.pm' 'blib/lib/App/archive/sunix/migration/sustolt.pm' \
	  'lib/App/archive/sunix/migration/sutifowler.pm' 'blib/lib/App/archive/sunix/migration/sutifowler.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/archive/sunix/model/addrvl3d.pm' 'blib/lib/App/archive/sunix/model/addrvl3d.pm' \
	  'lib/App/archive/sunix/model/cellauto.pm' 'blib/lib/App/archive/sunix/model/cellauto.pm' \
	  'lib/App/archive/sunix/model/elacheck.pm' 'blib/lib/App/archive/sunix/model/elacheck.pm' \
	  'lib/App/archive/sunix/model/elamodel.pm' 'blib/lib/App/archive/sunix/model/elamodel.pm' \
	  'lib/App/archive/sunix/model/elaray.pm' 'blib/lib/App/archive/sunix/model/elaray.pm' \
	  'lib/App/archive/sunix/model/elasyn.pm' 'blib/lib/App/archive/sunix/model/elasyn.pm' \
	  'lib/App/archive/sunix/model/elatriuni.pm' 'blib/lib/App/archive/sunix/model/elatriuni.pm' \
	  'lib/App/archive/sunix/model/gbbeam.pm' 'blib/lib/App/archive/sunix/model/gbbeam.pm' \
	  'lib/App/archive/sunix/model/grm.pm' 'blib/lib/App/archive/sunix/model/grm.pm' \
	  'lib/App/archive/sunix/model/normray.pm' 'blib/lib/App/archive/sunix/model/normray.pm' \
	  'lib/App/archive/sunix/model/raydata.pm' 'blib/lib/App/archive/sunix/model/raydata.pm' \
	  'lib/App/archive/sunix/model/suaddevent.pm' 'blib/lib/App/archive/sunix/model/suaddevent.pm' \
	  'lib/App/archive/sunix/model/suaddnoise.pm' 'blib/lib/App/archive/sunix/model/suaddnoise.pm' \
	  'lib/App/archive/sunix/model/sudgwaveform.pm' 'blib/lib/App/archive/sunix/model/sudgwaveform.pm' \
	  'lib/App/archive/sunix/model/suea2df.pm' 'blib/lib/App/archive/sunix/model/suea2df.pm' \
	  'lib/App/archive/sunix/model/sufctanismod.pm' 'blib/lib/App/archive/sunix/model/sufctanismod.pm' \
	  'lib/App/archive/sunix/model/sufdmod1.pm' 'blib/lib/App/archive/sunix/model/sufdmod1.pm' \
	  'lib/App/archive/sunix/model/sufdmod2.pm' 'blib/lib/App/archive/sunix/model/sufdmod2.pm' \
	  'lib/App/archive/sunix/model/sufdmod2_pml.pm' 'blib/lib/App/archive/sunix/model/sufdmod2_pml.pm' \
	  'lib/App/archive/sunix/model/sugoupillaud.pm' 'blib/lib/App/archive/sunix/model/sugoupillaud.pm' \
	  'lib/App/archive/sunix/model/sugoupillaudpo.pm' 'blib/lib/App/archive/sunix/model/sugoupillaudpo.pm' \
	  'lib/App/archive/sunix/model/suimp2d.pm' 'blib/lib/App/archive/sunix/model/suimp2d.pm' \
	  'lib/App/archive/sunix/model/suimp3d.pm' 'blib/lib/App/archive/sunix/model/suimp3d.pm' \
	  'lib/App/archive/sunix/model/suimpedance.pm' 'blib/lib/App/archive/sunix/model/suimpedance.pm' \
	  'lib/App/archive/sunix/model/sujitter.pm' 'blib/lib/App/archive/sunix/model/sujitter.pm' \
	  'lib/App/archive/sunix/model/sukdsyn2d.pm' 'blib/lib/App/archive/sunix/model/sukdsyn2d.pm' \
	  'lib/App/archive/sunix/model/sunull.pm' 'blib/lib/App/archive/sunix/model/sunull.pm' \
	  'lib/App/archive/sunix/model/suplane.pm' 'blib/lib/App/archive/sunix/model/suplane.pm' \
	  'lib/App/archive/sunix/model/surandspike.pm' 'blib/lib/App/archive/sunix/model/surandspike.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/archive/sunix/model/surandstat.pm' 'blib/lib/App/archive/sunix/model/surandstat.pm' \
	  'lib/App/archive/sunix/model/suremac2d.pm' 'blib/lib/App/archive/sunix/model/suremac2d.pm' \
	  'lib/App/archive/sunix/model/suremel2dan.pm' 'blib/lib/App/archive/sunix/model/suremel2dan.pm' \
	  'lib/App/archive/sunix/model/suspike.pm' 'blib/lib/App/archive/sunix/model/suspike.pm' \
	  'lib/App/archive/sunix/model/susyncz.pm' 'blib/lib/App/archive/sunix/model/susyncz.pm' \
	  'lib/App/archive/sunix/model/susynlv.pm' 'blib/lib/App/archive/sunix/model/susynlv.pm' \
	  'lib/App/archive/sunix/model/susynlvcw.pm' 'blib/lib/App/archive/sunix/model/susynlvcw.pm' \
	  'lib/App/archive/sunix/model/susynlvfti.pm' 'blib/lib/App/archive/sunix/model/susynlvfti.pm' \
	  'lib/App/archive/sunix/model/susynvxz.pm' 'blib/lib/App/archive/sunix/model/susynvxz.pm' \
	  'lib/App/archive/sunix/model/susynvxzcs.pm' 'blib/lib/App/archive/sunix/model/susynvxzcs.pm' \
	  'lib/App/archive/sunix/par/a2b.pm' 'blib/lib/App/archive/sunix/par/a2b.pm' \
	  'lib/App/archive/sunix/par/a2i.pm' 'blib/lib/App/archive/sunix/par/a2i.pm' \
	  'lib/App/archive/sunix/par/b2a.pm' 'blib/lib/App/archive/sunix/par/b2a.pm' \
	  'lib/App/archive/sunix/par/bhedtopar.pm' 'blib/lib/App/archive/sunix/par/bhedtopar.pm' \
	  'lib/App/archive/sunix/par/cshotplot.pm' 'blib/lib/App/archive/sunix/par/cshotplot.pm' \
	  'lib/App/archive/sunix/par/float2ibm.pm' 'blib/lib/App/archive/sunix/par/float2ibm.pm' \
	  'lib/App/archive/sunix/par/ftnstrip.pm' 'blib/lib/App/archive/sunix/par/ftnstrip.pm' \
	  'lib/App/archive/sunix/par/ftnunstrip.pm' 'blib/lib/App/archive/sunix/par/ftnunstrip.pm' \
	  'lib/App/archive/sunix/par/makevel.pm' 'blib/lib/App/archive/sunix/par/makevel.pm' \
	  'lib/App/archive/sunix/par/mkparfile.pm' 'blib/lib/App/archive/sunix/par/mkparfile.pm' \
	  'lib/App/archive/sunix/par/transp.pm' 'blib/lib/App/archive/sunix/par/transp.pm' \
	  'lib/App/archive/sunix/par/unif2.pm' 'blib/lib/App/archive/sunix/par/unif2.pm' \
	  'lib/App/archive/sunix/par/unif2aniso.pm' 'blib/lib/App/archive/sunix/par/unif2aniso.pm' \
	  'lib/App/archive/sunix/par/unisam.pm' 'blib/lib/App/archive/sunix/par/unisam.pm' \
	  'lib/App/archive/sunix/par/unisam2.pm' 'blib/lib/App/archive/sunix/par/unisam2.pm' \
	  'lib/App/archive/sunix/par/vel2stiff.pm' 'blib/lib/App/archive/sunix/par/vel2stiff.pm' \
	  'lib/App/archive/sunix/plot/elaps.pm' 'blib/lib/App/archive/sunix/plot/elaps.pm' \
	  'lib/App/archive/sunix/plot/lcmap.pm' 'blib/lib/App/archive/sunix/plot/lcmap.pm' \
	  'lib/App/archive/sunix/plot/lprop.pm' 'blib/lib/App/archive/sunix/plot/lprop.pm' \
	  'lib/App/archive/sunix/plot/psbbox.pm' 'blib/lib/App/archive/sunix/plot/psbbox.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/archive/sunix/plot/pscontour.pm' 'blib/lib/App/archive/sunix/plot/pscontour.pm' \
	  'lib/App/archive/sunix/plot/pscube.pm' 'blib/lib/App/archive/sunix/plot/pscube.pm' \
	  'lib/App/archive/sunix/plot/pscubecontour.pm' 'blib/lib/App/archive/sunix/plot/pscubecontour.pm' \
	  'lib/App/archive/sunix/plot/psepsi.pm' 'blib/lib/App/archive/sunix/plot/psepsi.pm' \
	  'lib/App/archive/sunix/plot/psgraph.pm' 'blib/lib/App/archive/sunix/plot/psgraph.pm' \
	  'lib/App/archive/sunix/plot/psimage.pm' 'blib/lib/App/archive/sunix/plot/psimage.pm' \
	  'lib/App/archive/sunix/plot/pslabel.pm' 'blib/lib/App/archive/sunix/plot/pslabel.pm' \
	  'lib/App/archive/sunix/plot/psmanager.pm' 'blib/lib/App/archive/sunix/plot/psmanager.pm' \
	  'lib/App/archive/sunix/plot/psmerge.pm' 'blib/lib/App/archive/sunix/plot/psmerge.pm' \
	  'lib/App/archive/sunix/plot/psmovie.pm' 'blib/lib/App/archive/sunix/plot/psmovie.pm' \
	  'lib/App/archive/sunix/plot/pswigb.pm' 'blib/lib/App/archive/sunix/plot/pswigb.pm' \
	  'lib/App/archive/sunix/plot/pswigp.pm' 'blib/lib/App/archive/sunix/plot/pswigp.pm' \
	  'lib/App/archive/sunix/plot/scmap.pm' 'blib/lib/App/archive/sunix/plot/scmap.pm' \
	  'lib/App/archive/sunix/plot/spsplot.pm' 'blib/lib/App/archive/sunix/plot/spsplot.pm' \
	  'lib/App/archive/sunix/plot/supscontour.pm' 'blib/lib/App/archive/sunix/plot/supscontour.pm' \
	  'lib/App/archive/sunix/plot/supscube.pm' 'blib/lib/App/archive/sunix/plot/supscube.pm' \
	  'lib/App/archive/sunix/plot/supscubecontour.pm' 'blib/lib/App/archive/sunix/plot/supscubecontour.pm' \
	  'lib/App/archive/sunix/plot/supsgraph.pm' 'blib/lib/App/archive/sunix/plot/supsgraph.pm' \
	  'lib/App/archive/sunix/plot/supsimage.pm' 'blib/lib/App/archive/sunix/plot/supsimage.pm' \
	  'lib/App/archive/sunix/plot/supsmax.pm' 'blib/lib/App/archive/sunix/plot/supsmax.pm' \
	  'lib/App/archive/sunix/plot/supsmovie.pm' 'blib/lib/App/archive/sunix/plot/supsmovie.pm' \
	  'lib/App/archive/sunix/plot/supswigb.pm' 'blib/lib/App/archive/sunix/plot/supswigb.pm' \
	  'lib/App/archive/sunix/plot/supswigp.pm' 'blib/lib/App/archive/sunix/plot/supswigp.pm' \
	  'lib/App/archive/sunix/plot/suxcontour.pm' 'blib/lib/App/archive/sunix/plot/suxcontour.pm' \
	  'lib/App/archive/sunix/plot/suxgraph.pm' 'blib/lib/App/archive/sunix/plot/suxgraph.pm' \
	  'lib/App/archive/sunix/plot/suximage.pm' 'blib/lib/App/archive/sunix/plot/suximage.pm' \
	  'lib/App/archive/sunix/plot/suxmax.pm' 'blib/lib/App/archive/sunix/plot/suxmax.pm' \
	  'lib/App/archive/sunix/plot/suxmovie.pm' 'blib/lib/App/archive/sunix/plot/suxmovie.pm' \
	  'lib/App/archive/sunix/plot/suxpicker.pm' 'blib/lib/App/archive/sunix/plot/suxpicker.pm' \
	  'lib/App/archive/sunix/plot/suxwigb.pm' 'blib/lib/App/archive/sunix/plot/suxwigb.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/archive/sunix/plot/viewer3.pm' 'blib/lib/App/archive/sunix/plot/viewer3.pm' \
	  'lib/App/archive/sunix/plot/xcontour.pm' 'blib/lib/App/archive/sunix/plot/xcontour.pm' \
	  'lib/App/archive/sunix/plot/xgraph.pm' 'blib/lib/App/archive/sunix/plot/xgraph.pm' \
	  'lib/App/archive/sunix/plot/ximage.pm' 'blib/lib/App/archive/sunix/plot/ximage.pm' \
	  'lib/App/archive/sunix/plot/xmovie.pm' 'blib/lib/App/archive/sunix/plot/xmovie.pm' \
	  'lib/App/archive/sunix/plot/xpicker.pm' 'blib/lib/App/archive/sunix/plot/xpicker.pm' \
	  'lib/App/archive/sunix/plot/xwigb.pm' 'blib/lib/App/archive/sunix/plot/xwigb.pm' \
	  'lib/App/archive/sunix/shapeNcut/archive/sumute_old.pm' 'blib/lib/App/archive/sunix/shapeNcut/archive/sumute_old.pm' \
	  'lib/App/archive/sunix/shapeNcut/suflip.pm' 'blib/lib/App/archive/sunix/shapeNcut/suflip.pm' \
	  'lib/App/archive/sunix/shapeNcut/sugain.pm' 'blib/lib/App/archive/sunix/shapeNcut/sugain.pm' \
	  'lib/App/archive/sunix/shapeNcut/sugprfb.pm' 'blib/lib/App/archive/sunix/shapeNcut/sugprfb.pm' \
	  'lib/App/archive/sunix/shapeNcut/sukill.pm' 'blib/lib/App/archive/sunix/shapeNcut/sukill.pm' \
	  'lib/App/archive/sunix/shapeNcut/sumute.pm' 'blib/lib/App/archive/sunix/shapeNcut/sumute.pm' \
	  'lib/App/archive/sunix/shapeNcut/supad.pm' 'blib/lib/App/archive/sunix/shapeNcut/supad.pm' \
	  'lib/App/archive/sunix/shapeNcut/suresamp.pm' 'blib/lib/App/archive/sunix/shapeNcut/suresamp.pm' \
	  'lib/App/archive/sunix/shapeNcut/susort.pm' 'blib/lib/App/archive/sunix/shapeNcut/susort.pm' \
	  'lib/App/archive/sunix/shapeNcut/susplit.pm' 'blib/lib/App/archive/sunix/shapeNcut/susplit.pm' \
	  'lib/App/archive/sunix/shapeNcut/suvcat.pm' 'blib/lib/App/archive/sunix/shapeNcut/suvcat.pm' \
	  'lib/App/archive/sunix/shapeNcut/suwind.pm' 'blib/lib/App/archive/sunix/shapeNcut/suwind.pm' \
	  'lib/App/archive/sunix/shell/cat_su.pm' 'blib/lib/App/archive/sunix/shell/cat_su.pm' \
	  'lib/App/archive/sunix/shell/cat_txt.pm' 'blib/lib/App/archive/sunix/shell/cat_txt.pm' \
	  'lib/App/archive/sunix/shell/cp.pm' 'blib/lib/App/archive/sunix/shell/cp.pm' \
	  'lib/App/archive/sunix/shell/evince.pm' 'blib/lib/App/archive/sunix/shell/evince.pm' \
	  'lib/App/archive/sunix/shell/sucat.pm' 'blib/lib/App/archive/sunix/shell/sucat.pm' \
	  'lib/App/archive/sunix/shell/sugetgthr.pm' 'blib/lib/App/archive/sunix/shell/sugetgthr.pm' \
	  'lib/App/archive/sunix/shell/suputgthr.pm' 'blib/lib/App/archive/sunix/shell/suputgthr.pm' \
	  'lib/App/archive/sunix/shell/xk.pm' 'blib/lib/App/archive/sunix/shell/xk.pm' \
	  'lib/App/archive/sunix/statsMath/cpftrend.pm' 'blib/lib/App/archive/sunix/statsMath/cpftrend.pm' \
	  'lib/App/archive/sunix/statsMath/entropy.pm' 'blib/lib/App/archive/sunix/statsMath/entropy.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/archive/sunix/statsMath/farith.pm' 'blib/lib/App/archive/sunix/statsMath/farith.pm' \
	  'lib/App/archive/sunix/statsMath/suacor.pm' 'blib/lib/App/archive/sunix/statsMath/suacor.pm' \
	  'lib/App/archive/sunix/statsMath/suacorfrac.pm' 'blib/lib/App/archive/sunix/statsMath/suacorfrac.pm' \
	  'lib/App/archive/sunix/statsMath/sualford.pm' 'blib/lib/App/archive/sunix/statsMath/sualford.pm' \
	  'lib/App/archive/sunix/statsMath/suattributes.pm' 'blib/lib/App/archive/sunix/statsMath/suattributes.pm' \
	  'lib/App/archive/sunix/statsMath/suconv.pm' 'blib/lib/App/archive/sunix/statsMath/suconv.pm' \
	  'lib/App/archive/sunix/statsMath/sufwmix.pm' 'blib/lib/App/archive/sunix/statsMath/sufwmix.pm' \
	  'lib/App/archive/sunix/statsMath/suhistogram.pm' 'blib/lib/App/archive/sunix/statsMath/suhistogram.pm' \
	  'lib/App/archive/sunix/statsMath/suhrot.pm' 'blib/lib/App/archive/sunix/statsMath/suhrot.pm' \
	  'lib/App/archive/sunix/statsMath/suinterp.pm' 'blib/lib/App/archive/sunix/statsMath/suinterp.pm' \
	  'lib/App/archive/sunix/statsMath/sumax.pm' 'blib/lib/App/archive/sunix/statsMath/sumax.pm' \
	  'lib/App/archive/sunix/statsMath/sumean.pm' 'blib/lib/App/archive/sunix/statsMath/sumean.pm' \
	  'lib/App/archive/sunix/statsMath/sumix.pm' 'blib/lib/App/archive/sunix/statsMath/sumix.pm' \
	  'lib/App/archive/sunix/statsMath/suop.pm' 'blib/lib/App/archive/sunix/statsMath/suop.pm' \
	  'lib/App/archive/sunix/statsMath/suop2.pm' 'blib/lib/App/archive/sunix/statsMath/suop2.pm' \
	  'lib/App/archive/sunix/statsMath/suxcor.pm' 'blib/lib/App/archive/sunix/statsMath/suxcor.pm' \
	  'lib/App/archive/sunix/statsMath/suxmax.pm' 'blib/lib/App/archive/sunix/statsMath/suxmax.pm' \
	  'lib/App/archive/sunix/transform/dctcomp.pm' 'blib/lib/App/archive/sunix/transform/dctcomp.pm' \
	  'lib/App/archive/sunix/transform/suamp.pm' 'blib/lib/App/archive/sunix/transform/suamp.pm' \
	  'lib/App/archive/sunix/transform/succepstrum.pm' 'blib/lib/App/archive/sunix/transform/succepstrum.pm' \
	  'lib/App/archive/sunix/transform/succwt.pm' 'blib/lib/App/archive/sunix/transform/succwt.pm' \
	  'lib/App/archive/sunix/transform/sucepstrum.pm' 'blib/lib/App/archive/sunix/transform/sucepstrum.pm' \
	  'lib/App/archive/sunix/transform/sufft.pm' 'blib/lib/App/archive/sunix/transform/sufft.pm' \
	  'lib/App/archive/sunix/transform/sugabor.pm' 'blib/lib/App/archive/sunix/transform/sugabor.pm' \
	  'lib/App/archive/sunix/transform/suicepstrum.pm' 'blib/lib/App/archive/sunix/transform/suicepstrum.pm' \
	  'lib/App/archive/sunix/transform/suifft.pm' 'blib/lib/App/archive/sunix/transform/suifft.pm' \
	  'lib/App/archive/sunix/transform/suminphase.pm' 'blib/lib/App/archive/sunix/transform/suminphase.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/archive/sunix/transform/suphasevel.pm' 'blib/lib/App/archive/sunix/transform/suphasevel.pm' \
	  'lib/App/archive/sunix/transform/suspecfk.pm' 'blib/lib/App/archive/sunix/transform/suspecfk.pm' \
	  'lib/App/archive/sunix/transform/suspecfx.pm' 'blib/lib/App/archive/sunix/transform/suspecfx.pm' \
	  'lib/App/archive/sunix/transform/sutaup.pm' 'blib/lib/App/archive/sunix/transform/sutaup.pm' \
	  'lib/App/archive/sunix/well/las2su.pm' 'blib/lib/App/archive/sunix/well/las2su.pm' \
	  'lib/App/archive/sunix/well/subackus.pm' 'blib/lib/App/archive/sunix/well/subackus.pm' \
	  'lib/App/archive/sunix/well/subackush.pm' 'blib/lib/App/archive/sunix/well/subackush.pm' \
	  'lib/App/archive/sunix/well/sugassman.pm' 'blib/lib/App/archive/sunix/well/sugassman.pm' \
	  'lib/App/archive/sunix/well/sulprime.pm' 'blib/lib/App/archive/sunix/well/sulprime.pm' \
	  'lib/App/archive/sunix/well/suwellrf.pm' 'blib/lib/App/archive/sunix/well/suwellrf.pm' 
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
install ::
	perl ./lib/App/SeismicUnixGui/script/post_install_env.pl


# End.
