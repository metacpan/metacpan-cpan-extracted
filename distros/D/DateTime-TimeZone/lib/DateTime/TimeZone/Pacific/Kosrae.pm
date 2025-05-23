# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.08) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from /tmp/nUm_LjpJ6O/australasia.  Olson data version 2025b
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Pacific::Kosrae;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '2.65';

use Class::Singleton 1.03;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Pacific::Kosrae::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY, #    utc_start
58191052084, #      utc_end 1844-12-31 13:08:04 (Tue)
DateTime::TimeZone::NEG_INFINITY, #  local_start
58191004800, #    local_end 1844-12-31 00:00:00 (Tue)
-47284,
0,
'LMT',
    ],
    [
58191052084, #    utc_start 1844-12-31 13:08:04 (Tue)
59958191284, #      utc_end 1900-12-31 13:08:04 (Mon)
58191091200, #  local_start 1845-01-01 00:00:00 (Wed)
59958230400, #    local_end 1901-01-01 00:00:00 (Tue)
39116,
0,
'LMT',
    ],
    [
59958191284, #    utc_start 1900-12-31 13:08:04 (Mon)
60392005200, #      utc_end 1914-09-30 13:00:00 (Wed)
59958230884, #  local_start 1901-01-01 00:08:04 (Tue)
60392044800, #    local_end 1914-10-01 00:00:00 (Thu)
39600,
0,
'+11',
    ],
    [
60392005200, #    utc_start 1914-09-30 13:00:00 (Wed)
60528870000, #      utc_end 1919-01-31 15:00:00 (Fri)
60392037600, #  local_start 1914-09-30 22:00:00 (Wed)
60528902400, #    local_end 1919-02-01 00:00:00 (Sat)
32400,
0,
'+09',
    ],
    [
60528870000, #    utc_start 1919-01-31 15:00:00 (Fri)
61094264400, #      utc_end 1936-12-31 13:00:00 (Thu)
60528909600, #  local_start 1919-02-01 02:00:00 (Sat)
61094304000, #    local_end 1937-01-01 00:00:00 (Fri)
39600,
0,
'+11',
    ],
    [
61094264400, #    utc_start 1936-12-31 13:00:00 (Thu)
61228274400, #      utc_end 1941-03-31 14:00:00 (Mon)
61094300400, #  local_start 1936-12-31 23:00:00 (Thu)
61228310400, #    local_end 1941-04-01 00:00:00 (Tue)
36000,
0,
'+10',
    ],
    [
61228274400, #    utc_start 1941-03-31 14:00:00 (Mon)
61365049200, #      utc_end 1945-07-31 15:00:00 (Tue)
61228306800, #  local_start 1941-03-31 23:00:00 (Mon)
61365081600, #    local_end 1945-08-01 00:00:00 (Wed)
32400,
0,
'+09',
    ],
    [
61365049200, #    utc_start 1945-07-31 15:00:00 (Tue)
62127694800, #      utc_end 1969-09-30 13:00:00 (Tue)
61365088800, #  local_start 1945-08-01 02:00:00 (Wed)
62127734400, #    local_end 1969-10-01 00:00:00 (Wed)
39600,
0,
'+11',
    ],
    [
62127694800, #    utc_start 1969-09-30 13:00:00 (Tue)
63050788800, #      utc_end 1998-12-31 12:00:00 (Thu)
62127738000, #  local_start 1969-10-01 01:00:00 (Wed)
63050832000, #    local_end 1999-01-01 00:00:00 (Fri)
43200,
0,
'+12',
    ],
    [
63050788800, #    utc_start 1998-12-31 12:00:00 (Thu)
DateTime::TimeZone::INFINITY, #      utc_end
63050828400, #  local_start 1998-12-31 23:00:00 (Thu)
DateTime::TimeZone::INFINITY, #    local_end
39600,
0,
'+11',
    ],
];

sub olson_version {'2025b'}

sub has_dst_changes {0}

sub _max_year {2035}

sub _new_instance {
    return shift->_init( @_, spans => $spans );
}



1;

