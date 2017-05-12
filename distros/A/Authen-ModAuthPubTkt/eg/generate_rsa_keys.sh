#!/bin/sh

##
## Simple Example of generating RSA key pair.
## more details: https://neon1.net/mod_auth_pubtkt/install.html
##

if ! which openssl 1>/dev/null 2>/dev/null ; then
	echo "Error: can't find 'openssl' executable in your \$PATH." >&2 ;
	exit 1
fi

openssl genrsa -out rsa.privkey.pem 1024 || exit 1
openssl rsa -in rsa.privkey.pem -out rsa.pubkey.pem -pubout || exit 1

echo
echo "RSA keys generated:"
echo " private: rsa.privkey.pem"
echo " public:  rsa.pubkey.pem"
echo
