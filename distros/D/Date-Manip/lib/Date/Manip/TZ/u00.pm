package #
Date::Manip::TZ::u00;
# Copyright (c) 2008-2017 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Tue May 30 10:43:18 EDT 2017
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
        [ [1,1,2,0,0,0],[1,1,2,8,0,0],'+08:00:00',[8,0,0],
          'U',0,[9999,12,31,0,0,0],[9999,12,31,8,0,0],
          '0001010200:00:00','0001010208:00:00','9999123100:00:00','9999123108:00:00' ],
     ],
);

%LastRule      = (
);

1;
