#!/usr/bin/perl -w
use strict;
use lib 't/lib';
use Test::More qw(no_plan);

my $sample_file  = 't/sample.conf';
my $sample_conf  = <<ENDCONF;
[error_type]
bad_request  = 400
unauthorized = 401
not_found    = 404

ENDCONF

open(CONF, ">$sample_file");
print CONF $sample_conf;
close(CONF);

use Test::Config::Singleton;
Test::Config::Singleton->file($sample_file);
my $config;
ok( $config = Test::Config::Singleton->instance );
isa_ok( $config, "Test::Config::Singleton" );
is($config->{error_type}{bad_request},  400);
is($config->{error_type}{unauthorized}, 401);
is($config->{error_type}{not_found},    404);

END{ unlink $sample_file; }

