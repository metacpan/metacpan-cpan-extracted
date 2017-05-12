use strict;
use warnings;

package TestApp::Other;
use Test::More;

sub import {
    my $class = shift;
    my $arg   = shift;

    pass('TestApp::Other used');
    is($arg, 'Something', 'TestApp::Other passed Something');
}

1;
