###
###   mpg123  Makefile
###

# Where to install binary and manpage on "make install":

PREFIX=/usr/local
BINDIR=$(PREFIX)/bin
MANDIR=$(PREFIX)/man
SECTION=1

########################################################
# Enable the below line If your plathome support IPv6
########################################################

#CFLAGS+= -DINET6
# Additional LIBDIR and libraries if exist
IPV6LIBDIR=
IPV6LIB=

### KAME stack
#IPV6LIBDIR=-L/usr/local/v6/lib
#IPV6LIB=-linet6
### BSD/OS 4.0 (NRL) stack
#IPV6LIBDIR=
#IPV6LIB=
### Linux stack
#IPV6LIBDIR= #/usr/inet6/lib
#IPV6LIB= #-linet6

###################################################
######                                       ######
######   End of user-configurable settings   ######
######                                       ######
###################################################

nothing-specified:
	@echo ""
	@echo "You must specify the system which you want to compile for:"
	@echo ""
	@echo "make linux-help     Linux          more help"
	@echo "make freebsd-help   FreeBSD        more help"
	@echo "make bsdos-help     BSDOS          more help"
	@echo "make aix-help       AIX            more help"
	@echo "make hpux-help      HPUX           more help"
	@echo "make solaris-help   Solaris 2.x    more help" 
	@echo "make dec-help       DEC OSF/True64 more help"
	@echo ""
	@echo "make sunos          SunOS 4.x (tested: 4.1.4)"
	@echo "make sgi            SGI running IRIX"
	@echo "make sgi-gcc        SGI running IRIX using GCC cc"
	@echo "make ultrix         DEC Ultrix (tested: 4.4)"
	@echo "make os2            IBM OS/2"
	@echo "make netbsd         NetBSD"
	@echo "make openbsd        OpenBSD"
	@echo "make mint           MiNT on Atari"
	@echo "make generic        try this one if your system isn't listed above"
	@echo ""
	@echo "Please read the file INSTALL for additional information."
	@echo ""

solaris-help:
	@echo "make solaris        Solaris 2.x (tested: 2.5 and 2.5.1) using SparcWorks cc"
	@echo "make solaris-gcc    Solaris 2.x using GNU cc (somewhat slower)"
	@echo "make solaris-gcc-esd  Solaris 2.x using gnu cc and Esound as audio output"
	@echo "make solaris-x86-gcc-oss Solaris with (commercial) OSS"
	@echo "make solaris-gcc-nas Solaris with gcc and NAS"
	@echo ""
	@echo "Please read the file INSTALL for additional information."
	@echo ""

dec-help:
	@echo "make dec            DEC/Tru64 UNIX (tested: 3.2 and 4.0), OSF/1"
	@echo "make dec-nas        DEC/Tru64 UNIX, OSF/1 with NAS"
	@echo "make dec-esd        DEC/Tru64 UNIX, OSF/1 using EsounD as audio output"
	@echo ""
	@echo "'dec' and 'dec-nas' versions tested using DEC UNIX 3.2 and 4.0"
	@echo "'dec' and 'dec-esd' versions tested using Tru64 UNIX 5.0A"
	@echo ""
	@echo "Please read the file INSTALL for additional information."
	@echo ""

bsdos-help:
	@echo "make bsdos          BSDI BSD/OS"
	@echo "make bsdos4         BSDI BSD/OS 4.0"
	@echo "make bsdos-nas      BSDI BSD/OS with NAS support"
	@echo ""
	@echo "Please read the file INSTALL for additional information."
	@echo ""	

aix-help:
	@echo "make aix-gcc        IBM AIX using gcc (tested: 4.2)"
	@echo "make aix-xlc        IBM AIX using xlc (tested: 4.3)"
	@echo "make aix-ums        IBM AIX using Ultimedia library"
	@echo "make aix-tk3play    IBM AIX"
	@echo ""
	@echo "Please read the file INSTALL for additional information."
	@echo ""	

hpux-help:
	@echo "make hpux           HP/UX 9/10, /7xx"
	@echo "make hpux-gcc       HP/UX 9/10, /7xx using GCC cc"
	@echo "make hpux-alib      HP/UX with ALIB audio"
	@echo ""
	@echo "Please read the file INSTALL for additional information."
	@echo ""	

