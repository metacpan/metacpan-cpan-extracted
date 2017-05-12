#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use DateTime;
use DateTime::Format::JSON::MicrosoftDateFormat (to_json=>1); #imports DateTime::TO_JSON method

my $formatter=DateTime::Format::JSON::MicrosoftDateFormat->new;
my $json=JSON->new->convert_blessed->pretty;

my $dt=DateTime->now(formatter=>$formatter);
print $json->encode({now=>$dt});
