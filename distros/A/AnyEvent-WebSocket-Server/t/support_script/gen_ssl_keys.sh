#!/bin/sh

this_dir=`dirname $0`

keybase="$1"

if [ "x$keybase" = "x" ]; then
    keybase="ssl_test"
fi

if [ -r "$keybase.key" ]; then
    echo "$keybase.key already exists. abort."
    exit 1
fi

if [ -r "$keybase.crt" ]; then
    echo "$keybase.crt already exists. abort."
    exit 1
fi

config_file="$this_dir/cert_config"

echo "Generating $keybase.key"
openssl genrsa 3072 > $keybase.key

csrC=JP
csrST=Kanagawa
csrO=Acme
csrCN="127.0.0.1"
echo "Generating $keybase.crt"
openssl req -new -key $keybase.key \
        -subj "/C=$csrC/ST=$csrST/L=/O=$csrO/OU=/CN=$csrCN/emailAddress=" \
    | openssl x509 -days 100000 -req -signkey $keybase.key > $keybase.crt

echo "Generating $keybase.combined.key"
cat $keybase.key $keybase.crt > $keybase.combined.key
