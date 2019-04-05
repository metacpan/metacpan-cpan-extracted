ENV=	  PATH=/usr/pgsql-9.4/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin
PERL5LIB= local/lib/perl5
PWD=	  `pwd`

all:

test:
	env DWARF_TEST_LEVEL=0 prove -I${PERL5LIB} -rlv t

jenkins:
	env DWARF_TEST_LEVEL=0 prove -rl -I${PERL5LIB} t

perl5lib: local/bin/cpanm
	env ${ENV} local/bin/cpanm -l local -v --installdeps .
	chmod -R ug+rw local

Net-LibIDN: local/bin/cpanm
	env ${ENV} local/bin/cpanm -L local Net::LibIDN --configure-args="--with-libidn-inc=/usr/local/include"

carton: local/bin/carton
	env ${ENV} PERL5LIB=${PWD}/${PERL5LIB} local/bin/carton install
	chmod -R ug+rw local

carton-deploy: local/bin/carton
	env ${ENV} PERL5LIB=${PWD}/${PERL5LIB} local/bin/carton install --deployment
	chmod -R ug+rw local

local/bin/carton: local/bin/cpanm
	env ${ENV} local/bin/cpanm -L local -v Carton

local/bin/cpanm:
	[ -d local/bin ] || mkdir -p local/bin
	[ -f local/bin/cpanm ] || curl -L http://xrl.us/cpanm -o local/bin/cpanm
	chmod ug+rx local/bin/cpanm
