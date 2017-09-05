package #
Date::Manip::TZ::amguya00;
# Copyright (c) 2008-2017 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Tue May 30 10:43:29 EDT 2017
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
        [ [1,1,2,0,0,0],[1,1,1,20,7,20],'-03:52:40',[-3,-52,-40],
          'LMT',0,[1915,3,1,3,52,39],[1915,2,28,23,59,59],
          '0001010200:00:00','0001010120:07:20','1915030103:52:39','1915022823:59:59' ],
     ],
   1915 =>
     [
        [ [1915,3,1,3,52,40],[1915,3,1,0,7,40],'-03:45:00',[-3,-45,0],
          '-0345',0,[1975,7,31,3,44,59],[1975,7,30,23,59,59],
          '1915030103:52:40','1915030100:07:40','1975073103:44:59','1975073023:59:59' ],
     ],
   1975 =>
     [
        [ [1975,7,31,3,45,0],[1975,7,31,0,45,0],'-03:00:00',[-3,0,0],
          '-03',0,[1991,1,1,2,59,59],[1990,12,31,23,59,59],
          '1975073103:45:00','1975073100:45:00','1991010102:59:59','1990123123:59:59' ],
     ],
   1991 =>
     [
        [ [1991,1,1,3,0,0],[1990,12,31,23,0,0],'-04:00:00',[-4,0,0],
          '-04',0,[9999,12,31,0,0,0],[9999,12,30,20,0,0],
          '1991010103:00:00','1990123123:00:00','9999123100:00:00','9999123020:00:00' ],
     ],
);

%LastRule      = (
);

1;
