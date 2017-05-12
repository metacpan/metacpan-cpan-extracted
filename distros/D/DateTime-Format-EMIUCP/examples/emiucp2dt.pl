#!/usr/bin/perl

use DateTime::Format::EMIUCP;

die "Usage: $0 scts\n" unless @ARGV;

my $dt = DateTime::Format::EMIUCP->parse_datetime($ARGV[0]);
print $dt->datetime, "\n";
