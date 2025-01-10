use strict;
use warnings;
# vim: set ts=8 sts=2 sw=2 tw=100 et :

use Test::More 0.88;
use Test::Warnings 0.009 ':no_end_test', ':all';
use Acme::LookOfDisapproval;

my $line; my $file = __FILE__;
is(
    warning { ಠ_ಠ('oh noes'); $line = __LINE__ },
    "oh noes at $file line $line.\n",
    'warning appears, and with the right file and line',
);

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
