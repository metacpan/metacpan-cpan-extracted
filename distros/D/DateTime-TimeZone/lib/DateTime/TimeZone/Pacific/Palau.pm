# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.08) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from /tmp/nUm_LjpJ6O/australasia.  Olson data version 2025b
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Pacific::Palau;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '2.65';

use Class::Singleton 1.03;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Pacific::Palau::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY, #    utc_start
58191058924, #      utc_end 1844-12-31 15:02:04 (Tue)
DateTime::TimeZone::NEG_INFINITY, #  local_start
58191004800, #    local_end 1844-12-31 00:00:00 (Tue)
-54124,
0,
'LMT',
    ],
    [
58191058924, #    utc_start 1844-12-31 15:02:04 (Tue)
59958198124, #      utc_end 1900-12-31 15:02:04 (Mon)
58191091200, #  local_start 1845-01-01 00:00:00 (Wed)
59958230400, #    local_end 1901-01-01 00:00:00 (Tue)
32276,
0,
'LMT',
    ],
    [
59958198124, #    utc_start 1900-12-31 15:02:04 (Mon)
DateTime::TimeZone::INFINITY, #      utc_end
59958230524, #  local_start 1901-01-01 00:02:04 (Tue)
DateTime::TimeZone::INFINITY, #    local_end
32400,
0,
'+09',
    ],
];

sub olson_version {'2025b'}

sub has_dst_changes {0}

sub _max_year {2035}

sub _new_instance {
    return shift->_init( @_, spans => $spans );
}



1;

