#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => '"string"'
    , 'var2' => 0
    , 'var3' => 15
    , 'var4' => 3
    , 'var5' => 2
    , 'var6' => undef
});

my $SET = [
];

use Scalar::Util qw(looks_like_number);

for( my $i = 1; $i < 7; $i++ )
{
    my $var1_name = "var$i";
    my $var1 = $context->get($var1_name);

    for( my $j = 1; $j < 7; $j++ )
    {
        my $var2_name = "var$j";
        my $var2 = $context->get($var2_name);
        
        my $validator = sub
        {
            my $var1 = shift;
            my $var2 = shift;
            return (
                looks_like_number($var1)
                and looks_like_number($var2)
                and $var2 != 0
                and not ($var1 % $var2)
            ) ? 1: 0;
        };
        
        my $data = sub{
            my $var1 = shift;
            my $var2 = shift;
            my $test = shift;
            
            return {
                'template' => sprintf('{{ %s|divisibleby:%s }}', $var1 // 'undef', $var2 // 'undef'),
                'test' => $test,
                'title' => sprintf('%s by %s', $var1 // 'undef', $var2 // 'undef')
            };
        };
        
        push @$SET, $data->($var1, $var2, $validator->($var1,$var2));
        push @$SET, $data->($var1_name, $var2_name, $validator->($var1,$var2));
        push @$SET, $data->($var1, $var2_name, $validator->($var1,$var2));
        push @$SET, $data->($var1_name, $var2, $validator->($var1,$var2));
        
    }
}


foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
