#!/bin/bash

perl -pe '/^=head1 DESCRIPTION/ and print <STDIN>' lib/Apache2/POST200.pod >README.pod <<EOF
=head1 INSTALLATION

 perl Makefile.PL
 make
 make test
 make install

=head1 DEPENDENCIES

=over 4

=item mod_perl2

=back

EOF

perldoc -tU README.pod >README
rm README.pod