linux-help:
	@echo ""
	@echo "There are several Linux flavours. Choose one:"
	@echo ""
	@echo "make linux            Linux (i386, Pentium or unlisted platform)"
	@echo "make linux-i486       Linux (optimized for i486 ONLY)"
	@echo "make linux-pentium    Linux with -mpentium"
	@echo "make linux-mmx        Linux with MMX optimized code"
	@echo "make linux-3dnow      Linux with 3DNow! optimized code"
	@echo "make linux-alsa       Linux with ALSA sound driver"
	@echo "make linux-esd        Linux with output to EsounD"
	@echo "make linux-3dnow-alsa Linux 3dnow optimzed with ALSA audio"
	@echo "make linux-3dnow-esd  Linux 3dnow optimzed with output to EsoundD"
	@echo "make linux-nas        Linux with output to Network Audio System"
	@echo "make linux-sajber     Linux, backend for Sajber Jukebox frontend"
	@echo "make linux-alpha      Linux/Alpha (minor changes)"
	@echo "make linux-alpha-alsa Linux/Alpha with ALSA audio"
	@echo "make linux-alpha-esd  Linux/Alpha output to EsounD audio"
	@echo "make linux-ppc        Linux/PPC or MkLinux for the PowerPC"
	@echo "make linux-ppc-esd    Linux/PPC output to EsounD audio"
	@echo "make linux-m68k       Linux/m68k (Amiga, Atari) using OSS"
	@echo "make linux-arm      Linux on the StrongArm"
	@echo "make linux-sparc      Linux/Sparc"
	@echo "make linux-mips-alsa  Linux/MIPS with ALSA sound driver"
	@echo "NOTE: - esd flavours require libaudiofile, available from: "
	@echo "        http://www.68k.org/~michael/audiofile/"
	@echo "      - 3DNow requires 'as' from binutils-2.9.1.0.15 or later"
	@echo "Please read the file INSTALL for additional information."
	@echo ""

freebsd-help:
	@echo ""
	@echo "There are several FreeBSD flavours. Choose one:"
	@echo ""
	@echo "make freebsd         FreeBSD"
	@echo "make freebsd-sajber  FreeBSD, build binary for Sajber Jukebox frontend"
	@echo "make freebsd-tk3play FreeBSD, build binary for tk3play frontend"
	@echo "make freebsd-esd     FreeBSD, output to EsounD"
	@echo "make freebsd-nas     FreeBSD, output to NAS"
	@echo "make freebsd-i486    FreeBSD, optimized for i486"
	@echo ""
	@echo "Please read the file INSTALL for additional information."
	@echo ""

linux-devel:
	$(MAKE) OBJECTS='decode_i386.o dct64_i386.o audio_oss.o' \
        CC=gcc LDFLAGS= \
        CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -DLINUX -Wall -g -m486 \
		-DOSS -funroll-all-loops \
		-finline-functions -ffast-math' \
        mpg123-make

linux-profile:
	$(MAKE) OBJECTS='decode_i386.o dct64_i386.o audio_oss.o' \
        CC=gcc LDFLAGS='-pg' \
        CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -DLINUX -Wall -pg -m486 \
		-DOSS -funroll-all-loops \
		-finline-functions -ffast-math' \
        mpg123-make

linux:
	$(MAKE) CC=gcc LDFLAGS= \
		OBJECTS='decode_i386.o dct64_i386.o decode_i586.o \
			audio_oss.o term.o' \
		CFLAGS='$(CFLAGS) -DI386_ASSEM -DPENTIUM_OPT -DREAL_IS_FLOAT -DLINUX \
			-DOSS -DTERM_CONTROL\
			-Wall -O2 -m486 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make

linux-pentium:
	$(MAKE) CC=gcc LDFLAGS= \
		OBJECTS='decode_i386.o dct64_i386.o decode_i586.o \
			audio_oss.o term.o' \
		CFLAGS='$(CFLAGS) -DI386_ASSEM -DPENTIUM_OPT -DREAL_IS_FLOAT -DLINUX \
			-DOSS -DTERM_CONTROL\
			-Wall -O2 -mpentium \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make

linux-mmx:
	$(MAKE) CC=gcc LDFLAGS= \
		OBJECTS='decode_i386.o dct64_MMX.o tabinit_MMX.o decode_MMX.o \
			audio_oss.o term.o' \
		CFLAGS='-DUSE_MMX -DI386_ASSEM -DPENTIUM_OPT -DREAL_IS_FLOAT \
			-DLINUX -DOSS -DTERM_CONTROL\
			-Wall -O2 -m486 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make

linux-3dnow:
	$(MAKE) CC=gcc LDFLAGS= \
		OBJECTS='decode_i386.o decode_3dnow.o dct64_3dnow.o \
			dct64_i386.o dct36_3dnow.o getcpuflags.o \
			equalizer_3dnow.o decode_i586.o audio_oss.o term.o' \
		CFLAGS='$(CFLAGS) -DI386_ASSEM -DREAL_IS_FLOAT -DPENTIUM_OPT -DLINUX \
			-DUSE_3DNOW -DOSS -DTERM_CONTROL\
			-Wall -O2 -m486 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make


linux-i486:
	$(MAKE) CC=gcc LDFLAGS= \
		OBJECTS='decode_i386.o dct64_i386.o decode_i586.o \
			decode_i486.o audio_oss.o term.o \
			dct64_i486-a.o dct64_i486-b.o ' \
		CFLAGS='$(CFLAGS) -DI386_ASSEM -DREAL_IS_FLOAT -DI486_OPT -DLINUX \
			-DOSS -DTERM_CONTROL\
			-Wall -O2 -m486 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make

