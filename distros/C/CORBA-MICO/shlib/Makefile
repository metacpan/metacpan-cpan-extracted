CC=mico-c++

all: server.so

%.pic.o : %.cc
	mico-shc++ -c $< -o $@ 

server.pic.o : hello.h

server.so: server.pic.o hello.pic.o
	rm -f $@
	mico-shld -o server hello.pic.o server.pic.o -lmico2.0.6 -lstdc++

hello.h hello.cc : hello.idl
	idl hello.idl

clean:
	rm -f hello.cc hello.h *.o *.so core *~
