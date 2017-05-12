use strict;
use warnings;

package TestApp::AnotherOther;
use Test::More;

sub import {
    my $class = shift;
    my $arg   = shift;

    pass('TestApp::AnotherOther used');
    is($arg, undef, 'TestApp::AnotherOther passed undef');
}

1;
