#!/usr/bin/perl
package Test;
use Test::More;
BEGIN {
    use_ok('Adam');
    use_ok('Moses');
}

diag("Testing Adam $Adam::VERSION");
diag("Testing Moses $Moses::VERSION");

done_testing();