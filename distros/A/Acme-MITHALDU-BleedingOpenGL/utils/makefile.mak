#!nmake

CC=cl.exe
CCFLAGS=/nologo /D "WIN32" /c 
LINK=link.exe
LDFLAGS=/nologo /subsystem:console /incremental:no /machine:I386 


!if "$(GLUT_DEF)" == "HAVE_FREEGLUT"
GLUT_LIB="..\FreeGLUT\freeglut"
!else
GLUT_LIB="glut32"
!endif


all: glversion.txt

clean:
	if exist glversion.txt del glversion.txt
	if exist glversion.exe del glversion.exe
	if exist glversion.obj del glversion.obj

glversion.txt: glversion.exe
	glversion > glversion.txt

glversion.exe: glversion.obj
	$(LINK) $(LDFLAGS) /defaultlib:$(GLUT_LIB).lib /out:"glversion.exe" glversion.obj

glversion.obj: glversion.c makefile.mak
	$(CC) $(CCFLAGS) /D $(GLUT_DEF) glversion.c
