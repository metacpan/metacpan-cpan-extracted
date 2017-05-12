include ../Makefile.version

PERL_VERSION=$(shell cat lib/C/sparse.pm | grep \$$VERSION | awk '{ print $$4; }' | sed -e "s/[;']//g" )

all:

# create a perl distribution for CPAN
dist:
	-make clean
	perl Makefile.PL
	-rm -rf sparse-$(PERL_VERSION).tar.gz ../sparse-decpp-$(VERSION).tar.gz src ../perl_dist
	mkdir -p src/
	make -C .. dist; #cp ../sparse-decpp-$(VERSION).tar.gz src/
	cd src/; tar  xvf  ../../sparse-decpp-$(VERSION).tar.gz
	rm -rf ../perl_dist/*
	cp -r . ../perl_dist
	echo "src/sparse-decpp-$(VERSION).tar.gz" > ../perl_dist/MANIFEST
	find lib/                                 >>../perl_dist/MANIFEST
	find src/                                 >>../perl_dist/MANIFEST
	find scripts/                             >>../perl_dist/MANIFEST
	echo "README"                             >>../perl_dist/MANIFEST
	echo "Makefile.PL"                        >>../perl_dist/MANIFEST
	echo "sparse.xs"                          >>../perl_dist/MANIFEST
	echo "sparse.xsh"                         >>../perl_dist/MANIFEST
	echo "sparse.pl"                          >>../perl_dist/MANIFEST
	echo "typemap"                            >>../perl_dist/MANIFEST
	echo "constdef.pl"                        >>../perl_dist/MANIFEST
	echo "test.pl"                            >>../perl_dist/MANIFEST
	perl -pi -e "s/#include \"\.\./#include \"src\/sparse-$(VERSION)/g"     ../perl_dist/sparse.xs
	perl -pi -e "s/\.\.\/libsparse.a/src\/sparse-$(VERSION)\/libsparse.a/g" ../perl_dist/Makefile.PL
	perl -pi -e "s/-I\.\./-Isrc\/sparse-$(VERSION)/g"                       ../perl_dist/Makefile.PL
	perl -pi -e "s/-L\.\/\.\./-L\.\/src\/sparse-$(VERSION)/g"               ../perl_dist/Makefile.PL
	perl -pi -e "s/-DD_USE_LIB//g"                                          ../perl_dist/Makefile.PL
	rm ../perl_dist/C-sparse-$(PERL_VERSION).tar.gz
	cd ../perl_dist; perl Makefile.PL; make dist
	cp ../perl_dist/C-sparse-$(PERL_VERSION).tar.gz .

upload: dist
	if [ -f ../../cpan-upload-do ]; then \
               ../../cpan-upload-do -verbose C-sparse-$(PERL_VERSION).tar.gz; \
        fi
