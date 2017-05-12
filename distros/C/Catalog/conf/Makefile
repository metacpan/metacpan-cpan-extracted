include install.conf

all:

install:
	-for i in *.conf ; do \
	 if [ ! -f $(config_dir)/$$i ] ; \
         then \
          cp $$i $(config_dir) ; \
          $(chown) $(userid) $(config_dir)/$$i ; \
         else \
          echo $$i already installed - not overwritten ; \
          diff $$i $(config_dir)/$$i ; \
         fi ; \
	done	

clean:
	rm -f *~

realclean: clean
	mv install.conf.orig install.conf
	mv db.conf.orig db.conf
	mv mysql.conf.orig mysql.conf

test:
