#!/usr/bin/perl

use DateTime::Format::ISO8601;
use DateTime::Format::EMIUCP::SCTS;

die "Usage: $0 scts\n" unless @ARGV;

my $dt = DateTime::Format::ISO8601->parse_datetime($ARGV[0]);
$dt->set_formatter(DateTime::Format::EMIUCP::SCTS->new);
print $dt, "\n";
