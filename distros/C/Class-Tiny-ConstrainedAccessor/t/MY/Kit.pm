#!perl
# Kit: Test kit for Class::Tiny::ConstrainedAccessor
package MY::Kit;

use 5.006;
use strict;
use warnings;
use Test::More ();
use Test::Exception ();
use Test::Fatal ();

use Import::Into;

sub import {
    my $target = caller;
    $_->import::into($target) foreach
        qw(strict warnings Test::More Test::Exception Test::Fatal);
} #import()

1;
