#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use DTL::Fast::Tag::Debug;
use Data::Dumper;

my( $template, $test_string, $context);

my @LAST_WARNING;
local $SIG{__WARN__} = sub { # here we get the warning
    @LAST_WARNING = @_;
#    print STDERR $_[0];
}; 


my $dirs = ['./t/tmpl', './t/tmpl2'];
$context = new DTL::Fast::Context({
    'include' => ['included2.txt']
    , 'with' => {
        'substitution' => 'context text'
    }
    , 'plain_text' => 'plain_value'
    , 'plain_html' => 'plain_value <with> some tags'
});

eval{$template = DTL::Fast::Template->new('{% dump_warn %}');};
ok($@ =~ /no variable specified for dumping/, 'Error message if no variable specified');

$template = DTL::Fast::Template->new('{% dump_warn include %}');
$template->render($context);
is( $LAST_WARNING[0], Data::Dumper->Dump([$context->{'ns'}->[-1]->{'include'}], ['context.include']), 'Array reference dump_warn');

$template = DTL::Fast::Template->new('{% dump_warn with.substitution %}');
$template->render($context);
is( $LAST_WARNING[0],  Data::Dumper->Dump([$context->{'ns'}->[-1]->{'with'}->{'substitution'}], ['context.with.substitution']), 'Traversed variable dump_warn');

$template = DTL::Fast::Template->new('{% dump_warn include with.substitution %}');
$template->render($context);
is( $LAST_WARNING[0], 
    Data::Dumper->Dump([$context->{'ns'}->[-1]->{'include'}], ['context.include'])
    ."\n"
    .Data::Dumper->Dump([$context->{'ns'}->[-1]->{'with'}->{'substitution'}], ['context.with.substitution'])
    , 'Several variables dump_warn');

$template = DTL::Fast::Template->new('{% dump_warn something %}');
$template->render($context);
is( $LAST_WARNING[0], Data::Dumper->Dump([$context->{'ns'}->[-1]->{'something'}], ['context.something']), 'Undefined dump_warn');

$template = DTL::Fast::Template->new('{% dump_warn plain_text %}');
$template->render($context);
is( $LAST_WARNING[0], Data::Dumper->Dump([$context->{'ns'}->[-1]->{'plain_text'}], ['context.plain_text']), 'String dump_warn');

$template = DTL::Fast::Template->new('{% dump_warn plain_html %}');
$template->render($context);
is( $LAST_WARNING[0], Data::Dumper->Dump([$context->{'ns'}->[-1]->{'plain_html'}], ['context.plain_html']), 'HTML text dump_warn (as is)');

done_testing();
