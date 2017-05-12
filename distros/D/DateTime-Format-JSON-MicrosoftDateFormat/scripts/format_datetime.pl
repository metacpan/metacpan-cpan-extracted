#!/usr/bin/perl
use strict;
use warnings;
use DateTime;
use DateTime::Format::JSON::MicrosoftDateFormat;

my $formatter=DateTime::Format::JSON::MicrosoftDateFormat->new;

my $dt=DateTime->now;
$dt->set_formatter($formatter);
print "$dt\n";
