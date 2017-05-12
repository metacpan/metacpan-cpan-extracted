

use strict;
use warnings;

use Test::More tests => 1;

use Data::FreqConvert;

use Data::Printer;
use blib;
subtest default => sub {
    plan tests => 2;

    my $data = Data::FreqConvert->new();
    my @a = ("a","b","c","a");
    my $b = "a\nb\nc\nc";

    my $ra = $data->freq(\@a);# for @test;

    my $rb = $data->freq($b);# for @test;
    my $r1 = {a=>2,b=>1,c=>1};
    my $r2 = {a=>1,b=>1,c=>2};

    is_deeply($ra,$r1);
    is_deeply($rb,$r2);

    #is_deeply($field, {type => 'text', aggregate => 'count', sort => 'score', order => 'desc'});
};
1;
