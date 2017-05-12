
=head1 DESCRIPTION

This test is to illustrate the "do" function load the perl code 
but the end of loading the perl code it will not trigger any end block.
For this case the end block of Test::Builder.  Therefore, the result
of the test is not TAP valid output.

=cut

use strict;
use Test::More 'no_plan';
use Test::Fatal;
use Test::Builder;

local $| = 1;

pass;
pass;
pass;
