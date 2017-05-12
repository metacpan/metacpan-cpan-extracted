# -*- perl -*-

# t/018_bug_rt107389.t - check bug http://rt.cpan.org/Public/Bug/Display.html?id=107389

use strict;
use warnings;
no warnings qw(once);

use lib qw(t/lib);
use testlib;

use Test::More tests => 15+1;
use Test::NoWarnings;

use DateTime;
use DateTime::Format::CLDR;

my @tests = (
    { pattern => 'y', value => '2015', result => 2015 },
    { pattern => 'y', value => '15', result => 15 },
    { pattern => 'y', value => '333', result => 333 },
    { pattern => 'y', value => '-333', result => -333 },
    { pattern => 'yy', value => '15', result => 2015 },
    { pattern => 'yy', value => '77', result => 1977 },
    { pattern => 'yyy', value => '2015', result => 2015 },
    { pattern => 'yyy', value => '333', result => 333 },
    { pattern => 'yyy', value => '-333', result => -333 },
    { pattern => 'yyyy', value => '2015', result => 2015 },
    { pattern => 'yyyy', value => '0333', result => 333 },
    { pattern => 'yyyy', value => '-0333', result => -333 },
    { pattern => 'yyyyy', value => '00333', result => 333 },
    { pattern => 'yyyyy', value => '-00333', result => -333 },
    { pattern => 'yyyyy', value => '02015', result => 2015 },
);

foreach my $test (@tests) {
    my $format = DateTime::Format::CLDR->new(
        pattern     => $test->{pattern},
        on_error    => 'croak',
    );
    my $year = $format->parse_datetime($test->{value})->year;
    is($year,$test->{result},'Parsed year is '.$test->{result});
}