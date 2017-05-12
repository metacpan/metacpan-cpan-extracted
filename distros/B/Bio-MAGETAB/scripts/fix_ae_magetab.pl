#!/usr/bin/env perl
#
# Copyright 2009-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: fix_ae_magetab.pl 333 2010-06-02 16:41:31Z tfrayner $

# This is a simple utility script which can be used to convert the
# current ArrayExpress implementation of the MAGE-TAB format into
# something that the MAGE-TAB Utilities API can reliably read. The
# changes are principally to bring the format into line with the
# MAGE-TAB v1.1 specification, and to fix some common errors. The aim
# is that the output of this script can be parsed using the MAGE-TAB
# Reader classes running in "strict" mode.

use strict;
use warnings;

use Getopt::Long;
use Bio::MAGETAB::Util::RewriteAE;

my $VERSION = 0.01;

my ( $idf, $sdrf, $want_version, $want_help );

GetOptions(
    "i|idf=s"      => \$idf,
    "s|sdrf=s"     => \$sdrf,
    "v|version"    => \$want_version,
    "h|help"       => \$want_help,
);

if ( $want_version ) {
    print (<<"OUTPUT");
This is fix_ae_magetab.pl version $VERSION
OUTPUT

    exit 255;
}

if ( $want_help || ! ( $idf && $sdrf ) ) {
    print (<<"USAGE");
Usage: fix_ae_magetab.pl -i <idf> -s <sdrf>
USAGE

    exit 255;
}

my $rw = Bio::MAGETAB::Util::RewriteAE->new();
$rw->rewrite_sdrf( $sdrf );
$rw->rewrite_idf( $idf );
