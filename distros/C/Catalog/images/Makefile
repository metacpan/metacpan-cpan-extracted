include ../conf/install.conf

all: ../doc/images/.stone

../doc/images/.stone:
	for i in *.gif ; do \
	( cd ../doc/images ; rm -f $$i ; cp ../../images/$$i . ) \
	done
	touch ../doc/images/.stone

install:
	dir=$(htmldir)/images ; \
	if [ ! -d $$dir ] ; then mkdir -p $$dir ; fi ; \
        for i in *.gif ; do \
	 if [ ! -f $$dir/$$i ] ; \
          then cp $$i $$dir ; \
          chown $(userid) $$dir/$$i; \
         fi ; \
	done

clean:
	rm -f ../doc/images/.stone

realclean:
	for i in *.gif ; do \
	( cd ../doc/images ; rm -f $$i ) \
	done

test:
