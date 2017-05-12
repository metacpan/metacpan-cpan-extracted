#!/usr/bin/perl -w

###############################################################################
#
# A test for Data::Dumper::Perltidy.
#
# Simple tests for th Dumper() function.
#
# reverse('©'), January 2009, John McNamara, jmcnamara@cpan.org
#

use strict;
use Data::Dumper::Perltidy;
use Test::More tests => 1;

# Test the example from the docs.
my $data = [
    { title      => 'This is a test header' },
    { data_range => [ 0, 0, 3, 9 ] },
    { format     => 'bold' }
];

my $got = Dumper $data;

my $expected = << 'END_OF_EXPECTED';
$VAR1 = [
    { 'title'      => 'This is a test header' },
    { 'data_range' => [ 0, 0, 3, 9 ] },
    { 'format'     => 'bold' }
];
END_OF_EXPECTED

is ($got, $expected, "Example from the docs");

__END__
