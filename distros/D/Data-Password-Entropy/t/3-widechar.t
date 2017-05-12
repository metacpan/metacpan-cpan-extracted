#!/usr/bin/perl -w

# ------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------

use strict;
use warnings;
use utf8;

use Test::More;

use FindBin qw($Bin);
use lib ("$Bin/../lib");

use Data::Password::Entropy;

&main();
# ------------------------------------------------------------------------------
sub main
{
    plan(tests => 3);

    is(chr(65), 'A', "Is ASCII platform");

    my $warn_thrown = 0;
    local $SIG{__WARN__} = sub {
        my $msg = shift;
        if ($msg =~ /wide/ || $msg =~ /uninitialized/) {
            $warn_thrown = 1;
        }
    };

    is(password_entropy("Хуябрики"), 79, "Wide characters");
    is($warn_thrown, 0, "No warnings");
}
# ------------------------------------------------------------------------------
1;
