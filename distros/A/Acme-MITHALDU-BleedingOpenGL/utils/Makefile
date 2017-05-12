#!make

# Default values for this Makefile
GLUT_DEF=HAVE_FREEGLUT
GLUT_LIB=glut

# Key OpenGL compile/link locations
INC=-I/usr/include -I/usr/X11R6/include -I/usr/local/include -I/usr/openwin/include
LIBS=-L/usr/lib -L/usr/X11R6/lib -L/usr/local/lib -L/usr/openwin/lib -L/usr/lib/xorg/modules -L/usr/X11R6/lib/modules -L/usr/lib/xorg/modules/extensions -L/usr/X11R6/lib/modules/extensions

# Compile command
CC=cc
CCFLAGS=${INC} -D${GLUT_DEF}

# Link command
LINK=cc
LDFLAGS=${LIBS} -lGL -l${GLUT_LIB}
EXTRALIBS=-lGLU -lXi -lXmu -lXext -lX11 -lm


all: glversion.txt

glversion.txt: glversion
	./glversion > glversion.txt

glversion: glversion.o
	${LINK} glversion.o ${LDFLAGS} ${EXTRALIBS} -o glversion
	chmod u+x glversion

clean:
	rm -f glversion.txt
	rm -f glversion
	rm -f glversion.o

.c.o:
	${CC} ${CCFLAGS} -c $<