linux-esd:
	$(MAKE) CC=gcc LDFLAGS= \
		AUDIO_LIB='-lesd -laudiofile' \
		OBJECTS='decode_i386.o dct64_i386.o decode_i586.o \
			audio_esd.o' \
		CFLAGS='$(CFLAGS) -DI386_ASSEM -DREAL_IS_FLOAT -DPENTIUM_OPT -DLINUX \
			-DOSS -DUSE_ESD \
			-Wall  -O2 -m486 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math \
			$(RPM_OPT_FLAGS)' \
		mpg123-make

linux-alsa:
	$(MAKE) CC=gcc LDFLAGS= \
		AUDIO_LIB='-lasound' \
		OBJECTS='decode_i386.o dct64_i386.o decode_i586.o \
			audio_alsa.o term.o' \
		CFLAGS='$(CFLAGS) -DI386_ASSEM -DREAL_IS_FLOAT -DPENTIUM_OPT -DLINUX \
			-DALSA -DTERM_CONTROL\
			-Wall  -O2 -m486 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math \
			$(RPM_OPT_FLAGS)' \
		mpg123-make

linux-3dnow-alsa:
	$(MAKE) CC=gcc LDFLAGS= \
		AUDIO_LIB='-lasound' \
		OBJECTS='decode_i386.o decode_3dnow.o dct64_3dnow.o \
			dct64_i386.o dct36_3dnow.o getcpuflags.o \
			equalizer_3dnow.o decode_i586.o audio_alsa.o term.o' \
		CFLAGS='-DI386_ASSEM -DREAL_IS_FLOAT -DPENTIUM_OPT -DLINUX \
			-DUSE_3DNOW -DALSA -DTERM_CONTROL\
			-Wall -O2 -m486 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make

linux-3dnow-esd:
	$(MAKE) CC=gcc LDFLAGS= \
		AUDIO_LIB='-lesd -laudiofile' \
		OBJECTS='decode_i386.o decode_3dnow.o dct64_3dnow.o \
			dct64_i386.o dct36_3dnow.o getcpuflags.o \
			equalizer_3dnow.o decode_i586.o audio_esd.o' \
		CFLAGS='-DI386_ASSEM -DREAL_IS_FLOAT -DPENTIUM_OPT -DLINUX \
			-DUSE_3DNOW -DUSE_ESD \
			-Wall -O2 -m486 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make

linux-mips-alsa:
	$(MAKE) CC=gcc LDFLAGS= \
		AUDIO_LIB='-lasound' \
		OBJECTS='decode.o dct64.o audio_alsa.o term.o' \
		CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -DLINUX -DALSA \
			-DTERM_CONTROL -Wall  -O2 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math \
			$(RPM_OPT_FLAGS)' \
		mpg123-make

linux-alpha:
	$(MAKE) CC=gcc LDFLAGS= OBJECTS='decode.o dct64.o audio_oss.o' \
		CFLAGS='$(CFLAGS) -DLINUX -DOSS -Wall -O2 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math \
			-Wall -O6 -DUSE_MMAP \
			$(RPM_OPT_FLAGS)' \
		mpg123-make

linux-alpha-alsa:
	$(MAKE) CC=gcc LDFLAGS= \
		AUDIO_LIB='-lasound' \
		OBJECTS='decode.o dct64.o audio_alsa.o term.o' \
		CFLAGS='-DLINUX \
			-DALSA -DTERM_CONTROL\
			-DUSE_MMAP  -O6 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math \
			$(RPM_OPT_FLAGS)' \
		mpg123-make

linux-alpha-esd:
	$(MAKE) CC=gcc LDFLAGS= \
		AUDIO_LIB='-lesd -laudiofile' \
		OBJECTS='decode.o dct64.o audio_esd.o' \
		CFLAGS='$(CFLAGS) -DLINUX -DOSS -DUSE_ESD -Wall -O2 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math \
			-Wall -O6 -DUSE_MMAP \
			$(RPM_OPT_FLAGS)' \
		mpg123-make

#linux-ppc:
#	$(MAKE) CC=gcc  LDFLAGS= \
#		OBJECTS='decode.o dct64.o audio_oss.o' \
#		CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -DLINUX -Wall -O2 -mcpu=ppc \
#			-DOSS -DPPC_ENDIAN \
#			-fomit-frame-pointer -funroll-all-loops \
#			-finline-functions -ffast-math' \
#		mpg123-make

#linux-ppc-esd:
#	$(MAKE) CC=gcc  LDFLAGS= \
#		AUDIO_LIB='-lesd -laudiofile' \
#		OBJECTS='decode.o dct64.o audio_esd.o' \
#		CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -DLINUX -Wall -O2 -mcpu=ppc \
#			-DOSS -DPPC_ENDIAN \
#			-fomit-frame-pointer -funroll-all-loops \
#			-finline-functions -ffast-math' \
#		mpg123-make

linux-ppc:
	$(MAKE) CC=gcc  LDFLAGS= \
		OBJECTS='decode.o dct64.o audio_oss.o' \
		CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -DLINUX -Wall -O2 -mcpu=ppc \
			-DOSS \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make

