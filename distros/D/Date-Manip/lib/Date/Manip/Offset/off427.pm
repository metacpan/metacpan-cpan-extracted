package #
Date::Manip::Offset::off427;
# Copyright (c) 2008-2021 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Mar  1 14:20:52 EST 2021
#    Data version: tzdata2021a
#    Code version: tzcode2021a

# This module contains data from the zoneinfo time zone database.  The original
# data was obtained from the URL:
#    ftp://ftp.iana.org/tz

use strict;
use warnings;
require 5.010000;

our ($VERSION);
$VERSION='6.85';
END { undef $VERSION; }

our ($Offset,%Offset);
END {
   undef $Offset;
   undef %Offset;
}

$Offset        = '-11:00:00';

%Offset        = (
   0 => [
      'pacific/pago_pago',
      'pacific/niue',
      'etc/gmt-11',
      'l',
      'pacific/fakaofo',
      'pacific/apia',
      'pacific/enderbury',
      'america/adak',
      'america/nome',
      ],
);

1;
