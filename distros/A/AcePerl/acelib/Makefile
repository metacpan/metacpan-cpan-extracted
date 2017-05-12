true = 1
false = 0
RANLIB_NEEDED = true	# default overridable in $(ACEDB_MACHINE)_DEF
AR_OPTIONS = rlu	# default overridable in $(ACEDB_MACHINE)_DEF

RPCGEN_FLAGS = -I -K -1
# -I -K -1  good for alpha
# -b  -I -K -1  good for linux, probably solaris ?

# suppress auto SCCS extraction
.SCCS_GET:

#################################################################
########## Machine dependent compiler modification ##############
############# Are included from an external file ################
#### This is equivalent to, but more portable than $($(CC)) #####
### Edit these rules to adapt the makefile to a new machine #####
# Note that you can keep different DEF files for the same machine
# setting  various compiler  options
#################################################################
include wmake/$(ACEDB_MACHINE)_DEF

FREE_OBJS = freesubs.o freeout.o messubs.o memsubs.o arraysub.o \
	liste.o filsubs.o \
	heap.o timesubs.o bump.o randsubs.o call.o menu.o dict.o \
	helpsubs.o texthelp.o

###########################################################
##  Compiler and library options
## CC, LIBS, NAME are defined in $(ACEDB_MACHINE)_DEF
##

IDIR = -I. -I./wh
# Do not use -I/usr/include
# it prevents gcc from picking up its own includes
# (cc goes to /usr/include anyway)

## to undefine any rubbish
CCFLAGS =
GCFLAGS =

## Different platforms use CC or COMPILE.c
#  (USEROPTS - see comments at top of file)
#
CC =        $(COMPILER) $(USEROPTS) $(IDIR) -D$(NAME) -c
COMPILE.c = $(COMPILER) $(USEROPTS) $(IDIR) -D$(NAME) -c

###########################################################
## make targets.
##
##
.KEEP_STATE: 

# "all" should always be the first target so that it is the default make action.
all : libaceperl.a

clean:
	\rm -f *.o *.a core $(RPCGEN_PRODUCTS)

depend:
	makedepend $(IDIR) *.c

################## libraries #########################

libaceperl.a : $(FREE_OBJS) aceclientlib.o rpcace_clnt.o rpcace_xdr.o
	ar $(AR_OPTIONS) $@ $?
	if ( $(RANLIB_NEEDED) ) then ranlib $@; fi

libfree.a : $(FREE_OBJS)
	ar $(AR_OPTIONS) libfree.a $?
	if ( $(RANLIB_NEEDED) ) then ranlib libfree.a; fi

#########################################
#### public C interface: libace #########
#########################################

# 
# aceversion.c is recompiled & rearchived every time one of the
# other libace objects is recompiled. Hence aceversion.c enables
# us to record the link date of the library along with the ACEDB
# version.
# (this is not quite true at the moment because of the graphic/
# non-graphic split in libace, but this will go away)
#
aceversion.o: $(GENERIC_ACE_OBJS) $(GENERIC_ACE_NONGRAPH_OBJS) $(GENERIC_ACE_GRAPH_OBJS)

LIBACE_OBJS = $(GENERIC_ACE_OBJS) $(GENERIC_ACE_NONGRAPH_OBJS) aceversion.o

libace.a :  $(LIBACE_OBJS)
	ar $(AR_OPTIONS) libace.a $?
	if ( $(RANLIB_NEEDED) ) then ranlib libace.a; fi

######################################################
#### RPC server/client ACEDB programs ################
######################################################

RPCGEN_PRODUCTS = rpcace.h rpcace_xdr.c rpcace_clnt.c rpcace_svc.c

$(RPCGEN_PRODUCTS): rpcace.x
	rpcgen $(RPCGEN_FLAGS) rpcace.x

rpcace_sp.o: rpcace_sp.c rpcace_svc.c

aceclientlib.o: aceclientlib.c rpcace.h
	$(CC) -c $<

RPC_CLIENT_OBJS = aceclientlib.o rpcace_clnt.o rpcace_xdr.o
RPC_SERVER_OBJS = rpcace_sp.o  rpcace_xdr.o 
NET_CLIENT_OBJS = aceclientlib.o rpcace_clnt.o rpcace_xdr.o
RPC_X_CLIENT_OBJS = xclient.o aceclientlib.o rpcace_clnt.o rpcace_xdr.o

libacecl.a : aceclientlib.o rpcace_clnt.o rpcace_xdr.o
	ar $(AR_OPTIONS) libacecl.a $?
	if ( $(RANLIB_NEEDED) ) then ranlib libacecl.a; fi

###########################################################
########### end of the acedb truemake file ################
###########################################################
