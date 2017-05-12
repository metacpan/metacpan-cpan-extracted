#!/usr/bin/perl -w

# Copyright 2007, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Archive::Zip qw(:CONSTANTS :ERROR_CODES);
use IO::String;
use IO::File;

# test writing to a scalar
my $zipContents = '';
my $SH = IO::String->new($zipContents);

my $zip = Archive::Zip->new();
my $member = $zip->addString('a' x 300, 'bunchOfAs.txt');
$member->desiredCompressionMethod(COMPRESSION_DEFLATED);
$member = $zip->addString('b' x 300, 'bunchOfBs.txt');
$member->desiredCompressionMethod(COMPRESSION_DEFLATED);
my $status = $zip->writeToFileHandle( $SH );

my $file = IO::File->new('test.zip', 'w');
binmode($file);
$file->print($zipContents);
$file->close();

