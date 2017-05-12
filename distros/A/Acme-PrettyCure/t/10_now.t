use strict;
use warnings;
use utf8;
use Test::More;

use Acme::PrettyCure;

my @now = Acme::PrettyCure->now;
my @dokidoki = Acme::PrettyCure->girls('DokiDoki');

is_deeply \@now, \@dokidoki, 'now "DokiDoki! Precure"';

done_testing;

