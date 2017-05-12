######################################################################
# Acme::Prereq::A -- 2005, Mike Schilli <m@perlmeister.com>
######################################################################

###########################################
package Acme::Prereq::A;
###########################################

use strict;
use warnings;

our $VERSION = "0.01";

1;

__END__

=head1 NAME

Acme::Prereq::A - Module for testing CPAN module prerequisites

=head1 SYNOPSIS

    use Acme::Prereq::A;

=head1 DESCRIPTION

Acme::Prereq::A does nothing, however, it requires 
Acme::Prereq::B to be installed. It can be used for
testing (circular) dependencies among CPAN modules.

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <mschilli@perlmeister.com>
