#!/bin/bash

# Generate RSA key pair for OIDC signing
# This script creates a 2048-bit RSA key pair for use with the OIDC example

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_DIR="$SCRIPT_DIR/keys"

echo "Generating RSA key pair for OIDC..."

# Generate private key
openssl genrsa -out "$KEYS_DIR/private.pem" 2048 2>/dev/null

# Extract public key
openssl rsa -in "$KEYS_DIR/private.pem" -pubout -out "$KEYS_DIR/public.pem" 2>/dev/null

echo "Keys generated successfully:"
echo "  Private key: $KEYS_DIR/private.pem"
echo "  Public key:  $KEYS_DIR/public.pem"
