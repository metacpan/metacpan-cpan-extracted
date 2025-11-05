# make-dist.mk. build just the shared lib from src/
PREFIX ?= /usr/local
LIBNAME = libhexsimd
VERSION = 1.0.0
SOVERSION = 1

CC ?= gcc

   # use these flags to enable specific AVX-512 subsets
	#-mno-avx512f -mavx512bw -mavx512vl -mavx512dq \
	#-DHEXSIMD_ENABLE_AVX512

CFLAGS ?= -O3 -Wall -Wextra -fPIC -fvisibility=hidden \
	-march=x86-64 -mno-avx -mno-avx2 \
	-DHEXSIMD_BUILD 

LDFLAGS ?=

all: $(LIBNAME).so

$(LIBNAME).so: $(LIBNAME).so.$(SOVERSION).$(VERSION)
	ln -sf $(LIBNAME).so.$(SOVERSION).$(VERSION) $(LIBNAME).so.$(SOVERSION)
	ln -sf $(LIBNAME).so.$(SOVERSION) $(LIBNAME).so

$(LIBNAME).so.$(SOVERSION).$(VERSION): src/hexsimd.o
	$(CC) -shared -Wl,-soname,$(LIBNAME).so.$(SOVERSION) -o $@ $^

src/hexsimd.o: src/hexsimd.c src/hexsimd.h
	$(CC) $(CFLAGS) -c $< -o $@

demo: all
	$(CC) -DTEST_HEX -o demo src/hexsimd.c -Isrc/ $(CFLAGS)

install: all
	mkdir -p $(DESTDIR)$(PREFIX)/lib
	mkdir -p $(DESTDIR)$(PREFIX)/include
	install -m 755 $(LIBNAME).so.$(SOVERSION).$(VERSION) $(DESTDIR)$(PREFIX)/lib/
	cd $(DESTDIR)$(PREFIX)/lib && ln -sf $(LIBNAME).so.$(SOVERSION).$(VERSION) $(LIBNAME).so.$(SOVERSION)
	cd $(DESTDIR)$(PREFIX)/lib && ln -sf $(LIBNAME).so.$(SOVERSION) $(LIBNAME).so
	install -m 644 src/hexsimd.h $(DESTDIR)$(PREFIX)/include/

clean:
	rm -f src/*.o $(LIBNAME).so* demo demo-2

.PHONY: all install clean
