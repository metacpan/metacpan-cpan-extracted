# vim: filetype=perl :
use strict;
use warnings;

use Test::More import => ['!pass'];

eval "use Template";
plan skip_all => "Template::Toolkit required for testing default" if $@;
#plan tests => 16;
plan 'no_plan';

use Dancer ':syntax';
use Dancer::Test;
use File::Spec::Functions qw( rel2abs );

setting views => rel2abs(path(qw( t views )));
setting template => 'template_toolkit';
setting plugins  => {
   FlashNote => {
      queue   => 'key_single',
      dequeue => 'by_key',
   },
};
use_ok 'Dancer::Plugin::FlashNote';

ok(get('/' => sub { template key_single => {where => 'root'} }),
   'root route');
ok(
   get(
      '/whine' => sub {
         flash(warn  => 'groan');
         flash(error => 'GROAN');
         template key_warn => {where => 'whine'};
      }
   ),
   'whine route'
);

route_exists [GET => $_] for qw( / /whine );

response_content_is(
   [GET => '/'],
   "root:\n   ''\n   ''\n",
   'response for / has no flash message'
);
response_content_is([GET => '/whine'], "whine:\n* warn: 'groan'\n");
response_content_is(
   [GET => '/'],
   "root:\n   ''\n   'GROAN'\n",
   'response for / collects unused keys'
);
response_content_is(
   [GET => '/'],
   "root:\n   ''\n   ''\n",
   'response for / is now empty'
);
