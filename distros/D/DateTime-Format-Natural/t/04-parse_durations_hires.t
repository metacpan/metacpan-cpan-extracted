#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true);

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test ':set';
use Test::More;

my @relative = (
    { 'for 4 milliseconds' => [ '24.11.2006 01:13:08.000', '24.11.2006 01:13:08.004' ] },
);

_run_tests(1, [ [ \@relative ] ], \&compare);

sub compare
{
    my $aref = shift;

    foreach my $href (@$aref) {
        my $key = (keys %$href)[0];
        foreach my $string ($case_strings->($key)) {
            compare_strings($string, $href->{$key});
        }
    }
}

sub compare_strings
{
    my ($string, $result) = @_;

    my $parser = DateTime::Format::Natural->new;
    $parser->_set_datetime(\%time);

    my @dt = $parser->parse_datetime_duration($string);

    my $pass = true;
    foreach my $i (0..$#dt) {
        $pass &= _result_string_hires($dt[$i]) eq $result->[$i];
    }

    if ($parser->success && $pass && @dt == 2) {
        ok($pass, _message($string));
    }
    else {
        fail(_message($string));
    }
}
