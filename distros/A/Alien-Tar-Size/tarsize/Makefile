
CFLAGS=-Wall -fPIC
OPTIMIZE:=-O2
LDFLAGS=-shared

all: tarsize.so

# some operating systems don't have libdl (such as bsds).
# all the libc's nowadays include dlsym anyways, with libdl just being a placeholder
# however, `man dlsym` says to link with `-ldl` for me, so
# first try to link with it otherwise try without
tarsize.so: tarsize.c
	$(CC) $(CFLAGS) $(OPTIMIZE) $(LDFLAGS) -ldl -o $@ $^ || $(CC) $(CFLAGS) $(OPTIMIZE) $(LDFLAGS) -o $@ $^

clean:
	rm -f tarsize.so

.PHONY: clean all