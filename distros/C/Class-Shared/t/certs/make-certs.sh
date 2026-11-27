#!/bin/sh
# Regenerate the certificates the TCP tests use.  They are test fixtures, not
# secrets: every key here is in the repository, so never use any of it for
# anything real.  They are long-lived (10 years) so the tests do not rot.
#
#   ca               signs the server and client the tests trust
#   other-ca         signs the impostors the tests expect to be refused
#   server/client    the pair a working frontend and backend use
#   other-server     a server certificate the tests' CA does not sign by
#   other-client     a client certificate the backend's CA does not sign
#
# server certificates carry DNS:localhost and IP:127.0.0.1, because the tests
# connect to 127.0.0.1 and IO::Socket::SSL checks the hostname as well as the
# chain.
set -eu

cd "$(dirname "$0")"

rm -f ./*.pem ./*.srl

cat > server.ext <<'EOF'
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:localhost,IP:127.0.0.1
EOF

cat > client.ext <<'EOF'
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=clientAuth
EOF

cat > ca.ext <<'EOF'
basicConstraints=critical,CA:TRUE
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
EOF

ca () {
	openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
		-keyout "$1-key.pem" -out "$1.pem" -subj "/CN=$2" \
		-addext "basicConstraints=critical,CA:TRUE" \
		-addext "keyUsage=critical,keyCertSign,cRLSign" \
		-addext "subjectKeyIdentifier=hash" >/dev/null 2>&1
}

leaf () {
	# leaf NAME SIGNING-CA CN EXTENSIONS
	openssl req -new -newkey rsa:2048 -nodes \
		-keyout "$1-key.pem" -out "$1.csr" -subj "/CN=$3" >/dev/null 2>&1
	openssl x509 -req -in "$1.csr" -CA "$2.pem" -CAkey "$2-key.pem" \
		-CAcreateserial -days 3650 -out "$1.pem" -extfile "$4" >/dev/null 2>&1
	rm -f "$1.csr"
}

ca ca 'Class Shared test CA'
ca other-ca 'Class Shared untrusted CA'

leaf server ca localhost server.ext
leaf client ca 'class-shared test client' client.ext
leaf other-server other-ca localhost server.ext
leaf other-client other-ca 'class-shared untrusted client' client.ext

rm -f ./*.srl
chmod 644 ./*.pem
