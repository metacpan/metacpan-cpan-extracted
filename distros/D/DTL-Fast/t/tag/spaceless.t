#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;
use Date::Format;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];

$context = DTL::Fast::Context->new({
});


$template = << '_EOT_';
{% spaceless %} <p>
    <div>
        This is a text
    </div>
</p>    {% endspaceless %}
_EOT_
$test_string = << '_EOT_';
<p><div>
        This is a text
    </div></p>
_EOT_

is( DTL::Fast::Template->new($template)->render($context), $test_string, 'Tags spaces removal');


done_testing();
