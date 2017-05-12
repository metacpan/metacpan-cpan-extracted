#!perl -T
use strict;
use warnings;
use Test::More tests => 2;
use Date::Extract;

my $parser = Date::Extract->new;
my $dt = $parser->extract("writing a test today!");
is($dt->time_zone->name, 'floating', 'default time zone is floating');
is($dt->ymd, DateTime->today(time_zone => 'floating')->ymd, 'extracted the date as today');

