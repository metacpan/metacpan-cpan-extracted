#!/bin/bash

# Don't allow any uninitialzed variables, trace execution, and exit on any error
set -u
set -x
set -e

mkdir -p scripts
export PERL5LIB="$PWD/lib"
fatpack trace scripts.bare/dex
fatpack packlists-for $(cat fatpacker.trace) > packlists
fatpack tree $(cat packlists)
rm scripts/dex </dev/null || echo "No packed dex present"

# There's warnings here about Class::XSAccessor from Moo, but this is fine.  It'll fall back to pure perl code when that's not installed to the local perl
fatpack file scripts.bare/dex > scripts/dex
chmod a+rx-w scripts/dex

rm -rf fatpacker.trace packlists fatlib
