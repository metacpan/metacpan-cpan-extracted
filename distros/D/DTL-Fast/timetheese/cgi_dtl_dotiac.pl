#!/usr/bin/perl -I../blib/lib -I../blib/arch
use Dotiac::DTL qw/Template Context/;

@Dotiac::DTL::TEMPLATE_DIRS = ('./tpl');
$Dotiac::DTL::CURRENTDIR = './tpl';

my $context = {
    'var1' => 'This',
    'var2' => 'is',
    'var3' => 'SPARTA',
    'var4' => 'GREEKS',
    'var5' => 'GO HOME!',
    'array1' => [qw( this is a text string as array )],
};

my $t=Dotiac::DTL::Template('root.txt');
$t->string($context);
