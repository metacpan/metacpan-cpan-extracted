RM = rm -f

# Parameters.

OBJECTS = xrt3d.o graph_3d.o
PROGRAMS = graph_3d

# Compiler flags

CPPFLAGS = -I$(XRTHOME)/include
CC=gcc
CPP=g++
CFLAGS=-g -I/usr/X11R6/include -I/usr/openwin/include -I/usr/dt/include $(CPPFLAGS) 
LDFLAGS = -L$(XRTHOME)/lib -L/usr/X11R6/lib -L/usr/openwin/lib -L/usr/dt/lib
LDLIBS = -lxrt3d -lpdsutil -lXpm -lMrm -lXext -lXm -lXt -lX11 -lm 
.SUFFIXES: .cpp $(.SUFFIXES)

# Standard targets

all: graph_3d

graph_3d: xrt3d.o graph_3d.o
	$(CC) $(CFLAGS) -o $@ graph_3d.o xrt3d.o $(LDFLAGS) $(LDLIBS)
	$(XRTHOME)/bin/xrt_auth $@

clean:
	$(RM) *.o $(PROGRAMS) core

# Inference rules

.c.o:
	$(CC) $(CFLAGS) -c $<
.cpp.o:
	$(CPP) $(CFLAGS) -c $<

# Header dependencies

xrt3d.o:	xrt3d.h
