# vim: filetype=perl :
use strict;
use warnings;

#use Test::More tests => 1, import => ['!pass']; # last test to print
use Test::More import => ['!pass'];
plan tests => 8;

use Dancer ':syntax';
use Dancer::Test;
use File::Spec::Functions qw( rel2abs );

setting views => rel2abs(path(qw( t views )));
setting plugins => {
   FlashNote => {
      queue   => 'single',
      dequeue => 'when_used',
   },
};
use_ok 'Dancer::Plugin::FlashNote';

ok(get('/' => sub { template single => {where => 'root'} }), 'root route');
ok(
   get(
      '/whine' => sub {
         flash('groan');
         template single => {where => 'whine'};
      }
   ),
   'whine route'
);

route_exists [GET => $_] for qw( / /whine );

response_content_is([GET => '/'],
   "root: \n", 'response for / has no flash message');
response_content_is([GET => '/whine'], "whine: groan\n");
response_content_is([GET => '/'],
   "root: \n", 'response for / has no flash message');
