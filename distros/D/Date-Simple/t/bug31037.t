use strict;
use warnings;

use Test::More;

plan tests => 3;

use Date::Simple;

my $date = Date::Simple->new("2007-11-05");

$date->default_format("%m.%d.%Y");

is($date->as_str, "11.05.2007");

$date++;

is($date->as_str, "11.06.2007");

$date--;

is($date->as_str, "11.05.2007");
