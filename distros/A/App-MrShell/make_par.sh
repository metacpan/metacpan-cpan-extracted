#!/bin/bash

version=$(perl -MMrShell -e 'print $App::MrShell::VERSION')
platform=$(uname -m)

perl Makefile.PL
make

deps="-M POE::Pipe -M POE::Filter -M POE::Wheel::Run"

pp $deps -I blib/lib -o mrsh-$version-$platform.par mrsh
