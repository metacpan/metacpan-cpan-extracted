#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use JSON qw(decode_json);
use Acme::URL;

# print the json
say http://twitter.com/statuses/show/6592721580.json;

# => "He nose the truth."
say decode_json( http://twitter.com/statuses/show/6592721580.json )->{text};