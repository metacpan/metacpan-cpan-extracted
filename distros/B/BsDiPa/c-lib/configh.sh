#!/bin/sh -

VERSION=0.8.0
CONTACT='Steffen Nurpmeso <steffen@sdaoden.eu>'

while [ $# -gt 0 ]; do
	eval $1
	shift
done

{
	echo '#ifndef s__BSDIPA_CONFIG_H'
	echo '#define s__BSDIPA_CONFIG_H'
	echo '#define s_BSDIPA_VERSION "'"$VERSION"'"'
	echo '#define s_BSDIPA_CONTACT "'"$CONTACT"'"'
	[ -n "$s_BSDIPA_32" ] && echo '#define s_BSDIPA_32' || echo '#undef s_BSDIPA_32'
	[ -n "$s_BSDIPA_MAGIC_WINDOW" ] &&
		echo '#define s_BSDIPA_MAGIC_WINDOW '"$s_BSDIPA_MAGIC_WINDOW" ||
		echo '#undef s_BSDIPA_MAGIC_WINDOW'
	echo '#endif'
} > ./s-bsdipa-config.h

# s-itt-mode
