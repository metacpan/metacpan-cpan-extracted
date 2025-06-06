# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.08) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from /tmp/nUm_LjpJ6O/asia.  Olson data version 2025b
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Indian::Maldives;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '2.65';

use Class::Singleton 1.03;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Indian::Maldives::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY, #    utc_start
59295524760, #      utc_end 1879-12-31 19:06:00 (Wed)
DateTime::TimeZone::NEG_INFINITY, #  local_start
59295542400, #    local_end 1880-01-01 00:00:00 (Thu)
17640,
0,
'LMT',
    ],
    [
59295524760, #    utc_start 1879-12-31 19:06:00 (Wed)
61820046360, #      utc_end 1959-12-31 19:06:00 (Thu)
59295542400, #  local_start 1880-01-01 00:00:00 (Thu)
61820064000, #    local_end 1960-01-01 00:00:00 (Fri)
17640,
0,
'MMT',
    ],
    [
61820046360, #    utc_start 1959-12-31 19:06:00 (Thu)
DateTime::TimeZone::INFINITY, #      utc_end
61820064360, #  local_start 1960-01-01 00:06:00 (Fri)
DateTime::TimeZone::INFINITY, #    local_end
18000,
0,
'+05',
    ],
];

sub olson_version {'2025b'}

sub has_dst_changes {0}

sub _max_year {2035}

sub _new_instance {
    return shift->_init( @_, spans => $spans );
}



1;

