package #
Date::Manip::TZ::panaur00;
# Copyright (c) 2008-2021 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Mar  1 14:17:33 EST 2021
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
        [ [1,1,2,0,0,0],[1,1,2,11,7,40],'+11:07:40',[11,7,40],
          'LMT',0,[1921,1,14,12,52,19],[1921,1,14,23,59,59],
          '0001010200:00:00','0001010211:07:40','1921011412:52:19','1921011423:59:59' ],
     ],
   1921 =>
     [
        [ [1921,1,14,12,52,20],[1921,1,15,0,22,20],'+11:30:00',[11,30,0],
          '+1130',0,[1942,8,28,12,29,59],[1942,8,28,23,59,59],
          '1921011412:52:20','1921011500:22:20','1942082812:29:59','1942082823:59:59' ],
     ],
   1942 =>
     [
        [ [1942,8,28,12,30,0],[1942,8,28,21,30,0],'+09:00:00',[9,0,0],
          '+09',0,[1945,9,7,14,59,59],[1945,9,7,23,59,59],
          '1942082812:30:00','1942082821:30:00','1945090714:59:59','1945090723:59:59' ],
     ],
   1945 =>
     [
        [ [1945,9,7,15,0,0],[1945,9,8,2,30,0],'+11:30:00',[11,30,0],
          '+1130',0,[1979,2,9,14,29,59],[1979,2,10,1,59,59],
          '1945090715:00:00','1945090802:30:00','1979020914:29:59','1979021001:59:59' ],
     ],
   1979 =>
     [
        [ [1979,2,9,14,30,0],[1979,2,10,2,30,0],'+12:00:00',[12,0,0],
          '+12',0,[9999,12,31,0,0,0],[9999,12,31,12,0,0],
          '1979020914:30:00','1979021002:30:00','9999123100:00:00','9999123112:00:00' ],
     ],
);

%LastRule      = (
);

1;
