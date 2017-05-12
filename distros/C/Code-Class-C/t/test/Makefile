NAME = dummy
#SRC  = $(wildcard *.c)
SRC  = main.c

DEBUG = -DDEBUG

CC      = gcc 
CCPARAM = -relaxed_ansi -Wall -Werror -lm -lz 

OS = $(shell echo -n $(shell uname -a | sed 's/ .*//g'))

PARAM_Darwin  = -framework GLUT -framework OpenGL -lobjc -framework FreeType -I/usr/X11/include/freetype2 -I/usr/X11/include
PARAM_Linux   = -lm -lglut -lGL -lGLU $(DEBUG) -lfreetype -I/usr/include/freetype2
PARAM_        = -lm -lglut -lGL -lGLU $(DEBUG) -lfreetype -I/usr/include/freetype2

all: $(NAME)

$(NAME): $(SRC)
	$(CC) -g $(CCPARAM) $(PARAM_$(OS)) -D$(OS) -o $(NAME) $(SRC)

doc:
	doxygen Doxyfile

clean:
	rm -rf *.o
