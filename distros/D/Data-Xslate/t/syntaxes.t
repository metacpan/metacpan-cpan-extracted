#!/usr/bin/env perl
use Test2::Bundle::Extended;
use strictures 2;

use Data::Xslate;

foreach my $KS (qw( . / - = KS \\ )) {
    foreach my $NKT (qw( = := . NKT \\ )) {
        foreach my $ST (qw( = =: . ST \\ )) {
            subtest "key_separator:$KS nested_key_tag:$NKT substitution_separator:$ST" => sub{
                my $xslate = Data::Xslate->new(
                    key_separator    => $KS,
                    nested_key_tag   => $NKT,
                    substitution_tag => $ST,
                );

                test_xslate(
                    $xslate,
                    { a=>{b=>3}, c=>"<: node('a${KS}b') :>" },
                    { a=>{b=>3}, c=>3 },
                    'template',
                );

                test_xslate(
                    $xslate,
                    { a=>{b=>5}, c=>"${ST}a${KS}b" },
                    { a=>{b=>5}, c=>5 },
                    'substitution',
                );

                test_xslate(
                    $xslate,
                    { a=>{b=>1}, "a${KS}b$NKT" => 2 },
                    { a=>{b=>2} },
                    'nested key',
                );
            };
        }
    }
}

done_testing;

sub test_xslate {
    my ($xslate, $data, $expected, $message) = @_;

    my $actual = $xslate->render( $data );

    return is(
        $actual,
        $expected,
        $message,
    );
}
