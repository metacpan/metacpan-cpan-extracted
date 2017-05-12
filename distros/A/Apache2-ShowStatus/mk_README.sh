#!/bin/bash

(perldoc -tU ./lib/Apache2/ShowStatus.pm
 perldoc -tU $0
) >README

exit 0

=head1 INSTALLATION

 perl Makefile.PL
 make
 make test
 make install

=head1 DEPENDENCIES

=over 4

=item *

Sys::Proctitle

=item *

perl 5.8.0

=back

=cut