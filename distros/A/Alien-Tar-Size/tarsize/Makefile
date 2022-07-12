
CFLAGS=-Wall -fPIC
OPTIMIZE:=-O2
LDFLAGS=-shared
LDLIBS=-ldl

all: tarsize.so

tarsize.so: tarsize.c
	$(CC) $(CFLAGS) $(OPTIMIZE) $(LDFLAGS) $(LDLIBS) -o $@ $^

clean:
	rm -f tarsize.so

.PHONY: clean all