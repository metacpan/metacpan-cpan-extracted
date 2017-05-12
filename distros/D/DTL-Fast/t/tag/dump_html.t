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

my $pref = '<textarea class="dtl_fast_dump_area" style="display:block;height:100px;width:100%;">';
my $suff = '</textarea>';

eval{$template = DTL::Fast::Template->new('{% dump_html %}');};
ok($@ =~ /no variable specified for dumping/, 'Error message if no variable specified');

$template = DTL::Fast::Template->new('{% dump_html include %}');
is( $template->render($context), $pref.DTL::Fast::html_protect(Data::Dumper->Dump([$context->{'ns'}->[-1]->{'include'}], ['context.include'])).$suff, 'Array reference dump_html');

$template = DTL::Fast::Template->new('{% dump_html with.substitution %}');
is( $template->render($context), $pref.DTL::Fast::html_protect(Data::Dumper->Dump([$context->{'ns'}->[-1]->{'with'}->{'substitution'}], ['context.with.substitution'])).$suff, 'Traversed variable dump_html');

$template = DTL::Fast::Template->new('{% dump_html include with.substitution %}');
is( $template->render($context),
    $pref
    .DTL::Fast::html_protect(Data::Dumper->Dump([$context->{'ns'}->[-1]->{'include'}], ['context.include']))
    ."\n"
    .DTL::Fast::html_protect(Data::Dumper->Dump([$context->{'ns'}->[-1]->{'with'}->{'substitution'}], ['context.with.substitution']))
    .$suff
    , 'Several variables dump');


$template = DTL::Fast::Template->new('{% dump_html something %}');
is( $template->render($context), $pref.DTL::Fast::html_protect(Data::Dumper->Dump([$context->{'ns'}->[-1]->{'something'}], ['context.something'])).$suff, 'Undefined dump_html');

$template = DTL::Fast::Template->new('{% dump_html plain_text %}');
is( $template->render($context), $pref.DTL::Fast::html_protect(Data::Dumper->Dump([$context->{'ns'}->[-1]->{'plain_text'}], ['context.plain_text'])).$suff, 'String dump_html');

$template = DTL::Fast::Template->new('{% dump_html plain_html %}');
is( $template->render($context), $pref.DTL::Fast::html_protect(Data::Dumper->Dump([$context->{'ns'}->[-1]->{'plain_html'}], ['context.plain_html'])).$suff, 'HTML text dump_html');

done_testing();
