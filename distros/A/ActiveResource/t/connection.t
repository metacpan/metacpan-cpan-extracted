#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;

use ActiveResource::Connection;

my $conn = ActiveResource::Connection->new;

ok($conn->can($_)) for qw(get post put);

done_testing;