linux-ppc-esd:
	$(MAKE) CC=gcc  LDFLAGS= \
		AUDIO_LIB='-lesd -laudiofile' \
		OBJECTS='decode.o dct64.o audio_esd.o' \
		CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -DLINUX -Wall -O2 -mcpu=ppc \
			-DOSS -DUSE_ESD \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make

linux-sparc:
	$(MAKE) CC=gcc  LDFLAGS= \
		OBJECTS='decode.o dct64.o audio_sun.o' \
		CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -DUSE_MMAP -DSPARCLINUX -Wall -O2 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make

linux-sparc-esd:
	$(MAKE) CC=gcc  LDFLAGS= \
		AUDIO_LIB='-lesd -laudiofile' \
		OBJECTS='decode.o dct64.o audio_esd.o' \
		CFLAGS='-DREAL_IS_FLOAT -DUSE_MMAP -DOSS -DUSE_ESD -DSPARCLINUX -Wall -O2 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math \
		mpg123-make


linux-armv4l:
	$(MAKE) CC=gcc LDFLAGS= OBJECTS='decode.o dct64.o audio_oss.o' \
		CFLAGS='-DLINUX -DOSS -Wall -O2 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math \
			-Wall -O6 -DUSE_MMAP \
                mpg123-make

linux-arm:
	$(MAKE) CC=gcc LDFLAGS= OBJECTS='decode.o dct64.o audio_oss.o' \
		CFLAGS='-DREAL_IS_FIXED -DLINUX \
			-DOSS -Wall -O6 -march=armv4 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make
 

linux-m68k:
	$(MAKE) CC=gcc LDFLAGS= OBJECTS='decode.o dct64.o audio_oss.o' \
		CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -DLINUX \
			-DOSS -DOSS_BIG_ENDIAN -Wall -O2 -m68040 \
			-fomit-frame-pointer -funroll-loops \
			-finline-functions -ffast-math' \
		mpg123-make

linux-sajber:
	@ $(MAKE) FRONTEND=sajberplay-make linux-frontend

linux-tk3play:
	@ $(MAKE) FRONTEND=mpg123m-make linux-frontend

freebsd-sajber:
	@ $(MAKE) FRONTEND=sajberplay-make freebsd-frontend

freebsd-tk3play:
	@ $(MAKE) FRONTEND=mpg123m-make freebsd-frontend

linux-frontend:
	$(MAKE) CC=gcc LDFLAGS= \
		OBJECTS='decode_i386.o dct64_i386.o decode_i586.o \
			control_sajber.o control_tk3play.o audio_oss.o' \
		CFLAGS='$(CFLAGS) -DFRONTEND -DOSS -DI386_ASSEM -DREAL_IS_FLOAT \
			-DPENTIUM_OPT -DLINUX -Wall -O2 -m486 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		$(FRONTEND)

linux-nas:
	$(MAKE) CC=gcc LDFLAGS='-L/usr/X11R6/lib' \
		AUDIO_LIB='-laudio -lXau' \
		OBJECTS='decode_i386.o dct64_i386.o audio_nas.o' \
		CFLAGS='$(CFLAGS) -I/usr/X11R6/include \
			-DI386_ASSEM -DREAL_IS_FLOAT -DLINUX -DNAS \
			-Wall -O2 -m486 \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make

#### the following defines are for experimental use ... 
#
#CFLAGS='$(CFLAGS) -pg -DI386_ASSEM -DREAL_IS_FLOAT -DLINUX -Wall -O2 -m486 -funroll-all-loops -finline-functions -ffast-math' mpg123
#CFLAGS='$(CFLAGS) -DI386_ASSEM -O2 -DREAL_IS_FLOAT -DLINUX -Wall -g'
#CFLAGS='$(CFLAGS) -DI386_ASSEM -DREAL_IS_FLOAT -DLINUX -Wall -O2 -m486 -fomit-frame-pointer -funroll-all-loops -finline-functions -ffast-math -malign-loops=2 -malign-jumps=2 -malign-functions=2'

freebsd:
	$(MAKE) CC=cc LDFLAGS= \
		OBJECTS='decode_i386.o dct64_i386.o audio_oss.o' \
		CFLAGS='$(CFLAGS) -Wall -ansi -pedantic -O4 -m486 -fomit-frame-pointer \
			-funroll-all-loops -ffast-math -DROT_I386 \
			-DI386_ASSEM -DREAL_IS_FLOAT -DUSE_MMAP -DOSS' \
		mpg123-make

freebsd-i486:
	$(MAKE) CC=cc LDFLAGS= \
		OBJECTS='decode_i386.o dct64_i386.o \
			decode_i486.o dct64_i486.o audio_oss.o' \
		CFLAGS='$(CFLAGS) -Wall -ansi -pedantic -O4 -m486 -fomit-frame-pointer \
			-funroll-all-loops -ffast-math -DROT_I386 \
			-DOPT_ARCH=i486 \
			-march=i486 -finline-functions \
			-DI386_ASSEM -DREAL_IS_FLOAT -DUSE_MMAP -DOSS' \
		mpg123-make

