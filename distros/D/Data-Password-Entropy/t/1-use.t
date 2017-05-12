#!/usr/bin/perl -w

# ------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------

use strict;
use warnings;

use Test::More 0.88 tests => 3;

use FindBin qw($Bin);
use lib ("$Bin/../lib");

BEGIN
{
    use_ok('Data::Password::Entropy');
    isa_ok('Data::Password::Entropy', 'Exporter');
}

&main();
# ------------------------------------------------------------------------------
sub main
{
    is(password_entropy(undef),	0, 'Undefined value');
}
# ------------------------------------------------------------------------------
1;
