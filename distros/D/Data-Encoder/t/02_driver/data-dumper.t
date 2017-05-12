use strict;
use warnings;
use Test::Requires 'Data::Dumper';
use Data::Encoder::Data::Dumper;
use Test::More;
use t::Util;

show_version('Data::Dumper');

subtest 'simple' => sub {
    my $encoder = Data::Encoder::Data::Dumper->new;
    my $data = $encoder->encode(['foo']);

    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Indent = 0;

    is $data, Data::Dumper::Dumper(['foo']);
    is_deeply $encoder->decode($data), ['foo'];

    done_testing;
};

subtest 'args' => sub {
    my $encoder = Data::Encoder::Data::Dumper->new({ Useqq => 1 });
    my $data = $encoder->encode(['$hoge']);
    
    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq  = 1;

    is $data, Data::Dumper::Dumper(['$hoge']);
    is_deeply $encoder->decode($data), ['$hoge'];

    done_testing;
};

done_testing;
