
CC=gcc
CFLAGS=-Wall -g -DLAYER1 -DLAYER2 -DLAYER3

all: mpglib


*.o: mpg123.h mpglib.h

mpglib: layer1.o layer2.o common.o dct64_i386.o decode_i386.o layer3.o tabinit.o interface.o main.o
	$(CC) -o mpglib \
		common.o dct64_i386.o decode_i386.o layer3.o \
		tabinit.o interface.o main.o layer2.o layer1.o -lm

clean:
	rm *.o mpglib


