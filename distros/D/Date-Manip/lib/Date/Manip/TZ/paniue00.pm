package #
Date::Manip::TZ::paniue00;
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
        [ [1,1,2,0,0,0],[1,1,1,12,40,20],'-11:19:40',[-11,-19,-40],
          'LMT',0,[1952,10,16,11,19,39],[1952,10,15,23,59,59],
          '0001010200:00:00','0001010112:40:20','1952101611:19:39','1952101523:59:59' ],
     ],
   1952 =>
     [
        [ [1952,10,16,11,19,40],[1952,10,15,23,59,40],'-11:20:00',[-11,-20,0],
          '-1120',0,[1964,7,1,11,19,59],[1964,6,30,23,59,59],
          '1952101611:19:40','1952101523:59:40','1964070111:19:59','1964063023:59:59' ],
     ],
   1964 =>
     [
        [ [1964,7,1,11,20,0],[1964,7,1,0,20,0],'-11:00:00',[-11,0,0],
          '-11',0,[9999,12,31,0,0,0],[9999,12,30,13,0,0],
          '1964070111:20:00','1964070100:20:00','9999123100:00:00','9999123013:00:00' ],
     ],
);

%LastRule      = (
);

1;
