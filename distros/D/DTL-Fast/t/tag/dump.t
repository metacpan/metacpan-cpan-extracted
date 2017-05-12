#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use DTL::Fast::Tag::Debug;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];
$context = new DTL::Fast::Context({
    'include' => ['included2.txt']
    , 'with' => {
        'substitution' => 'context text'
    }
    , 'plain_text' => 'plain_value'
    , 'plain_html' => 'plain_value <with> some tags'
});

eval{$template = DTL::Fast::Template->new('{% dump %}');};
ok($@ =~ /no variable specified for dumping/, 'Error message if no variable specified');

$template = DTL::Fast::Template->new('{% dump include %}');
is( $template->render($context), Data::Dumper->Dump([$context->{'ns'}->[-1]->{'include'}], ['context.include']), 'Array reference dump');

$template = DTL::Fast::Template->new('{% dump with.substitution %}');
is( $template->render($context), Data::Dumper->Dump([$context->{'ns'}->[-1]->{'with'}->{'substitution'}], ['context.with.substitution']), 'Traversed variable dump');

$template = DTL::Fast::Template->new('{% dump include with.substitution %}');
is( $template->render($context),
    Data::Dumper->Dump([$context->{'ns'}->[-1]->{'include'}], ['context.include'])
    ."\n"
    .Data::Dumper->Dump([$context->{'ns'}->[-1]->{'with'}->{'substitution'}], ['context.with.substitution'])
    , 'Several variables dump');

$template = DTL::Fast::Template->new('{% dump something %}');
is( $template->render($context), Data::Dumper->Dump([$context->{'ns'}->[-1]->{'something'}], ['context.something']), 'Undefined dump');

$template = DTL::Fast::Template->new('{% dump plain_text %}');
is( $template->render($context), Data::Dumper->Dump([$context->{'ns'}->[-1]->{'plain_text'}], ['context.plain_text']), 'String dump');

$template = DTL::Fast::Template->new('{% dump plain_html %}');
is( $template->render($context), Data::Dumper->Dump([$context->{'ns'}->[-1]->{'plain_html'}], ['context.plain_html']), 'HTML text dump (as is)');

done_testing();
