.SUFFIXES:	.ec
# OS type
OSTYPE = -DHPUX
# Other OSes ???
#OSTYPE = 

CFLAGS=-O -I$(INFORMIXDIR)/incl/esql $(OSTYPE)

SRCS=agent.ec net.c
INFORMIXC=gcc
CC=cc -Ae
CC=gcc
# For Informix 7.x
LINKLIB= -lsql -los -lasf -lgen -lnetstub
# For Informix 5.x
LINKLIB= -lsql -los -lgen -lfesql

OBJS=agent.o net.o
#OBJCL=a.o te.o

all:	dbagent

dbagent:	$(OBJS)
	$(CC) $(OBJS) -o $@ -L$(INFORMIXDIR)/lib \
	-L$(INFORMIXDIR)/lib/esql $(LINKLIB)
	strip $@

.ec.c:
	esql -e $<

#te: $(OBJCL)
#	$(CC) $(OBJCL) -o $@ -L$(INFORMIXDIR)/lib -L$(INFORMIXDIR)/lib/esql \
#	$(LINKLIB)

clean:
	rm -f *.o dbagent *~ a.c
