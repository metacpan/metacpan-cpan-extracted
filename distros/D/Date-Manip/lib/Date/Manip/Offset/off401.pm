package #
Date::Manip::Offset::off401;
# Copyright (c) 2008-2018 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Wed May 30 14:51:34 EDT 2018
#    Data version: tzdata2018e
#    Code version: tzcode2018e

# This module contains data from the zoneinfo time zone database.  The original
# data was obtained from the URL:
#    ftp://ftp.iana.org/tz

use strict;
use warnings;
require 5.010000;

our ($VERSION);
$VERSION='6.72';
END { undef $VERSION; }

our ($Offset,%Offset);
END {
   undef $Offset;
   undef %Offset;
}

$Offset        = '-08:00:00';

%Offset        = (
   0 => [
      'america/los_angeles',
      'america/vancouver',
      'america/tijuana',
      'america/whitehorse',
      'america/dawson',
      'pacific/pitcairn',
      'etc/gmt-8',
      'h',
      'america/fort_nelson',
      'america/metlakatla',
      'america/juneau',
      'america/sitka',
      'america/inuvik',
      'america/dawson_creek',
      'america/bahia_banderas',
      'america/hermosillo',
      'america/mazatlan',
      'america/boise',
      'america/creston',
      ],
   1 => [
      'america/juneau',
      'america/yakutat',
      'america/anchorage',
      'america/nome',
      'america/sitka',
      'america/metlakatla',
      'america/dawson',
      'america/whitehorse',
      ],
);

1;
