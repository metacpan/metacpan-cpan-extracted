#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

use B::RecDeparse;
use B::Deparse;

sub wut { "\x{1c}B::RecDeparse\x{1c}"->() }

my $bd = B::Deparse->new();
my $code = $bd->coderef2text(\&wut);
like $code, qr/B::RecDeparse/, 'single_delim is only fooled when called from B::RecDeparse';
