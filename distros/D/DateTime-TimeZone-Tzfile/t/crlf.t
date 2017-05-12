use warnings;
use strict;

use Test::More tests => 2;

require_ok "DateTime::TimeZone::Tzfile";

# This tests for proper binary mode handling of tzfiles.  Specifically,
# if a tzfile is read in text mode then it may get mangled by translation
# of CRLF to LF.  This Kaliningrad.tz file happens to contain a byte
# sequence that would be interpreted as CRLF in text mode.
my $tz = DateTime::TimeZone::Tzfile->new("t/Kaliningrad.tz");
ok 1;

1;
