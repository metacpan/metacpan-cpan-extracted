use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

$ENV{SCREENORAMA_COMMAND} = 'ls -l';
plan skip_all => "do script/screenorama: $@" unless do 'script/screenorama';

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->text_is('title', 'screenorama - ls -l')->element_exists('.shell span.output')
  ->element_exists('.shell span.cursor');

done_testing;
