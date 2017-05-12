all: build_pl
	./Build

build_pl:
	perl Build.PL --prefix=$(PREFIX)

clean: build_pl
	./Build clean
	[ ! -d _build ]     || rm -rf _build
	[ ! -e rpmbuild ]   || rm -rf rpmbuild
	[ ! -e Build ]      || rm -f Build
	touch build.tap ; rm build.tap

install: all
	./Build install

check:

test: all
	./Build test verbose=1 | tee "build.tap"

manifest: Build.PL lib Makefile eg t README MANIFEST Changes
	find . -type f | grep -vE 'DS_Store|git|_build|META.yml|Build|cover_db|svn|blib|\~|\.old|CVS|Makefile|rpmbuild' | sed 's/^\.\///' | sort > MANIFEST
	echo "Makefile"    >> MANIFEST
	echo "Build.PL"    >> MANIFEST

dist: all manifest
	./Build dist
