package #
Date::Manip::TZ::aspyon00;
# Copyright (c) 2008-2017 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Tue May 30 10:43:28 EDT 2017
#    Data version: tzdata2017b
#    Code version: tzcode2017b

# This module contains data from the zoneinfo time zone database.  The original
# data was obtained from the URL:
#    ftp://ftp.iana.org/tz

use strict;
use warnings;
require 5.010000;

our (%Dates,%LastRule);
END {
   undef %Dates;
   undef %LastRule;
}

our ($VERSION);
$VERSION='6.60';
END { undef $VERSION; }

%Dates         = (
   1    =>
     [
        [ [1,1,2,0,0,0],[1,1,2,8,23,0],'+08:23:00',[8,23,0],
          'LMT',0,[1908,3,31,15,36,59],[1908,3,31,23,59,59],
          '0001010200:00:00','0001010208:23:00','1908033115:36:59','1908033123:59:59' ],
     ],
   1908 =>
     [
        [ [1908,3,31,15,37,0],[1908,4,1,0,7,0],'+08:30:00',[8,30,0],
          'KST',0,[1911,12,31,15,29,59],[1911,12,31,23,59,59],
          '1908033115:37:00','1908040100:07:00','1911123115:29:59','1911123123:59:59' ],
     ],
   1911 =>
     [
        [ [1911,12,31,15,30,0],[1912,1,1,0,30,0],'+09:00:00',[9,0,0],
          'JST',0,[1945,8,23,14,59,59],[1945,8,23,23,59,59],
          '1911123115:30:00','1912010100:30:00','1945082314:59:59','1945082323:59:59' ],
     ],
   1945 =>
     [
        [ [1945,8,23,15,0,0],[1945,8,24,0,0,0],'+09:00:00',[9,0,0],
          'KST',0,[2015,8,14,14,59,59],[2015,8,14,23,59,59],
          '1945082315:00:00','1945082400:00:00','2015081414:59:59','2015081423:59:59' ],
     ],
   2015 =>
     [
        [ [2015,8,14,15,0,0],[2015,8,14,23,30,0],'+08:30:00',[8,30,0],
          'KST',0,[9999,12,31,0,0,0],[9999,12,31,8,30,0],
          '2015081415:00:00','2015081423:30:00','9999123100:00:00','9999123108:30:00' ],
     ],
);

%LastRule      = (
);

1;
