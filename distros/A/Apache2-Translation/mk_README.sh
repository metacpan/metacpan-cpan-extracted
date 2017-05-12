#!/bin/bash

perl -pe '/^=head1 DESCRIPTION/ and print <STDIN>' lib/Apache2/Translation.pod >README.pod <<EOF
=head1 INSTALLATION

 perl Makefile.PL
 make
 make test
 make install

EOF

perldoc -tU README.pod >README
rm README.pod