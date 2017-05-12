.PHONY: all clean install uninstall

DESTDIR ?= /usr/local

CFLAGS = -Wall -Wextra -Werror -fno-common

all: lib__cpu_model.a

lib__cpu_model.a: cpu_model.o
	 $(AR) rcs $@ $<

install :
	mkdir -p $(DESTDIR)/lib/pkgconfig
	sed -e 's|^prefix=.*$$|prefix=$(DESTDIR)|' __cpu_model.pc \
		> $(DESTDIR)/lib/pkgconfig/__cpu_model.pc
	cp lib__cpu_model.a $(DESTDIR)/lib/
	@echo "installed archive."


uninstall :
	rm -f $(DESTDIR)/lib/pkgconfig/__cpu_model.pc
	rm -f $(DESTDIR)/lib/lib__cpu_model.a
	@echo "archive removed."

clean:
	rm -rf *.o *.a
	@echo "removed all generated files."
