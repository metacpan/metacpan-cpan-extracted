package #
Date::Manip::Offset::off402;
# Copyright (c) 2008-2019 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Dec  2 09:46:54 EST 2019
#    Data version: tzdata2019c
#    Code version: tzcode2019c

# This module contains data from the zoneinfo time zone database.  The original
# data was obtained from the URL:
#    ftp://ftp.iana.org/tz

use strict;
use warnings;
require 5.010000;

our ($VERSION);
$VERSION='6.79';
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
      'america/metlakatla',
      'etc/gmt-8',
      'h',
      'america/fort_nelson',
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
