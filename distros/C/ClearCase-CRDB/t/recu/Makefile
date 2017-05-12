## This makefile is designed to work the same on UNIX and Windows
## as long as clearmake -C gnu is in use. It exists only to generate
## some derived objects for subsequent testing.

include ../macros.mk

rx1: r1/librecu1.so r2/librecu2.so
	@$(DOITALL)

r1/librecu1.so:
	cd r1 && $(MAKE) librecu1.so

r2/librecu2.so:
	cd r2 && $(MAKE) librecu2.so
