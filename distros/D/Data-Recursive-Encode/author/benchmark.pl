use strict;
use warnings;
use utf8;
use Benchmark qw(:all);
use lib './lib';
use Data::Visitor::Encode;
use Data::Recursive::Encode;
 
my $cmp = timethese(
    20000,
    {
        data_recursive => sub {
            my $sample = { key => ["これはサンプルです","これはサンプルです"] };
            Data::Recursive::Encode->encode('utf8', $sample)
        },
        data_visitor   => sub {
            my $sample = { key => ["これはサンプルです","これはサンプルです"] };
            Data::Visitor::Encode->encode('utf8', $sample)
        },
    }
);
 
cmpthese $cmp;