freebsd-esd:
	$(MAKE) CC=cc LDFLAGS= \
		AUDIO_LIB='-lesd -laudiofile' \
		OBJECTS='decode_i386.o dct64_i386.o $(GETBITS) audio_esd.o' \
		CFLAGS='$(CFLAGS) -Wall -ansi -pedantic -O4 -m486 -fomit-frame-pointer \
			-funroll-all-loops -ffast-math -DROT_I386 \
			-DI386_ASSEM -DREAL_IS_FLOAT -DUSE_MMAP -DOSS -DUSE_ESD \
			-I/usr/local/include -L/usr/local/lib 
		mpg123-make

freebsd-nas:
	$(MAKE) CC=cc LDFLAGS= \
		AUDIO_LIB='-L/usr/X11R6/lib -laudio -lXau' \
		OBJECTS='decode_i386.o dct64_i386.o audio_nas.o' \
		CFLAGS='-Wall -ansi -pedantic -O4 -m486 -fomit-frame-pointer \
			-funroll-all-loops -ffast-math -DROT_I386 \
			-DREAD_MMAP \
			-DI386_ASSEM -DREAL_IS_FLOAT -DUSE_MMAP -DNAS \
			-I/usr/X11R6/include -L/usr/X11R6/lib' \
		mpg123-make

freebsd-frontend:
	$(MAKE) CC=cc LDFLAGS= \
		OBJECTS='decode_i386.o dct64_i386.o audio_oss.o \
			control_sajber.o control_tk3play.o' \
		CFLAGS='$(CFLAGS) -Wall -ansi -pedantic -O4 -m486 -fomit-frame-pointer \
			-funroll-all-loops -ffast-math -DROT_I386 \
			-DFRONTEND \
			-DI386_ASSEM -DREAL_IS_FLOAT -DUSE_MMAP -DOSS' \
		$(FRONTEND)

openbsd:
	$(MAKE) CC=cc LDFLAGS='-L/usr/lib' \
		AUDIO_LIB='-lossaudio' \
		OBJECTS='decode_i386.o dct64_i386.o audio_oss.o' \
		CFLAGS='-Wall -ansi -pedantic -O4 -m486 -fomit-frame-pointer \
			-funroll-all-loops -ffast-math -DROT_I386 \
			-DREAD_MMAP \
			-DI386_ASSEM -DREAL_IS_FLOAT -DUSE_MMAP -DOSS' \
		mpg123-make

# -mno-epilogue
# -mflat -mv8 -mcpu=ultrasparc

# these are MY EXPERIMENTAL compile entries
solaris-pure:
	$(MAKE) CC='purify -cache-dir=/tmp cc' \
		LDFLAGS='-lsocket -lnsl' \
		OBJECTS='decode.o dct64.o audio_sun.o term.o' \
		CFLAGS='$(CFLAGS) -fast -native -xO4 -DSOLARIS -DTERM_CONTROL \
			-DUSE_MMAP ' \
		mpg123-make

solaris-ccscc:
	$(MAKE) CC=/usr/ccs/bin/ucbcc LDFLAGS='-lsocket -lnsl' \
		OBJECTS='decode.o dct64.o audio_sun.o term.o' \
		CFLAGS='$(CFLAGS) -fast -native -xO4 -DSOLARIS \
			-DUSE_MMAP ' \
		mpg123-make

# common solaris compile entries
solaris:
	$(MAKE) CC=cc LDFLAGS='-lsocket -lnsl' \
		OBJECTS='decode.o dct64.o audio_sun.o term.o' \
		CFLAGS='$(CFLAGS) -fast -native -xO4 -DSOLARIS \
			-DUSE_MMAP -DTERM_CONTROL' \
		mpg123-make

solaris-gcc-profile:
	$(MAKE) CC='gcc' \
		LDFLAGS='-lsocket -lnsl -pg' \
		OBJECTS='decode.o dct64.o audio_sun.o' \
		CFLAGS='$(CFLAGS) -g -pg -O2 -Wall -DSOLARIS -DREAL_IS_FLOAT -DUSE_MMAP \
			-funroll-all-loops -finline-functions' \
		mpg123-make

#	-DREAL_IS_FLOAT 

solaris-gcc:
	$(MAKE) CC=gcc \
		LDFLAGS='-lsocket -lnsl' \
		OBJECTS='decode.o dct64.o audio_sun.o term.o' \
		CFLAGS='$(CFLAGS) -O2 -Wall -pedantic -DSOLARIS \
			-DUSE_MMAP -g \
			-DTERM_CONTROL \
			-funroll-all-loops  -finline-functions' \
		mpg123-make

