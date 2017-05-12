#
# Makefile - make certs w/ mkcerts
# 
# $Id: Makefile,v 1.1 2002/04/20 22:58:46 pliam Exp $
# 

#
# config
#
APACHE=/usr/local/apache
CACERT=acme-ca.crt
CRTPATH=$(APACHE)/conf/ssl.crt
KEYPATH=$(APACHE)/conf/ssl.key
DOCROOT=$(APACHE)/ht/adam.acme.com

#
# targets
# 
all: scratch

# make a CA from scratch
scratch:
	(umask 066; ./mkcerts -d -n)

# add signed certs to existing ones, encrypting the server keys
append: 
	(umask 066; ./mkcerts -d -e)

# assumes that this is run in $(KEYPATH)
install:
	install -m 644 *-cert.pem $(CRTPATH)
	install -m 644 $(CACERT) $(CRTPATH)
	install -m 644 $(CACERT) $(DOCROOT)

install-key:
	install -m 600 *-key.pem $(KEYPATH)

clean:
	rm -f *.pem *.key *.p12 *.srl $(CACERT)
	rm -f *~
