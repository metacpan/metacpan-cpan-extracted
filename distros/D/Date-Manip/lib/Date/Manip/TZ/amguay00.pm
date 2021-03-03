package #
Date::Manip::TZ::amguay00;
# Copyright (c) 2008-2021 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Mar  1 14:17:28 EST 2021
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
        [ [1,1,2,0,0,0],[1,1,1,18,40,40],'-05:19:20',[-5,-19,-20],
          'LMT',0,[1890,1,1,5,19,19],[1889,12,31,23,59,59],
          '0001010200:00:00','0001010118:40:40','1890010105:19:19','1889123123:59:59' ],
     ],
   1890 =>
     [
        [ [1890,1,1,5,19,20],[1890,1,1,0,5,20],'-05:14:00',[-5,-14,0],
          'QMT',0,[1931,1,1,5,13,59],[1930,12,31,23,59,59],
          '1890010105:19:20','1890010100:05:20','1931010105:13:59','1930123123:59:59' ],
     ],
   1931 =>
     [
        [ [1931,1,1,5,14,0],[1931,1,1,0,14,0],'-05:00:00',[-5,0,0],
          '-05',0,[1992,11,28,4,59,59],[1992,11,27,23,59,59],
          '1931010105:14:00','1931010100:14:00','1992112804:59:59','1992112723:59:59' ],
     ],
   1992 =>
     [
        [ [1992,11,28,5,0,0],[1992,11,28,1,0,0],'-04:00:00',[-4,0,0],
          '-04',1,[1993,2,5,3,59,59],[1993,2,4,23,59,59],
          '1992112805:00:00','1992112801:00:00','1993020503:59:59','1993020423:59:59' ],
     ],
   1993 =>
     [
        [ [1993,2,5,4,0,0],[1993,2,4,23,0,0],'-05:00:00',[-5,0,0],
          '-05',0,[9999,12,31,0,0,0],[9999,12,30,19,0,0],
          '1993020504:00:00','1993020423:00:00','9999123100:00:00','9999123019:00:00' ],
     ],
);

%LastRule      = (
);

1;
