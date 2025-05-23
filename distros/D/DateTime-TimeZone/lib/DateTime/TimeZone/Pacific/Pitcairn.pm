# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.08) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from /tmp/nUm_LjpJ6O/australasia.  Olson data version 2025b
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Pacific::Pitcairn;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '2.65';

use Class::Singleton 1.03;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Pacific::Pitcairn::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY, #    utc_start
59958261620, #      utc_end 1901-01-01 08:40:20 (Tue)
DateTime::TimeZone::NEG_INFINITY, #  local_start
59958230400, #    local_end 1901-01-01 00:00:00 (Tue)
-31220,
0,
'LMT',
    ],
    [
59958261620, #    utc_start 1901-01-01 08:40:20 (Tue)
63029349000, #      utc_end 1998-04-27 08:30:00 (Mon)
59958231020, #  local_start 1901-01-01 00:10:20 (Tue)
63029318400, #    local_end 1998-04-27 00:00:00 (Mon)
-30600,
0,
'-0830',
    ],
    [
63029349000, #    utc_start 1998-04-27 08:30:00 (Mon)
DateTime::TimeZone::INFINITY, #      utc_end
63029320200, #  local_start 1998-04-27 00:30:00 (Mon)
DateTime::TimeZone::INFINITY, #    local_end
-28800,
0,
'-08',
    ],
];

sub olson_version {'2025b'}

sub has_dst_changes {0}

sub _max_year {2035}

sub _new_instance {
    return shift->_init( @_, spans => $spans );
}



1;

