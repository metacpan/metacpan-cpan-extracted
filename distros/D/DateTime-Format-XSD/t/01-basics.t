#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use_ok('DateTime::Format::XSD');

{   package PseudoDateTime;
    sub strftime {
        '2008-04-30T11:42:00+0100';
    }
}

my $dt = bless {}, 'PseudoDateTime';

my $out = DateTime::Format::XSD->format_datetime($dt);

is($out, '2008-04-30T11:42:00+01:00', 'Correctly forces timezone style.');
