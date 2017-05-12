#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Acme::Lingua::ZH::Remix;

my $str = Acme::Lingua::ZH::Remix->new->random_sentence;

ok($str);

done_testing;
