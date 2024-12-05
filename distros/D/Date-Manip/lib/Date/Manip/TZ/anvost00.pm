package #
Date::Manip::TZ::anvost00;
# Copyright (c) 2008-2024 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Wed Dec  4 14:48:44 EST 2024
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
        [ [1,1,2,0,0,0],[1,1,2,0,0,0],'+00:00:00',[0,0,0],
          '-00',0,[1957,12,15,23,59,59],[1957,12,15,23,59,59],
          '0001010200:00:00','0001010200:00:00','1957121523:59:59','1957121523:59:59' ],
     ],
   1957 =>
     [
        [ [1957,12,16,0,0,0],[1957,12,16,7,0,0],'+07:00:00',[7,0,0],
          '+07',0,[1994,1,31,16,59,59],[1994,1,31,23,59,59],
          '1957121600:00:00','1957121607:00:00','1994013116:59:59','1994013123:59:59' ],
     ],
   1994 =>
     [
        [ [1994,1,31,17,0,0],[1994,1,31,17,0,0],'+00:00:00',[0,0,0],
          '-00',0,[1994,10,31,23,59,59],[1994,10,31,23,59,59],
          '1994013117:00:00','1994013117:00:00','1994103123:59:59','1994103123:59:59' ],
        [ [1994,11,1,0,0,0],[1994,11,1,7,0,0],'+07:00:00',[7,0,0],
          '+07',0,[2023,12,17,18,59,59],[2023,12,18,1,59,59],
          '1994110100:00:00','1994110107:00:00','2023121718:59:59','2023121801:59:59' ],
     ],
   2023 =>
     [
        [ [2023,12,17,19,0,0],[2023,12,18,0,0,0],'+05:00:00',[5,0,0],
          '+05',0,[9999,12,31,0,0,0],[9999,12,31,5,0,0],
          '2023121719:00:00','2023121800:00:00','9999123100:00:00','9999123105:00:00' ],
     ],
);

%LastRule      = (
);

1;
