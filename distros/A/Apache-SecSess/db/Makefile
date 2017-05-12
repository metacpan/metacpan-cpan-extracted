#
# Makefile - manage account DB
#
# $Id: Makefile,v 1.5 2002/05/19 05:15:31 pliam Exp $
#

help:
	@echo type "'make init'" to initialize account database

DBNAME=secsess
DBUSER=pliam
DBPW=blah
DBFILE=dbilogin.txt
init: dbfile
	psql -d $(DBNAME) < schema.sql
	./initdb

dbfile:
	echo dbi:Pg:dbname=$(DBNAME) > $(DBFILE)
	echo $(DBUSER) >> $(DBFILE)
	echo $(DBPW) >> $(DBFILE)

test:
	./testdb

clean:
	psql -d $(DBNAME) < cleanup.sql
	rm -f $(DBFILE)
