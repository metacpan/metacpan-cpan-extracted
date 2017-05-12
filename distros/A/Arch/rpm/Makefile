version = 0.5.2
release = 0.`date +%Y%m%d`
cparams = ''  # configure params, not really used
mparams = ''  # make params, like: 'CFLAGS="-O2"'

package = Arch
top_srcdir = ..

rpm: $(package).spec
	@\
	version=$(version); \
	release=$(release); \
	cparams='$(cparams)'; \
	mparams='$(mparams)'; \
	tarball=$(package)-$$version.tar.gz; \
	tarball_full=`cd $(top_srcdir) && pwd`/$$tarball; \
	if [ ! -f $$tarball_full ]; then echo "No $$tarball"; exit -1; fi; \
	ln -sf $$tarball_full /tmp/$$tarball || exit -1; \
	echo ""; \
	echo "==== Creating rpm from /tmp/$$tarball, release $$release ===="; \
	echo ""; \
	sleep 3; \
	sed < $(package).spec > tmp-$(package).spec \
		-e "s/%define ver /&$$version  %define old_ver /" \
		-e "s/%define rel /&$$release  %define old_rel /" \
		-e "s/%define c_p /&$$cparams  %define old_c_p /" \
		-e "s/%define m_p /&$$mparams  %define old_m_p /" \
	; \
	rpmbuild -ba tmp-$(package).spec --clean --target=noarch-perl-linux; \
	rm /tmp/$$tarball; \
	rm tmp-$(package).spec
