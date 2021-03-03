package #
Date::Manip::TZ::pagala00;
# Copyright (c) 2008-2021 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Mar  1 14:17:27 EST 2021
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
        [ [1,1,2,0,0,0],[1,1,1,18,1,36],'-05:58:24',[-5,-58,-24],
          'LMT',0,[1931,1,1,5,58,23],[1930,12,31,23,59,59],
          '0001010200:00:00','0001010118:01:36','1931010105:58:23','1930123123:59:59' ],
     ],
   1931 =>
     [
        [ [1931,1,1,5,58,24],[1931,1,1,0,58,24],'-05:00:00',[-5,0,0],
          '-05',0,[1986,1,1,4,59,59],[1985,12,31,23,59,59],
          '1931010105:58:24','1931010100:58:24','1986010104:59:59','1985123123:59:59' ],
     ],
   1986 =>
     [
        [ [1986,1,1,5,0,0],[1985,12,31,23,0,0],'-06:00:00',[-6,0,0],
          '-06',0,[1992,11,28,5,59,59],[1992,11,27,23,59,59],
          '1986010105:00:00','1985123123:00:00','1992112805:59:59','1992112723:59:59' ],
     ],
   1992 =>
     [
        [ [1992,11,28,6,0,0],[1992,11,28,1,0,0],'-05:00:00',[-5,0,0],
          '-05',1,[1993,2,5,4,59,59],[1993,2,4,23,59,59],
          '1992112806:00:00','1992112801:00:00','1993020504:59:59','1993020423:59:59' ],
     ],
   1993 =>
     [
        [ [1993,2,5,5,0,0],[1993,2,4,23,0,0],'-06:00:00',[-6,0,0],
          '-06',0,[9999,12,31,0,0,0],[9999,12,30,18,0,0],
          '1993020505:00:00','1993020423:00:00','9999123100:00:00','9999123018:00:00' ],
     ],
);

%LastRule      = (
);

1;
