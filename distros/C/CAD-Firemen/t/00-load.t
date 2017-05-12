#!/usr/bin/perl -T
######################
#
#    Copyright (C) 2011  TU Clausthal, Institut für Maschinenwesen, Joachim Langenbach
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################

use Test::More tests => 6;

BEGIN {
    use_ok( 'CAD::Firemen' ) || print "Bail out!\n";
    use_ok( 'CAD::Firemen::Analyze' ) || print "Bail out!\n";
    use_ok( 'CAD::Firemen::Change' ) || print "Bail out!\n";
    use_ok( 'CAD::Firemen::Common' ) || print "Bail out!\n";
    use_ok( 'CAD::Firemen::Load' ) || print "Bail out!\n";
    use_ok( 'CAD::Firemen::Option::Check' ) || print "Bail out!\n";
}

diag( "Testing CAD::Firemen $CAD::Firemen::VERSION, Perl $], $^X" );
