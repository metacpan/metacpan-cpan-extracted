#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use 5.010;
use strict;
use warnings;

package Foo;

our @EXPORT = qw(f1);
our @EXPORT_OK = qw(f2);

sub import {
    no strict 'refs';
    my $pkg = shift;
    my $caller = caller;
    my @imp = @_ ? @_ : @{__PACKAGE__.'::EXPORT'};
    for my $imp (@imp) {
        if (grep {$_ eq $imp} (@{__PACKAGE__.'::EXPORT'},
                               @{__PACKAGE__.'::EXPORT_OK'})) {
            *{"$caller\::$imp"} = \&{$imp};
        } else {
            die "$imp is not exported by ".__PACKAGE__;
        }
    }
}

package main;

use Test::Exception;
use Test::More 0.98;

lives_ok { Foo->import };
lives_ok { Foo->import("f1") };
lives_ok { Foo->import("f2") };
dies_ok  { Foo->import("f3") };

done_testing;
