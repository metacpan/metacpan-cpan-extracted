use strict;
use warnings;
# vim: set ts=8 sts=2 sw=2 tw=100 et :

use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8
use Test::More 0.88;
use Test::Warnings 0.009 ':no_end_test', ':all';
use utf8;
use Acme::ಠ_ಠ;
use JSON::PP;

my $line; my $file = __FILE__;
is(
    warning { ಠ_ಠ('oh noes'); $line = __LINE__ },
    "oh noes at $file line $line.\n",
    'warning appears, and with the right file and line',
);

diag '%INC is: ' . JSON::PP->new->ascii->canonical->pretty->encode(\%INC);

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
