#!/usr/bin/perl -w

# Copyright 2008, 2010, 2016 Kevin Ryde

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
use File::Slurp 'slurp';
use Data::Dumper;

my $filename = $ENV{'HOME'}.'/chart/samples/float/CML.zip';
#  $filename = 'test.zip';

my $zipContents = slurp ($filename);
my $SH = IO::String->new($zipContents);

#my $zip = Archive::Zip->new($filename);
my $zip = Archive::Zip->new();

#$zip->read($filename);

$zip->readFromFileHandle ($SH);

my @members = $zip->members;
#print Dumper (\@members);

my $m = $members[0];
print Dumper (\$m);

my $cont = $m->contents;
print Dumper (\$cont);

# my $member = $zip->addString('a' x 300, 'bunchOfAs.txt');
# $member->desiredCompressionMethod(COMPRESSION_DEFLATED);
# $member = $zip->addString('b' x 300, 'bunchOfBs.txt');
# $member->desiredCompressionMethod(COMPRESSION_DEFLATED);
# my $status = $zip->writeToFileHandle( $SH );

# my $file = IO::File->new('test.zip', 'w');
# binmode($file);
# $file->print($zipContents);
# $file->close();

