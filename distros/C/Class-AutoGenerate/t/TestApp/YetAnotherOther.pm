use strict;
use warnings;

package TestApp::YetAnotherOther;
use Test::More;

sub import {
    my $class = shift;
    my $arg   = shift;

    pass('TestApp::YetAnotherOther used');
    is($arg, undef, 'TestApp::YetAnotherOther passed undef');
}

1;
