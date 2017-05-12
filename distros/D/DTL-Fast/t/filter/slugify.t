#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context(
);

my @strings = (
    'This was a really_awesome 123'
    , 'This was a - really_awesome 123'
    , ' This was a - really_awesome 123'
    , ' This was a - really_awesome 123 блабла '
    , ' This was a -"- really_awesome 123 блабла '
);

$template = DTL::Fast::Template->new('{{ var|slugify }}');
$test_string = 'this-was-a-really_awesome-123';

foreach my $string (@strings)
{
    $context->set('var' => $string);
    is( $template->render($context), $test_string, "'".$string."'");
    
}

done_testing();
