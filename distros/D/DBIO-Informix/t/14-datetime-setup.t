use strict;
use warnings;

use Test::More;
use DBIO::Informix::Storage;

# GL_DATETIME is what the server formats DATETIME values with, and the storage
# parses them with '%Y-%m-%d %H:%M:%S.%5N'. Informix puts no decimal point
# before %F on its own: with "...%S%F5" the value comes back as
# '2026-10-27 14:26:5755564' (measured against Informix 15.0.1, karr k20),
# which the parser rejects. The point has to be in the format.

local (%ENV) = %ENV;
DBIO::Informix::Storage->connect_call_datetime_setup;

is $ENV{GL_DATETIME}, '%Y-%m-%d %H:%M:%S.%F5',
  'GL_DATETIME separates seconds and fraction with a point, as the parser expects';

done_testing;
