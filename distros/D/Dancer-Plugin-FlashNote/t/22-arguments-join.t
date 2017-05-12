# vim: filetype=perl :
use strict;
use warnings;

use Test::More import => ['!pass'];

plan tests => 6;

use Dancer ':syntax';
use Dancer::Test;
use File::Spec::Functions qw( rel2abs );

setting views => rel2abs(path(qw( t views )));
#setting template => 'template_toolkit';
setting plugins => {
   FlashNote => {
      queue => 'single',
      arguments => 'join',
   },
};

use_ok 'Dancer::Plugin::FlashNote';

ok(get('/' => sub {
   flash(qw( whatever you do ));
   template single => {where => 'root'};
}),
   'root route');

route_exists [GET => '/'];

response_content_is([GET => '/'], "root: whateveryoudo\n");
{
   local $, = ' ';
   response_content_is([GET => '/'], "root: whatever you do\n");
}
response_content_is([GET => '/'], "root: whateveryoudo\n");
