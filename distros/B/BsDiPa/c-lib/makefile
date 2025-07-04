#@ Makefile for s-bsdipa-lib (libsbsdipa.a).
#@  - pass s_BSDIPA_32 non-empty for 31-bit file size limits and control data.
#@    (This also almost halves memory usage.)
#@  - pass s_BSDIPA_MAGIC_WINDOW=UINT to define the built-in default for
#@    s_bsdipa_diff_ctx::dc_magic_window (see there).
#@ [- pass s_BSDIPA_CFLAGS='$(SUFX)' for lots of compiler flags.]
#@ - pass -DNDEBUG via $CFLAGS to disable some redundant expensive cleanups.
#@
#@ For example:
#@	CFLAGS='-O1 -DNDEBUG' make s_BSDIPA_32=y s_BSDIPA_CFLAGS='$(SUFX)' all

RM ?= rm

LIB = libsbsdipa.a
LIBDIVSUFSORT = libdivsufsort

SUFWW = #-Weverything
#	-Wconversion -Wsign-conversion \
SUFW = -W -Wall -pedantic $(SUFWW) \
	\
	-Wno-atomic-implicit-seq-cst \
	-Wno-documentation-unknown-command \
	-Wno-duplicate-enum \
	-Wno-reserved-identifier \
	-Wno-reserved-macro-identifier \
	-Wno-unused-macros \
	\
	-Werror=format-security -Werror=int-conversion \

# smake predefines this (cannot handle # in variables)
NUMBER_SIGN?=\#
SUFS = -fno-common \
	-fstrict-aliasing -fstrict-overflow \
	-fstack-protector-strong \
	-D_FORTIFY_SOURCE=3 \
	$$(x=$$(uname -m); [ "$${x}" != "$${x$(NUMBER_SIGN)x86*}" ] && echo -fcf-protection=full) \
	\
#	-DHAVE_SANITIZER \
#		-fsanitize=undefined \
#		-fsanitize=address \

SUFX = $(SUFW) $(SUFS)

CFLAGS += -std=c99 $(s_BSDIPA_CFLAGS) -I$(LIBDIVSUFSORT) -I.

CONFIGH = s-bsdipa-config.h
SRCS = s-bsdiff.c \
	$(LIBDIVSUFSORT)/divsufsort.c $(LIBDIVSUFSORT)/sssort.c $(LIBDIVSUFSORT)/trsort.c \
	s-bspatch.c
OBJS = $(SRCS:.c=.o)

.SUFFIXES: .o .c .y
.c.o:
	$(CC) $(CFLAGS) -c -o $@ -c $<

all: $(LIB)
$(CONFIGH):
	v1= v2=;\
	[ -n "$(s_BSDIPA_32)" ] && v1=s_BSDIPA_32="$(s_BSDIPA_32)";\
	[ -n "$(s_BSDIPA_MAGIC_WINDOW)" ] && v2=s_BSDIPA_MAGIC_WINDOW="$(s_BSDIPA_MAGIC_WINDOW)";\
	./configh.sh "$$v1" "$$v2"
$(LIB): $(CONFIGH) $(OBJS)
	$(AR) crs $(@) $(OBJS)
test: all
clean:
	$(RM) -f $(LIB) $(OBJS) $(CONFIGH)

# s-mk-mode
