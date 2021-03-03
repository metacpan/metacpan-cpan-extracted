package #
Date::Manip::TZ::afsao_00;
# Copyright (c) 2008-2021 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Mar  1 14:17:31 EST 2021
#    Data version: tzdata2021a
#    Code version: tzcode2021a

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
$VERSION='6.85';
END { undef $VERSION; }

%Dates         = (
   1    =>
     [
        [ [1,1,2,0,0,0],[1,1,2,0,26,56],'+00:26:56',[0,26,56],
          'LMT',0,[1883,12,31,23,33,3],[1883,12,31,23,59,59],
          '0001010200:00:00','0001010200:26:56','1883123123:33:03','1883123123:59:59' ],
     ],
   1883 =>
     [
        [ [1883,12,31,23,33,4],[1883,12,31,22,56,19],'-00:36:45',[0,-36,-45],
          'LMT',0,[1911,12,31,23,59,59],[1911,12,31,23,23,14],
          '1883123123:33:04','1883123122:56:19','1911123123:59:59','1911123123:23:14' ],
     ],
   1912 =>
     [
        [ [1912,1,1,0,0,0],[1912,1,1,0,0,0],'+00:00:00',[0,0,0],
          'GMT',0,[2018,1,1,0,59,59],[2018,1,1,0,59,59],
          '1912010100:00:00','1912010100:00:00','2018010100:59:59','2018010100:59:59' ],
     ],
   2018 =>
     [
        [ [2018,1,1,1,0,0],[2018,1,1,2,0,0],'+01:00:00',[1,0,0],
          'WAT',0,[2019,1,1,0,59,59],[2019,1,1,1,59,59],
          '2018010101:00:00','2018010102:00:00','2019010100:59:59','2019010101:59:59' ],
     ],
   2019 =>
     [
        [ [2019,1,1,1,0,0],[2019,1,1,1,0,0],'+00:00:00',[0,0,0],
          'GMT',0,[9999,12,31,0,0,0],[9999,12,31,0,0,0],
          '2019010101:00:00','2019010101:00:00','9999123100:00:00','9999123100:00:00' ],
     ],
);

%LastRule      = (
);

1;
