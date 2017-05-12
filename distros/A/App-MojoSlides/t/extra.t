use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

$ENV{MOJO_SLIDES_PRESENTATION} = 't/pres/extra.pl';

my $t = Test::Mojo->new('App::MojoSlides');

$t->get_ok('/1')
  ->text_is('p' => 'Hi')
  ->element_exists('script[src="myjs.js"]')
  ->element_exists('link[href="mycss1.css"]')
  ->element_exists('link[href="mycss2.css"]');

$t->get_ok('/2')
  ->text_like('p#finally' => qr/Works/);

done_testing;

