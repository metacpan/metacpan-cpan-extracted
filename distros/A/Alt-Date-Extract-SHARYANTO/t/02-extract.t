#!perl -T
use strict;
use warnings;
use Test::More tests => 50;
use Test::MockTime 'set_fixed_time';
use Date::Extract;

# a Friday. The time I wrote this line of code, in fact (in UTC)
set_fixed_time('2007-08-03T05:36:52Z');

my $parser = Date::Extract->new(prefers => 'future', time_zone => 'America/New_York');

sub extract_is {
    my ($in, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $dt = $parser->extract($in);
    is($dt->ymd, $expected, "extracts '$in' to $expected");

    local $TODO = '';
    is($dt->time_zone->name, 'America/New_York', "correct time zone");
}

# days relative to today {{{
extract_is(today     => "2007-08-03");
extract_is(tomorrow  => "2007-08-04");
extract_is(yesterday => "2007-08-02");
# }}}
# days of the week {{{
extract_is("saturday"  => "2007-08-04");
extract_is("sunday"    => "2007-08-05");
extract_is("monday"    => "2007-08-06");
extract_is("tuesday"   => "2007-08-07");
extract_is("wednesday" => "2007-08-08");
extract_is("thursday"  => "2007-08-09");

extract_is("friday"    => "2007-08-03");
TODO: {
    local $TODO = "DTFN bug. on friday, friday + prefer_future = today";
    extract_is("friday"    => "2007-08-10");
}
# }}}
# "last" days of the week {{{
extract_is("last monday"    => "2007-07-23");
extract_is("last tuesday"   => "2007-07-24");
extract_is("last wednesday" => "2007-07-25");
extract_is("last thursday"  => "2007-07-26");
extract_is("last friday"    => "2007-07-27");
extract_is("last saturday"  => "2007-07-28");
extract_is("last sunday"    => "2007-07-29");
# }}}
# "next" days of the week {{{
extract_is("next monday"    => "2007-08-06");
extract_is("next tuesday"   => "2007-08-07");
extract_is("next wednesday" => "2007-08-08");
extract_is("next thursday"  => "2007-08-09");
extract_is("next friday"    => "2007-08-10");
extract_is("next saturday"  => "2007-08-11");
extract_is("next sunday"    => "2007-08-12");
# }}}