solaris-gcc-esd:
	$(MAKE) CC=gcc LDFLAGS='-lsocket -lnsl' \
		AUDIO_LIB='-lesd -lresolv' \
		OBJECTS='decode.o dct64.o audio_esd.o' \
		CFLAGS='$(CFLAGS) -O2 -Wall -DSOLARIS -DREAL_IS_FLOAT -DUSE_MMAP \
			-DUSE_ESD -funroll-all-loops -finline-functions' \
		mpg123-make

solaris-x86-gcc-oss:
	$(MAKE) CC=gcc LDFLAGS='-lsocket -lnsl' \
		OBJECTS='decode_i386.o dct64_i386.o decode_i586.o \
			audio_oss.o' \
		CFLAGS='$(CFLAGS) -DI386_ASSEM -DREAL_IS_FLOAT -DPENTIUM_OPT -DUSE_MMAP \
			-DOSS \
			-Wall -O2 -m486 \
			-funroll-all-loops -finline-functions' \
		mpg123-make

solaris-gcc-nas:
	$(MAKE) CC=gcc LDFLAGS='-lsocket -lnsl' \
		AUDIO_LIB='-L/usr/openwin/lib -laudio -lXau'\
		OBJECTS='decode.o dct64.o audio_nas.o' \
		CFLAGS='$(CFLAGS) -O2 -I/usr/openwin/include -Wall \
			-DSOLARIS -DREAL_IS_FLOAT -DUSE_MMAP \
			-DNAS \
			-funroll-all-loops -finline-functions' \
		mpg123-make

sunos:
	$(MAKE) CC=gcc LDFLAGS= \
		OBJECTS='decode.o dct64.o audio_sun.o' \
		CFLAGS='$(CFLAGS) -O2 -DSUNOS -DREAL_IS_FLOAT -DUSE_MMAP \
			-funroll-loops' \
		mpg123-make

#		CFLAGS='-DREAL_IS_FLOAT -Aa +O3 -D_HPUX_SOURCE -DHPUX'
hpux:
	$(MAKE) CC=cc LDFLAGS= \
		OBJECTS='decode.o dct64.o audio_hp.o' \
		CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -Ae +O3 -D_HPUX_SOURCE -DHPUX' \
		mpg123-make

hpux-alib:
	$(MAKE) CC=cc LDFLAGS='-L/opt/audio/lib' \
		OBJECTS='decode.o dct64.o audio_alib.o' \
		AUDIO_LIB=-lAlib \
		CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -Ae +O3 -D_HPUX_SOURCE -DHPUX \
			-I/opt/audio/include' \
		mpg123-make

hpux-gcc:
	$(MAKE) CC=gcc LDFLAGS= OBJECTS='decode.o dct64.o audio_hp.o' \
		CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -O3 -D_HPUX_SOURCE -DHPUX' \
		mpg123-make
sgi:
	$(MAKE) CC=cc LDFLAGS= \
		OBJECTS='decode.o dct64.o audio_sgi.o' AUDIO_LIB=-laudio \
		CFLAGS='$(CFLAGS) -O2 -DSGI -DTERM_CONTROL \
		-DREAL_IS_FLOAT -DUSE_MMAP' \
		mpg123-make

sgi-gcc:
	$(MAKE) CC=gcc LDFLAGS= \
		OBJECTS='decode.o dct64.o audio_sgi.o' AUDIO_LIB=-laudio \
		CFLAGS='$(CFLAGS) -O2 -DSGI -DTERM_CONTROL \
		-DREAL_IS_FLOAT -DUSE_MMAP' \
		mpg123-make

dec:
	$(MAKE) CC=cc LDFLAGS= OBJECTS='decode.o dct64.o audio_dec.o' \
		AUDIO_LIB=-lmme \
		CFLAGS='$(CFLAGS) -std1 -warnprotos -O4 -DUSE_MMAP \
			-I/usr/include/mme' \
		mpg123-make

dec-esd:
	$(MAKE) CC=cc LDFLAGS= OBJECTS='decode.o dct64.o audio_esd.o' \
		AUDIO_LIB='-lesd -laudiofile' \
		CFLAGS='$(CFLAGS) -std1 -warnprotos -O4 -DUSE_MMAP \
			-I/usr/include/mme `esd-config --cflags`' \
		mpg123-make

dec-nas:
	$(MAKE) CC=cc LDFLAGS='-L/usr/X11R6/lib' \
		AUDIO_LIB='-laudio -lXau -ldnet_stub'\
		OBJECTS='decode.o dct64.o  audio_nas.o' \
		CFLAGS='$(CFLAGS) -I/usr/X11R6/include -std1 -warnprotos -O4 -DUSE_MMAP' \
		mpg123-make

ultrix:
	$(MAKE) CC=cc LDFLAGS= OBJECTS='decode.o dct64.o audio_dummy.o' \
		CFLAGS='$(CFLAGS) -std1 -O2 -DULTRIX' \
		mpg123-make

aix-gcc:
	$(MAKE) CC=gcc LDFLAGS= OBJECTS='decode.o dct64.o audio_aix.o' \
		CFLAGS='$(CFLAGS) -DAIX -Wall -O6 -DUSE_MMAP -DREAL_IS_FLOAT \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		mpg123-make

