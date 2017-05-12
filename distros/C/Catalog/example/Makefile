BASE = catalog_example

include ../conf/install.conf
include ../conf/mysql.conf

all:

install:
	rm -fr $(htmldir)/index.html $(cgidir)/browse $(cgidir)/admin $(cgidir)/DMOZ
	perl -p -e 's|_CGIPATH_|$(cgipath)|g' < index.html > $(htmldir)/index.html
	cp -rp admin browse DMOZ $(cgidir)
	$(MAKE) DIR=browse CGI=Catalog configure
	$(MAKE) DIR=admin CGI=Catalog configure
	$(MAKE) DIR=DMOZ CGI=dmoz BASE=dmoz configure
	$(MAKE) BASE=dmoz create
	$(MAKE) load

configure:
	cd $(cgidir)/$(DIR) ; \
	cp $(cgidir)/$(CGI) . ; \
	perl -p -e 's|^base.*|base = $(BASE)|' < $(config_dir)/mysql.conf > mysql.conf ; \
	ln -s $(config_dir)/cgi.conf . ; \
	ln -s $(config_dir)/db.conf . ; \
	ln -s $(config_dir)/install.conf . ; \
	if [ -f sqledit.conf ] ; then perl -pi -e 's|_HTMLPATH_|$(htmlpath)|' sqledit.conf ; fi

clean:

realclean:

TABLES_ALL = catalog catalog_category2category_urlcatalog catalog_category_urlcatalog catalog_entry2category_urlcatalog catalog_path_urlcatalog catalog_alpha_urlalpha urldemo
TABLES_STRUCTURE = catalog_date_urldate

load: 
	@if mysql $(cmd_opt) -e "create database $(BASE)" 2>/dev/null ; \
	then \
		mysql $(cmd_opt) $(BASE) < example.sql ; \
		mysql $(cmd_opt) -e "update catalog set updated = 0" $(BASE) < example.sql ; \
		echo "The example database has been loaded." ; \
	else \
		echo "Example not loaded because the base $(BASE) exists." ; \
	fi

create:
	@if mysql $(cmd_opt) -e "create database $(BASE)" 2>/dev/null ; \
	then \
		echo "The $(BASE) database has been created." ; \
	else \
		echo "The $(BASE) database exists." ; \
	fi

dump:
	mysqldump $(cmd_opt) $(BASE) $(TABLES_ALL) > example.sql
	mysqldump $(cmd_opt) --no-data $(BASE) $(TABLES_STRUCTURE) >> example.sql

drop:
	mysql $(cmd_opt) -e "drop database $(BASE)"

test:
