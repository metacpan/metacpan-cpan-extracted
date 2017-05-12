CC=		gcc
CFLAGS=		-g -Wall -O2 -fPIC
DFLAGS=		-D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE -D_USE_KNETFILE -D_CURSES_LIB=1
INCLUDES=
LIBPATH=
PROG=		bam2bedgraph

.SUFFIXES:.c .o
.PHONY: all lib

.c.o:
		$(CC) -c $(CFLAGS) $(DFLAGS) $(INCLUDES) $< -o $@

all:$(PROG)

bam2bedgraph: bam2bedgraph.o
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS) $(LIBPATH) -lbam -lpthread -lm -lz

clean:
	rm -f *.o $(PROG)

