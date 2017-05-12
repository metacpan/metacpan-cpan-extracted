RM = rm -f

# Parameters.

OBJECTS = xrt_2d.o graph_2d.o
PROGRAMS = graph_2d

# Compiler flags

CPPFLAGS = -I$(XRTHOME)/include
#CFLAGS   = -g  -Xc -dalign $(CPPFLAGS)
#LDFLAGS = -L$(XRTHOME)/lib
CC=gcc-anal
CPP=g++
CFLAGS=-g -I/usr/X11R6/include -I/usr/openwin/include -I/usr/dt/include $(CPPFLAGS) 
LDFLAGS = -L$(XRTHOME)/lib -L/usr/X11R6/lib -L/usr/openwin/lib -L/usr/dt/lib
LDLIBS = -lxrtm -lpdsutil -lXpm -lXext -lMrm -lXm -lXt -lX11 -lm \

.SUFFIXES: .cpp $(.SUFFIXES)

# Standard targets

all: graph_2d

graph_2d: xrt_2d.o graph_2d.o
	$(CC) $(CFLAGS) -o $@ graph_2d.o xrt_2d.o $(LDFLAGS) $(LDLIBS)
	$(XRTHOME)/bin/xrt_auth $@

clean:
	$(RM) *.o $(PROGRAMS) core

# Inference rules

.c.o:
	$(CC) $(CFLAGS) -c $<
.cpp.o:
	$(CPP) $(CFLAGS) -c $<

# Header dependencies

xrt_2d.o:	xrt_2d.h
