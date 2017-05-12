use strict;
use warnings;
use Test::More;

use App::plmetrics;

my $plm = App::plmetrics->new;
isa_ok $plm, 'App::plmetrics';

done_testing;
