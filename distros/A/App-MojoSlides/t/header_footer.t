use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

$ENV{MOJO_SLIDES_PRESENTATION} = 't/pres/header_footer.pl';

my $t = Test::Mojo->new('App::MojoSlides');

$t->get_ok('/1')
  ->text_is('#myheader' => 'Mojo')
  ->text_is('#myfooter' => 'Slides');

done_testing;

