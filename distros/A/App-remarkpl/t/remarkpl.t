use Mojo::Base -strict;
use Mojo::File 'path';
use Test::Mojo;
use Test::More;

$ENV{MOJO_APP_LOADER} = 1;
plan skip_all => $@ unless do(path(qw(script remarkpl))->to_abs);
my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->text_is('title', 'example.markdown - remarkpl')
  ->element_exists('head > link[href="/fonts.css"]')
  ->element_exists('head > link[href="/basic.css"]')
  ->element_exists('body > script[src="/remark.min.js"]')
  ->element_exists('body > script[src="/custom.js"]')
  ->content_like(qr{<script>const slideshow = remark\.create\(\);</script>})
  ->text_like('textarea', qr{\# remark presentation example.*The end}s);

$t->get_ok('/fonts.css')->status_is(200);
$t->get_ok('/basic.css')->status_is(200);
$t->get_ok('/remark.min.js')->status_is(200);
$t->get_ok('/custom.js')->status_is(200);

done_testing;
