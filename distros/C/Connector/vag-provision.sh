#!/bin/bash

sudo apt-get install -y git libssl-dev zlib1g zlib1g-dev
\curl -L https://install.perlbrew.pl | bash
perlbrew init
if ! grep -q perlbrew ~/.profile; then
    echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.profile
fi
