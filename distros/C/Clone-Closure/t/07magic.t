#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Clone::Closure qw/clone/;

my $tests;

BEGIN { $tests += 1 }
SKIP: {
    eval "use Scalar::Util qw( weaken ); 1";
    skip "Scalar::Util not installed", 1 if $@;

    my $x = { a => "worked\n" }; 
    my $y = $x;
    weaken($y);
    my $z = clone $x;
    is Dumper($x), Dumper($z), 'cloned weak reference';
}

## RT 21859: Clone::Closure segfault (isolated example)
BEGIN { $tests += 1 }
SKIP: {
    my $string = "HDDR-WD-250JS";
    eval {
      use utf8;
      utf8::upgrade($string);
    };
    skip $@, 1 if $@;

    $string = sprintf '<<bg_color=%s>>%s<</bg_color>>%s',
          '#EA0',
          substr($string, 0, 4),
          substr($string, 4);
    my $z = clone $string;
    is Dumper($string), Dumper($z), 'cloned magic utf8';
}

BEGIN { $tests += 1 }
SKIP: {
    eval "use Taint::Runtime qw(enable taint_env)";
    skip "Taint::Runtime not installed", 1 if $@;

    taint_env();
    my $x = "";
    for (keys %ENV) {
        $x = $ENV{$_};
        last if ( $x && length($x) > 0 );
    }
    my $y = clone $x;
    is Dumper($x), Dumper($y), 'Tainted input';
}

BEGIN { plan tests => $tests }
