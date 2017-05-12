#!/bin/sh

##
## Simple Example of generating RSA key pair.
## more details: https://neon1.net/mod_auth_pubtkt/install.html
##

if ! which openssl 1>/dev/null 2>/dev/null ; then
	echo "Error: can't find 'openssl' executable in your \$PATH." >&2 ;
	exit 1
fi

openssl dsaparam -out dsaparam.pem 1024 || exit 1
openssl gendsa -out dsa.privkey.pem dsaparam.pem || exit 1
openssl dsa -in dsa.privkey.pem -out dsa.pubkey.pem -pubout || exit 1
rm dsaparam.pem || exit 1

echo
echo "DSA keys generated:"
echo " private: dsa.privkey.pem"
echo " public:  dsa.pubkey.pem"
echo
