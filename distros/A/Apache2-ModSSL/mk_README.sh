#!/bin/bash

(perldoc -tU ./lib/Apache2/ModSSL.pm
 perldoc -tU $0
) >README

exit 0

=head1 INSTALLATION

 perl Makefile.PL -apxs /path/to/apxs
 make
 make test
 make install

=head1 DEPENDENCIES

mod_perl 2.0.0-RC5,
httpd 2.0.52,
perl 5.8.0

=cut