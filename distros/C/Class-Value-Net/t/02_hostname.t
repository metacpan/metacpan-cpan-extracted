#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Error::Hierarchy::Test 'throws2_ok';
use Class::Value;
use Class::Value::Net::Hostname;
use Error ':try';
$Class::Value::SkipChecks = 0;
my @not_ok_values = qw(
  BAR
  -foo.at
  foo-.at
  blubb_blubb.org
  12.34.56.78
);
my %ok_values = (
    '123.at'       => '123.at',
    'foo.at.'      => 'foo.at',
    'a12.34.56.78' => 'a12.34.56.78',
);
plan tests => @not_ok_values + keys %ok_values;
my $obj = Class::Value::Net::Hostname->new;

for (@not_ok_values) {
    throws2_ok { $obj->value($_) }
    'Class::Value::Net::Exception::MalformedHostname',
      qr/^Malformed hostname \[$_\]$/,
      sprintf "malformed hostname '%s'", $_;
}
while (my ($hostname, $normalized) = each %ok_values) {
    try {
        $obj->value($hostname);
        is("$obj", $normalized, "valid hostname '$hostname'");
    }
    catch Error with {
        fail(sprintf "valid hostname '%s' raised exception: '%s'",
            $hostname, shift);
    };
}
