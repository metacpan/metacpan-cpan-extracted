#!/usr/bin/perl -w

use strict;
use Test;
#use warnings;

# First check that the module loads OK.
use vars qw($loaded);
BEGIN {  $| = 1;  plan tests => 11; }
END {print "not ok 1\n" unless $loaded;}

use Config::File;
print "! Testing module load ...\n";
ok(++$loaded);

print "! Testing constructor ...\n";
my $config = Config::File::read_config_file("t/config");
ok($config);

print "! Testing simple values ...\n";
ok($config->{foo}, 'bar');

print "! Testing embeded values ...\n";
ok($config->{bar}, 'bar/bar');

print "! Testing comments do not affect prior characters ...\n";
ok($config->{comment_limit}, 'Complete value');

print "! Testing embeded values with comment...\n";
ok($config->{foobar}, 'bar/bar # variable #');

print "! Testing quotes within values...\n(got: $config->{quoted}\n\n";
ok($config->{quoted}, '"foo \'bar baz\'"');

print "! Testing clustered values...\n";
ok($config->{dummy}->{1}, 'data 1');
ok($config->{dummy}->{2}, 'data 2');
ok($config->{dummy}->{3}, 'data 3');

print "! Testing whether we correctly ignore invalid keys\n";
ok(scalar(keys %$config), 6);
