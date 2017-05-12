# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Alien-SFML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('Alien::SFML') }

#########################

# Not all that much else that needs testing, really.

=head1 COPYRIGHT

 ############################
 # Copyright 2013 Jake Bott #
 #=>----------------------<=#
 #   All Rights Reserved.   #
 #   Part of Alien::SFML.   #
 #=>----------------------<=#
 #   See the LICENCE file   #
 ############################

=cut
