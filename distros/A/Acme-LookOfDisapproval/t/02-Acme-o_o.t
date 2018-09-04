use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings 0.009 ':no_end_test', ':all';
use utf8;
use Acme::ಠ_ಠ;
use JSON::PP;

binmode Test::More->builder->$_, ':encoding(UTF-8)' foreach qw(output failure_output todo_output);
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $line; my $file = __FILE__;
is(
    warning { ಠ_ಠ('oh noes'); $line = __LINE__ },
    "oh noes at $file line $line.\n",
    'warning appears, and with the right file and line',
);

diag '%INC is: ' . JSON::PP->new->ascii->canonical->pretty->encode(\%INC);

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
