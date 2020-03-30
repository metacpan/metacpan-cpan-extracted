use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use Data::Dumper;

use lib '.';
use t::Util;
$Script::lib    = File::Spec->rel2abs('lib');
$Script::script = File::Spec->rel2abs('script/week');

my %result = (
'157209' => <<END
                          
        September         
   Su Mo Tu We Th Fr Sa   
          1  2 14 15 16   
   17 18 19 20 21 22 23   
   24 25 26 27 28 29 30   
                          
                          
                          
                          
END
);

$ENV{LANG} = $ENV{LC_ALL} = 'C';

my $week = Script->new([qw(--cm *= -C0 1752/9/2)])->run;
is($week->result, $result{157209}, "1752/9/2");

done_testing;