aix-xlc:
	$(MAKE) LDFLAGS= OBJECTS='decode.o dct64.o audio_aix.o' \
		CFLAGS="$(CFLAGS) -O3 -qstrict -qcpluscmt -DAIX -DUSE_MMAP \
		mpg123-make


aix-ums:
	$(MAKE) LDFLAGS='-L/usr/lpp/som/lib -lUMSobj' \
		OBJECTS='decode.o dct64.o audio_aixums.o term.o' \
		CFLAGS="$(CFLAGS) -O3 -qstrict -qcpluscmt -DAIX -DAIX_UMS \
			-DUSE_MMAP -DTERM_CONTROL \
			-DREAD_MMAP -I/usr/lpp/UMS/include \
			-I/usr/lpp/som/include" \
		mpg123-make


aix-tk3play:
	@ $(MAKE) FRONTEND=mpg123m-make aix-frontend

aix-frontend:
	$(MAKE) LDFLAGS= OBJECTS='decode.o dct64.o audio_aix.o \
			control_sajber.o control_tk3play.o' \
		CFLAGS='$(CFLAGS) -DAIX -Wall -O6 -DUSE_MMAP -DFRONTEND \
			-fomit-frame-pointer -funroll-all-loops \
			-finline-functions -ffast-math' \
		$(FRONTEND)

os2:
	$(MAKE) CC=gcc LDFLAGS= \
		OBJECTS='decode_i386.o dct64_i386.o audio_os2.o' \
		CFLAGS='$(CFLAGS) -DREAL_IS_FLOAT -DNOXFERMEM -DOS2 -Wall -O2 -m486 \
		-fomit-frame-pointer -funroll-all-loops \
		-finline-functions -ffast-math' \
		LIBS='-los2me -lsocket' \
		mpg123.exe

netbsd:
	$(MAKE) CC=cc LDFLAGS= \
		OBJECTS='decode.o dct64.o audio_sun.o' \
		CFLAGS='$(CFLAGS) -Wall -ansi -pedantic -O3 -fomit-frame-pointer \
			-funroll-all-loops -ffast-math \
			-DREAL_IS_FLOAT -DUSE_MMAP -DNETBSD' \
		mpg123-make

netbsd-i386:
	$(MAKE) CC=cc LDFLAGS= \
		OBJECTS='decode_i386.o dct64_i386.o audio_sun.o' \
		CFLAGS='$(CFLAGS) -Wall -ansi -pedantic -O4 -m486 -fomit-frame-pointer \
			-funroll-all-loops -ffast-math -DROT_I386 \
			-DI386_ASSEM -DREAL_IS_FLOAT -DUSE_MMAP -DNETBSD' \
		mpg123-make

bsdos:
	$(MAKE) CC=shlicc2 LDFLAGS= \
		OBJECTS='decode_i386.o dct64_i386.o \
			 audio_oss.o' \
		CFLAGS='$(CFLAGS) -Wall -O4 -m486 -fomit-frame-pointer \
			-funroll-all-loops -ffast-math -DROT_I386 \
			-DI386_ASSEM -DREAL_IS_FLOAT -DUSE_MMAP -DOSS \
			-DDONT_CATCH_SIGNALS' \
		mpg123-make

bsdos4:
	$(MAKE) CC=gcc LDFLAGS= \
		OBJECTS='decode_i386.o dct64_i386.o audio_oss.o' \
		CFLAGS='$(CFLAGS) -Wall -O4 -m486 -fomit-frame-pointer \
			-funroll-all-loops -ffast-math -DROT_I386 \
			-DI386_ASSEM -DREAL_IS_FLOAT -DUSE_MMAP -DOSS \
			-DDONT_CATCH_SIGNALS' \
		mpg123-make

bsdos-nas:
	$(MAKE) CC=shlicc2 LDFLAGS= \
		AUDIO_LIB='-laudio -lXau -L/usr/X11R6/lib' \
		OBJECTS='decode_i386.o dct64_i386.o \
			audio_nas.o' \
		CFLAGS='$(CFLAGS) -Wall -O4 -m486 -fomit-frame-pointer \
			-funroll-all-loops -ffast-math -DROT_I386 \
			-DI386_ASSEM -DREAL_IS_FLOAT -DUSE_MMAP -DOSS \
			-DDONT_CATCH_SIGNALS -DNAS' \
		mpg123-make

mint:
	$(MAKE) CC=gcc LDFLAGS= \
		OBJECTS='decode.o dct64.o audio_mint.o' \
		CFLAGS='$(CFLAGS) -Wall -O2 -m68020-40 -m68881 \
		-fomit-frame-pointer -funroll-all-loops \
		-finline-functions -ffast-math \
		-DREAL_IS_FLOAT -DMINT -DNOXFERMEM' \
		AUDIO_LIB='-lsocket' \
		mpg123-make

