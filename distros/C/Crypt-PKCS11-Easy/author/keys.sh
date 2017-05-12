#!/bin/bash

# This generates the softhsm2 tokens. It requires softhsm2-util, pkcs11-tool from OpenSC and openssl commands
# WARNING: It is destructive!
set -e

export SOFTHSM2_CONF="author/softhsm2.conf"

TOKEN_DIR="tokens";
PKCS11TOOL_CMD="pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so --login --pin 1234 -v"

rm -rfv $TOKEN_DIR && mkdir $TOKEN_DIR

softhsm2-util --init-token --pin 1234 --so-pin 123456 --slot 0 --label test_keys_1

# add an RSA 1024 private key just for signing and the public key for verifying
openssl rsa -in t/keys/1024_sign.pem -outform DER -out t/keys/1024_sign.der
$PKCS11TOOL_CMD --usage-sign --write-object t/keys/1024_sign.der -y privkey --label 'signing_key' --id 0001

openssl rsa -pubin -in t/keys/1024_sign_pub.pem -outform DER -out t/keys/1024_sign_pub.der
$PKCS11TOOL_CMD --usage-sign --write-object t/keys/1024_sign_pub.der -y pubkey --label 'signing_key' --id 0001



# add a RSA 1024 private and public keys for encryption/decryption
openssl rsa -in t/keys/1024_enc.pem -outform DER -out t/keys/1024_enc.der
$PKCS11TOOL_CMD --usage-decrypt --write-object t/keys/1024_enc.der -y privkey --label 'encryption_key' --id 0002

openssl rsa -pubin -in t/keys/1024_enc_pub.pem -outform DER -out t/keys/1024_enc_pub.der
$PKCS11TOOL_CMD --usage-decrypt --write-object t/keys/1024_enc_pub.der -y pubkey --label 'encryption_key' --id 0002

echo -e "\n ****** Listing objects ******\n"

$PKCS11TOOL_CMD --list-slots
$PKCS11TOOL_CMD --list-objects

# $PKCS11TOOL_CMD -t

cd author; tar -cvzf ../t/data/tokens.tar.gz tokens
