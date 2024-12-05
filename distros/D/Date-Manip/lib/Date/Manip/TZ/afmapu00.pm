package #
Date::Manip::TZ::afmapu00;
# Copyright (c) 2008-2024 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Wed Dec  4 14:48:43 EST 2024
#    Data version: tzdata2024b
#    Code version: tzcode2024b

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
$VERSION='6.96';
END { undef $VERSION; }

%Dates         = (
   1    =>
     [
        [ [1,1,2,0,0,0],[1,1,2,2,10,18],'+02:10:18',[2,10,18],
          'LMT',0,[1908,12,31,21,49,41],[1908,12,31,23,59,59],
          '0001010200:00:00','0001010202:10:18','1908123121:49:41','1908123123:59:59' ],
     ],
   1908 =>
     [
        [ [1908,12,31,21,49,42],[1908,12,31,23,49,42],'+02:00:00',[2,0,0],
          'CAT',0,[9999,12,31,0,0,0],[9999,12,31,2,0,0],
          '1908123121:49:42','1908123123:49:42','9999123100:00:00','9999123102:00:00' ],
     ],
);

%LastRule      = (
);

1;
