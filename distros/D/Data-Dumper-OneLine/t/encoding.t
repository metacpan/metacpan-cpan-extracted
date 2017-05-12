use strict;
use warnings;
use utf8;
use lib 't/lib';
use Test::More;
use Data::Dumper::OneLine;
use Encode;

{
    local $Data::Dumper::OneLine::Encoding = 'utf8';
    is(
        Dumper({ foo => { bar => 'あ' }}),
        encode_utf8("{foo => {bar => 'あ'}}"),
    );
}
{
    is(
        Dumper({ foo => { bar => 'あ' }}),
        '{foo => {bar => "\x{3042}"}}',
    );
}

done_testing;

