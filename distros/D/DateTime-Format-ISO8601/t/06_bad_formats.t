#!/usr/bin/perl

# Copyright (C) 2003-2012  Joshua Hoblitt

use strict;
use warnings;

use lib qw( ./lib );

use Test::More tests => 4;

use DateTime::Format::ISO8601;

# parse_datetime
my $base_year = 2000;
my $base_month = "01";
my $iso8601 = DateTime::Format::ISO8601->new(
    base_datetime => DateTime->new( year => $base_year, month => $base_month ),
);

# examples from https://rt.cpan.org/Ticket/Update.html?id=5264

#Section 4.2.5.1 says "Expressions of the difference between local time and UTC
#of day are a component in the representations defined in 4.2.5.2; they shall
#not be used as self-standing expressions.".  Which means the UTC offset is
#considered part of the time format so you get to use the extended formation
#(the ':') or not but you can't mix and match the two.

eval {
    my $dt = $iso8601->parse_datetime( '2009-12-10T09:00:00.00+0100' );
};
like( $@, qr/Invalid date format/ );

eval {
    my $dt = $iso8601->parse_datetime( '2011-07-04T20:50:23+0200' );
};
like( $@, qr/Invalid date format/ );

# more "colon or not" coverage
eval {
    my $dt = $iso8601->parse_datetime( '20091210T090000.00+01:00' );
};
like( $@, qr/Invalid date format/ );

eval {
    my $dt = $iso8601->parse_datetime( '20110704T205023+02:00' );
};
like( $@, qr/Invalid date format/ );
