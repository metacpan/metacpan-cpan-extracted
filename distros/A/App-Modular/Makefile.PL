#!/usr/bin/perl -w
#----------------------------------------------------------------------------
#   Modularizer - perl program modularization framewok
#   Modularizer.pm: module management class
#
#   Copyright (c) 2003-2008 Baltasar Cevc
#
#   Thanx to http://former03.de for paying me for the future 
#   development ;-)
#
#   This code is released under the L<perlartistic> Perl Artistic
#   License, which can should be accessible via the C<perldoc
#   perlartistic> command and the file COPYING provided with this
#
#   DISCLAIMER: THIS SOFTWARE AND DOCUMENTATION IS PROVIDED "AS IS," AND
#   COPYRIGHT HOLDERS MAKE NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO, WARRANTIES OF MERCHANTABILITY
#   OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF THE SOFTWARE
#   OR DOCUMENTATION WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS,
#   TRADEMARKS OR OTHER RIGHTS.
#   IF YOU USE THIS SOFTWARE, YOU DO SO AT YOUR OWN RISK.
#
#   See this internet site for more details: http://technik.juz-kirchheim.de/
#
#   Creation:       07.06.04    bc
#   Last Update:    06.04.08    bc
#   Version:         0. 1. 22 
# ----------------------------------------------------------------------------
use strict;
use warnings;

# files needed for CPAN
#Changes
#README
#INSTALL
#MANIFEST

use ExtUtils::MakeMaker;

WriteMakefile (
   NAME                => 'App::Modular',
   VERSION_FROM        => 'lib/App/Modular.pm',
   PREREQ_PM           => {'Class::Singleton' => '1.03'}
);
