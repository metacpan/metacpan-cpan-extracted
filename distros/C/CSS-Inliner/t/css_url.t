#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;

use_ok( 'CSS::Inliner' );

my $inliner = new CSS::Inliner();

my $input = <<IN;
<html>
  <head>
    <style type="text/css">
    h4 {
	background-image: url(http://www.example.com/test.jpg);
       }</style>
  </head>
  <body>
  <h4>Test header with background</h4>
</body>
</html>
IN

$inliner->read({ html => $input });

my $actual = $inliner->inlinify();

ok ($actual =~ m{url\(http://www.example.com/test.jpg\)}, 'url in style');

done_testing;

