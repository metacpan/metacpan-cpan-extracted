# vim: filetype=perl :
use strict;
use warnings;

use Test::More import => ['!pass'];

eval "use Template";
plan skip_all => "Template::Toolkit required for testing default" if $@;
plan tests => 16;

use Dancer ':syntax';
use Dancer::Test;
use File::Spec::Functions qw( rel2abs );

setting views => rel2abs(path(qw( t views )));
setting template => 'template_toolkit';
setting plugins  => {
   FlashNote => {
      queue   => 'multiple',
      dequeue => 'when_used',
   },
};

use_ok 'Dancer::Plugin::FlashNote';

ok(get('/' => sub { template multiple => {where => 'root'} }),
   'root route');
ok(
   get(
      '/whine' => sub {
         flash('groan');
         template multiple => {where => 'whine'};
      }
   ),
   'whine route'
);
ok(
   get(
      '/noisy' => sub {
         flash('BOOM!');
         flash('KABOOM!');
         template multiple => {where => 'noisy'};
      }
   ),
   'noisy route'
);
ok(
   get(
      '/fishy' => sub {
         flash('SLIIIME!');
         redirect '/';
      }
   ),
   'fishy route'
);

route_exists [GET => $_] for qw( / /whine /noisy /fishy );

response_content_is([GET => '/'],
   "root:\n", 'response for / has no flash message');
response_content_is([GET => '/whine'], "whine:\n   groan\n\n");
response_content_is([GET => '/'],
   "root:\n", 'response for / has no flash message');
response_content_is([GET => '/noisy'],
   "noisy:\n   BOOM!\n\n   KABOOM!\n\n");
response_content_is([GET => '/'],
   "root:\n", 'response for / has no flash message');
response_content_is([GET => '/fishy'], '',
   'GET /fishy yields redirection');
response_content_is(
   [GET => '/'],
   "root:\n   SLIIIME!\n\n",
   'now response for / has flash message'
);
