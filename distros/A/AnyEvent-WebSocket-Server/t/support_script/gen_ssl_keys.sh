#!/bin/sh

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

echo "Generating $keybase.key"
openssl genrsa 2024 > $keybase.key

echo "Generating $keybase.crt"
openssl req -new -key $keybase.key | openssl x509 -days 100000 -req -signkey $keybase.key > $keybase.crt

echo "Generating $keybase.combined.key"
cat $keybase.key $keybase.crt > $keybase.combined.key
