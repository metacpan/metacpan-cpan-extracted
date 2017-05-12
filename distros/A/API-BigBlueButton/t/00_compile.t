#!/usr/bin/env perl

use strict;
use warnings;
use Test::More  tests => 3;

use FindBin qw/ $Bin /;
use lib "$Bin/../lib";

my @modules = qw/ API::BigBlueButton API::BigBlueButton::Requests API::BigBlueButton::Response /;

for my $module ( @modules ) {
    require_ok( $module );
}

done_testing;
