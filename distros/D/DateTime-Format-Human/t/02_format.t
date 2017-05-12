# Copyright (C) 2004  Joshua Hoblitt
#
# $Id: 02_format.t,v 1.1.1.1 2004/10/17 00:44:32 jhoblitt Exp $

use strict;
use warnings;

use Test::More tests => 48;

use DateTime;
use DateTime::Format::Human;

my %numbers = (
    1   => "one",
    2   => "two",
    3   => "three",
    4   => "four",
    5   => "five",
    6   => "six",
    7   => "seven",
    8   => "eight",
    9   => "nine",
    10  => "ten",
    11  => "eleven",
#    12  => "twelve",
    13  => "one",
    14  => "two",
    15  => "three",
    16  => "four",
    17  => "five",
    18  => "six",
    19  => "seven",
    20  => "eight",
    21  => "nine",
    22  => "ten",
    23  => "eleven",
#    0   => "midnight",
);

my %daytime = (
    0   => "midnight",
    1   => "in the morning",
    12  => "midday",
    13  => "in the afternoon",
    18  => "in the evening",
    22  => "at night",
);

my %vagueness = (
    0 => "exactly",
    1 => "just after",
    2 => "a little after",
    3 => "coming up to",
    4 => "almost",
);

my %minutes = (
    5   => "five past",
    10  => "ten past",
    15  => "quarter past",
    20  => "twenty past",
    25  => "twenty-five past",
    30  => "half past",
    35  => "twenty-five to",
    40  => "twenty to",
    45  => "quarter to",
    50  => "ten to",
    55  => "five to",
);

foreach my $n ( keys %numbers ) {
    my $dtfh = DateTime::Format::Human->new;
    my $dt = DateTime->new( year => 0, hour => $n );

    like( $dtfh->format_datetime( $dt ), qr/$numbers{ $n } o'clock/ );
}

foreach my $n ( keys %daytime ) {
    my $dtfh = DateTime::Format::Human->new;
    my $dt = DateTime->new( year => 0, hour => $n );

    like( $dtfh->format_datetime( $dt ), qr/$daytime{ $n }/ );
}

{
    my %daytime = (
        13  => "in the afternoon",
        15  => "in the evening",
        17  => "at night",
    );

    foreach my $n ( keys %daytime ) {
        my $dtfh = DateTime::Format::Human->new( evening => 14, night => 16 );
        my $dt = DateTime->new( year => 0, hour => $n );

        like( $dtfh->format_datetime( $dt ), qr/$daytime{ $n }/ );
    }
}

foreach my $n ( keys %vagueness ) {
    my $dtfh = DateTime::Format::Human->new;
    my $dt = DateTime->new( year => 0, minute => $n );

    like( $dtfh->format_datetime( $dt ), qr/$vagueness{ $n }.*midnight/ );
}

foreach my $n ( keys %minutes ) {
    my $dtfh = DateTime::Format::Human->new;
    my $dt = DateTime->new( year => 0, minute => $n );

    like( $dtfh->format_datetime( $dt ), qr/$minutes{ $n }/ );
}

{
    my $dtfh = DateTime::Format::Human->new;
    my $dt = DateTime->new( year => 12, hour => 12, minute => 12 );

    is( $dtfh->format_datetime( $dt ), "a little after ten past midday" );
}
