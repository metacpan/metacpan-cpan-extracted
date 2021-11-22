package #
Date::Manip::TZ::amguya00;
# Copyright (c) 2008-2021 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Nov 15 11:13:45 EST 2021
#    Data version: tzdata2021e
#    Code version: tzcode2021e

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
$VERSION='6.86';
END { undef $VERSION; }

%Dates         = (
   1    =>
     [
        [ [1,1,2,0,0,0],[1,1,1,20,7,21],'-03:52:39',[-3,-52,-39],
          'LMT',0,[1911,8,1,3,52,38],[1911,7,31,23,59,59],
          '0001010200:00:00','0001010120:07:21','1911080103:52:38','1911073123:59:59' ],
     ],
   1911 =>
     [
        [ [1911,8,1,3,52,39],[1911,7,31,23,52,39],'-04:00:00',[-4,0,0],
          '-04',0,[1915,3,1,3,59,59],[1915,2,28,23,59,59],
          '1911080103:52:39','1911073123:52:39','1915030103:59:59','1915022823:59:59' ],
     ],
   1915 =>
     [
        [ [1915,3,1,4,0,0],[1915,3,1,0,15,0],'-03:45:00',[-3,-45,0],
          '-0345',0,[1975,8,1,3,44,59],[1975,7,31,23,59,59],
          '1915030104:00:00','1915030100:15:00','1975080103:44:59','1975073123:59:59' ],
     ],
   1975 =>
     [
        [ [1975,8,1,3,45,0],[1975,8,1,0,45,0],'-03:00:00',[-3,0,0],
          '-03',0,[1992,3,29,3,59,59],[1992,3,29,0,59,59],
          '1975080103:45:00','1975080100:45:00','1992032903:59:59','1992032900:59:59' ],
     ],
   1992 =>
     [
        [ [1992,3,29,4,0,0],[1992,3,29,0,0,0],'-04:00:00',[-4,0,0],
          '-04',0,[9999,12,31,0,0,0],[9999,12,30,20,0,0],
          '1992032904:00:00','1992032900:00:00','9999123100:00:00','9999123020:00:00' ],
     ],
);

%LastRule      = (
);

1;
