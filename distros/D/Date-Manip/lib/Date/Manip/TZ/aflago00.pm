package #
Date::Manip::TZ::aflago00;
# Copyright (c) 2008-2021 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Mar  1 14:17:32 EST 2021
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
        [ [1,1,2,0,0,0],[1,1,2,0,13,35],'+00:13:35',[0,13,35],
          'LMT',0,[1905,6,30,23,46,24],[1905,6,30,23,59,59],
          '0001010200:00:00','0001010200:13:35','1905063023:46:24','1905063023:59:59' ],
     ],
   1905 =>
     [
        [ [1905,6,30,23,46,25],[1905,6,30,23,46,25],'+00:00:00',[0,0,0],
          'GMT',0,[1908,6,30,23,59,59],[1908,6,30,23,59,59],
          '1905063023:46:25','1905063023:46:25','1908063023:59:59','1908063023:59:59' ],
     ],
   1908 =>
     [
        [ [1908,7,1,0,0,0],[1908,7,1,0,13,35],'+00:13:35',[0,13,35],
          'LMT',0,[1913,12,31,23,46,24],[1913,12,31,23,59,59],
          '1908070100:00:00','1908070100:13:35','1913123123:46:24','1913123123:59:59' ],
     ],
   1913 =>
     [
        [ [1913,12,31,23,46,25],[1914,1,1,0,16,25],'+00:30:00',[0,30,0],
          '+0030',0,[1919,8,31,23,29,59],[1919,8,31,23,59,59],
          '1913123123:46:25','1914010100:16:25','1919083123:29:59','1919083123:59:59' ],
     ],
   1919 =>
     [
        [ [1919,8,31,23,30,0],[1919,9,1,0,30,0],'+01:00:00',[1,0,0],
          'WAT',0,[9999,12,31,0,0,0],[9999,12,31,1,0,0],
          '1919083123:30:00','1919090100:30:00','9999123100:00:00','9999123101:00:00' ],
     ],
);

%LastRule      = (
);

1;
