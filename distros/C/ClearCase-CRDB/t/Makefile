## This makefile is designed to work the same on UNIX and Windows,
## as long as clearmake -C gnu is in use. It exists only to generate
## some derived objects for subsequent testing.

include macros.mk

prog1: libcrdb1.a libcrdb2.a
	@$(DOITALL)

libcrdb1.a: crdba.o crdbb.o
	@$(SAYIT)
	@$(MAKEIT)

libcrdb2.a: crdbc.o
	@$(SAYIT)
	@$(MAKEIT)
