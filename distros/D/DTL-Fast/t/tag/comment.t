#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];

$context = DTL::Fast::Context->new({});

$template = DTL::Fast::Template->new( << '_EOT_' );
Simple {% comment Some explanation %} NOT RENDER {% endcomment %} comment test
_EOT_

$test_string = <<'_EOT_';
Simple  comment test
_EOT_

is( $template->render($context), $test_string, 'Simple comment');


$template = DTL::Fast::Template->new( << '_EOT_' );
Simple {% 
comment Some explanation %} 
NOT RENDER {% 
endcomment%} comment test
_EOT_

$test_string = <<'_EOT_';
Simple  comment test
_EOT_

is( $template->render($context), $test_string, 'Simple comment with newlines');

$test_string = <<'_EOT_';
This is commented  test checking  endit
_EOT_

is( get_template( 'comment_top.txt', 'dirs' => $dirs)->render($context), $test_string, 'Comment with inclusion');

done_testing();
