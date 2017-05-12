#!/usr/bin/perl
use strict;
use warnings;
use DateTime::Format::JSON::MicrosoftDateFormat;

my $parser=DateTime::Format::JSON::MicrosoftDateFormat->new;

my $dt=$parser->parse_datetime("/Date(1392606509000)/");
print "$dt\n";
