#!/bin/sh

openssl req -x509  -nodes \
   -newkey rsa:2048 \
   -sha256 \
   -days 365 \
   -subj "/C=IT/ST=Roma/L=Roma/O=Pinco Pals/CN=$BOT_IP" \
   -keyout server.key \
   -out server.crt
