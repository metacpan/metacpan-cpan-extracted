# vim: filetype=perl :
use strict;
use warnings;

use Test::More import => ['!pass'];

eval "use Template";
plan skip_all => "Template::Toolkit required for testing default" if $@;
plan tests => 4;

use Dancer ':syntax';
use Dancer::Test;
use File::Spec::Functions qw( rel2abs );

setting views => rel2abs(path(qw( t views )));
setting template => 'template_toolkit';
setting plugins => {
   FlashNote => {
      queue => 'single',
      arguments => 'array',
   },
};

use_ok 'Dancer::Plugin::FlashNote';

ok(get('/' => sub {
   flash(qw( whatever you do ));
   template array => {where => 'root'};
}),
   'root route');

route_exists [GET => '/'];

response_content_is([GET => '/'], "root: whatever*you*do\n");
