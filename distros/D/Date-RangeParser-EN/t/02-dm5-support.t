#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

plan skip_all => 'DM5 support is not testable as of Date::Manip v6.00 and before v6.14'
    unless $Date::Manip::VERSION lt '6.00'
        or $Date::Manip::VERSION ge '6.14';

BEGIN {
    my $initial_warnings = "";
    $Date::Manip::Backend = 'DM5';
    {
        local $SIG{__WARN__} = sub{$initial_warnings .= $_[0]};
        require Date::Manip;
        require Date::RangeParser::EN;
    }

    like $initial_warnings, qr/Date::Manip::DM5 is deprecated/, "Found Date::Manip deprication warning";
    like $initial_warnings, qr/DM5 backend will be deprecated/, "Found Date::RangeParser::EN deprication warning";
}

sub is_forcedate($) {
    my ($expected) = @_;
    my $expected_str = $expected || ""; # warning prevention
    my @config = grep /^ForceDate=/i, Date::Manip::Date_Init();
    like($config[0], qr/=$expected$/, qq[Is ForceDate now "$expected_str"]);
}

my @config = Date::Manip::Date_Init();

is_forcedate('');

my $rp = Date::RangeParser::EN->new;
$rp->parse_range('2012-10-10');

is_forcedate('');

Date::Manip::Date_Init("ForceDate=2012-12-12-00:00:00");
@config = Date::Manip::Date_Init("ForceDate=2012-12-12-00:00:00");

$rp->parse_range('2012-10-10');

is_forcedate('2012-12-12-00:00:00');

done_testing;
