use v5.14;
use warnings;
use Encode;
use utf8;

use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;
my $data = <DATA>;

is(xlate(qw(--xlate-engine=null .+ cpanfile))->run->{result}, 0);

is(xlate(qw(--xlate-engine=null .+))->setstdin($data)->run->stdout, $data);

done_testing;

__DATA__
All men are created equal
