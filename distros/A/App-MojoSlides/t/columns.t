use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

$ENV{MOJO_SLIDES_PRESENTATION} = 't/pres/columns.pl';

my $t = Test::Mojo->new('App::MojoSlides');

$t->get_ok('/1')
  ->text_is('.row .col-md-6 p' => 'Column w 6')
  ->text_is('.row .col-md-3.col-md-offset-3 p' => 'Column w 3 o 3');

done_testing;

