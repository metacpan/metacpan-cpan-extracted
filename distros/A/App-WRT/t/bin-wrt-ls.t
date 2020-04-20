#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use 5.10.0;

use lib 'lib';

use Encode;
use Test::More tests => 6;

chdir 'example/blog';
require_ok('../../bin/wrt-ls');

my $output_string;
my $output = sub {
  $output_string .= $_[0] . "\n";
};

my @local_argv = qw(--years);
main($output, @local_argv);
ok(
  $output_string eq "1952\n2012\n2013\n2014\n",
  "Correctly listed years."
);

@local_argv = qw(--months);
$output_string = '';
main($output, @local_argv);
ok(
  $output_string eq "1952/2\n2013/1\n2013/2\n2014/1\n",
  "Correctly listed months."
);

@local_argv = qw(--days);
$output_string = '';
main($output, @local_argv);
ok(
  $output_string eq "1952/2/13\n2014/1/1\n2014/1/2\n",
  "Correctly listed days."
);

@local_argv = qw(--props);
$output_string = '';
main($output, @local_argv);
ok(
  $output_string eq "foo\ntag.animals.platypus\ntag.something\ntag.topics.example\nwrt-noexpand\n",
  "Correctly listed properties."
) or diag($output_string);

@local_argv = qw(--days --months);
$output_string = '';
eval {
  main($output, @local_argv);
};
ok(
  $@,
  "Croaked on trying to combine multiple entry-type options."
);
