use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Warnings 0.005 ':all';
use utf8;
use Acme::ಠ_ಠ;
use JSON 2;

binmode $_, ':utf8' foreach map { Test::Builder->new->$_ } qw(output failure_output todo_output);
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $line; my $file = __FILE__;
is(
    warning { ಠ_ಠ('oh noes'); $line = __LINE__ },
    "oh noes at $file line $line.\n",
    'warning appears, and with the right file and line',
);

diag '%INC is: ' . JSON->new->ascii(1)->canonical(1)->pretty->encode(\%INC);

done_testing;
