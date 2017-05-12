#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
  use_ok( 'CGI::Application::Plugin::Output::XSV', qw(xsv_report) );
}

my $report;

my @vals = qw(one two three four five six);

# using iterator to generate values list.
# setting stream parameter to force immediate output, no return value

open(SAVESTDOUT, '>&', STDOUT) or die "Can't dup STDOUT: $!";
close(STDOUT);
open(STDOUT, '>', \$report) or die "Can't redirect STDOUT: $!";

my $ret = xsv_report({
  fields    => [ qw(foo) ],
  iterator  => sub { while ( @vals ) { return [ splice @vals, 0, 1 ] } },
  stream    => 1,
});

is( $ret, "", "empty return value when streaming enabled" );

is( $report, "Foo\none\ntwo\nthree\nfour\nfive\nsix\n",
             "streaming output works" );

open(STDOUT, '>&', SAVESTDOUT) or die "Can't restore STDOUT: $!"
