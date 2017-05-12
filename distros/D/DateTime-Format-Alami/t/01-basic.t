#!perl

use 5.010001;
use strict;
use warnings;

use DateTime::Format::Alami::EN;
use DateTime::Format::Alami::ID;
use Test::Exception;
use Test::More 0.98;

# sanity: allow calling as static method
my $dt = DateTime::Format::Alami::EN->parse_datetime("2d ago");
is(ref $dt, "DateTime");

# sanity: dies on parse failure
dies_ok { DateTime::Format::Alami::EN->parse_datetime("foo") };

# sanity: allow calling as static method
my $dtdur = DateTime::Format::Alami::ID->parse_datetime_duration("2h");
is(ref $dtdur, "DateTime::Duration");

# sanity: dies on parse failure
dies_ok { DateTime::Format::Alami::ID->parse_datetime_duration("foo") };

done_testing;
