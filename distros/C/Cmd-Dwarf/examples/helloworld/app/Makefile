S2PAN=    https://s2pan.s2factory.co.jp/
ENV=	  PATH=/usr/pgsql-9.4/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin
MIR=	  --mirror=${S2PAN} --mirror=http://www.cpan.org/ --mirror-only
PERL5LIB= local/lib/perl5
PWD=	  `pwd`

all:

test:
	env DWARF_TEST_LEVEL=0 prove -I${PERL5LIB} -rlv t

jenkins:
	env DWARF_TEST_LEVEL=0 prove -rl -I${PERL5LIB} t

perl5lib: local/bin/cpanm
	local/bin/cpanm -l local -v ${MIR} --installdeps .
	chmod -R ug+rw local

Net-LibIDN: local/bin/cpanm
	local/bin/cpanm -L local Net::LibIDN --configure-args="--with-libidn-inc=/usr/local/include"

carton: local/bin/carton
	env ${ENV} PERL_CARTON_MIRROR=${S2PAN} PERL5LIB=${PWD}/${PERL5LIB} local/bin/carton install
	chmod -R ug+rw local

carton-deploy: local/bin/carton
	env ${ENV} PERL_CARTON_MIRROR=${S2PAN} PERL5LIB=${PWD}/${PERL5LIB} local/bin/carton install --deployment
	chmod -R ug+rw local

local/bin/carton: local/bin/cpanm
	local/bin/cpanm -L local -v Carton

local/bin/cpanm:
	[ -d local/bin ] || mkdir -p local/bin
	[ -f local/bin/cpanm ] || curl -L http://xrl.us/cpanm -o local/bin/cpanm
	chmod ug+rx local/bin/cpanm