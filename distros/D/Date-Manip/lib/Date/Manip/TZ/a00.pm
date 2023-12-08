package #
Date::Manip::TZ::a00;
# Copyright (c) 2008-2023 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Wed Jun  7 12:24:47 EDT 2023
#    Data version: tzdata2023c
#    Code version: tzcode2023c

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
$VERSION='6.93';
END { undef $VERSION; }

%Dates         = (
   1    =>
     [
        [ [1,1,2,0,0,0],[1,1,1,23,0,0],'-01:00:00',[-1,0,0],
          'A',0,[9999,12,31,0,0,0],[9999,12,30,23,0,0],
          '0001010200:00:00','0001010123:00:00','9999123100:00:00','9999123023:00:00' ],
     ],
);

%LastRule      = (
);

1;