# maybe you need the additonal options LDFLAGS='-lnsl -lsocket' when linking (see solaris:)
generic:
	$(MAKE) LDFLAGS= OBJECTS='decode.o dct64.o audio_dummy.o' \
		CFLAGS='$(CFLAGS) -O -DGENERIC -DNOXFERMEM' \
		mpg123-make

###########################################################################
###########################################################################
###########################################################################

sajberplay-make:
	@ $(MAKE) CFLAGS='$(CFLAGS)' BINNAME=sajberplay mpg123

mpg123m-make:
	@ $(MAKE) CFLAGS='$(CFLAGS)' BINNAME=mpg123m mpg123

mpg123-make:
	@ $(MAKE) CFLAGS='$(CFLAGS)' BINNAME=mpg123 mpg123

mpg123: mpg123.o common.o $(OBJECTS) decode_2to1.o decode_4to1.o \
		tabinit.o audio.o layer1.o layer2.o layer3.o buffer.o \
		getlopt.o httpget.o xfermem.o equalizer.o \
		decode_ntom.o Makefile wav.o readers.o \
		control_generic.o vbrhead.o playlist.o getbits.o
	$(CC) $(CFLAGS) $(LDFLAGS)  mpg123.o tabinit.o common.o layer1.o \
		layer2.o layer3.o audio.o buffer.o decode_2to1.o equalizer.o \
		decode_4to1.o getlopt.o httpget.o xfermem.o decode_ntom.o \
		wav.o readers.o control_generic.o vbrhead.o playlist.o getbits.o \
		$(OBJECTS) -o $(BINNAME) -lm $(AUDIO_LIB) $(IPV6LIBDIR) $(IPV6LIB)

mpg123.exe: mpg123.o common.o $(OBJECTS) decode_2to1.o decode_4to1.o \
		tabinit.o audio.o layer1.o layer2.o layer3.o buffer.o \
		getlopt.o httpget.o Makefile wav.o readers.o 
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o mpg123.exe -lm $(LIBS)

###########################################################################
###########################################################################
###########################################################################

layer1.o:	mpg123.h getbits.h
layer2.o:	mpg123.h l2tables.h getbits.h
layer3.o:	mpg123.h huffman.h common.h getbits.h
decode.o:	mpg123.h
decode_2to1.o:	mpg123.h
decode_4to1.o:	mpg123.h
decode_ntom.o:	mpg123.h
decode_i386.o:	mpg123.h
common.o:	mpg123.h common.h
mpg123.o:	mpg123.c mpg123.h getlopt.h xfermem.h version.h buffer.h term.h
mpg123.h:	audio.h
audio.o:	mpg123.h
audio_oss.o:	mpg123.h
audio_sun.o:	mpg123.h
audio_sgi.o:	mpg123.h
audio_hp.o:	mpg123.h
audio_nas.o:	mpg123.h
audio_os2.o:	mpg123.h
audio_dummy.o:	mpg123.h
buffer.o:	mpg123.h xfermem.h buffer.h
getbits.o:	common.h mpg123.h
tabinit.o:	mpg123.h audio.h
getlopt.o:	getlopt.h
httpget.o:	mpg123.h
dct64.o:	mpg123.h
dct64_i386.o:	mpg123.h
xfermem.o:	xfermem.h
equalizer.o:	mpg123.h
control_sajber.o:	jukebox/controldata.h mpg123.h
wav.o:		mpg123.h
readers.o:	mpg123.h buffer.h common.h
term.o:		mpg123.h buffer.h term.h common.h
vbrhead.o:	mpg123.h
playlist.o:	playlist.h mpg123.h

###########################################################################
###########################################################################
###########################################################################

clean:
	rm -f *.o *core *~ mpg123 gmon.out sajberplay system mpg123m

prepared-for-install:
	@if [ ! -x mpg123 ]; then \
		echo '###' ; \
		echo '###  Before doing "make install", you have to compile the software.' ; \
		echo '### Type "make" for more information.' ; \
		echo '###' ; \
		exit 1 ; \
	fi

system: mpg123.h system.c
	$(CC) -o $@ -Wall -O2 system.c

install:	prepared-for-install
	strip mpg123
	if [ -x /usr/ccs/bin/mcs ]; then /usr/ccs/bin/mcs -d mpg123; fi
	mkdir -p $(BINDIR)
	mkdir -p $(MANDIR)/man$(SECTION)
	cp -f mpg123 $(BINDIR)
	chmod 755 $(BINDIR)/mpg123
	cp -f mpg123.1 $(MANDIR)/man$(SECTION)
	chmod 644 $(MANDIR)/man$(SECTION)/mpg123.1

dist:	clean
	DISTNAME="`basename \`pwd\``" ; \
	sed '/prgDate/s_".*"_"'`date +%Y/%m/%d`'"_' version.h > version.new; \
	mv -f version.new version.h; \
	cd .. ; \
	rm -f "$$DISTNAME".tar.gz "$$DISTNAME".tar ; \
	tar cvf "$$DISTNAME".tar "$$DISTNAME" ; \
	gzip -9 "$$DISTNAME".tar
