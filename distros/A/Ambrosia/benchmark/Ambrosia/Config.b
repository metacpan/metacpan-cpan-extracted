#!/usr/bin/perl
use strict;
use warnings;
use lib qw(lib t);

use Benchmark;

use Ambrosia::Config;

my $i = 0;
my $h = { param1 => 123, param2 => 456 };

timethese(10_000, {
        'config create'    => sub {
            instance Ambrosia::Config( 'test'.$i++ => $h );
        },
});


instance Ambrosia::Config( 'test' => $h );
Ambrosia::Config::assign 'test';

timethese(100_000, {
        'config create'    => sub {
            my $p = config->param1;
        },
});

