# vim: filetype=perl :
use strict;
use warnings;

#use Test::More tests => 1, import => ['!pass']; # last test to print
use Test::More import => ['!pass'];
#plan 'no_plan';
plan tests            => 20;

use Dancer ':syntax';
use Dancer::Test;
use File::Spec::Functions qw( rel2abs );

setting views => rel2abs(path(qw( t views )));
setting plugins => {
   FlashNote => {
      queue   => 'single',
      dequeue => 'never',
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
ok(
   get(
      '/noisy' => sub {
         flash('BOOM!');
         flash('KABOOM!');
         template single => {where => 'noisy'};
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
   "root: \n", 'response for / has no flash message');
response_content_is([GET => '/whine'], "whine: groan\n");
response_content_is([GET => '/'],      "root: groan\n");
response_content_is([GET => '/noisy'], "noisy: KABOOM!\n");
response_content_is([GET => '/'],      "root: KABOOM!\n");
response_content_is([GET => '/'],      "root: KABOOM!\n");
flash_flush();
response_content_is([GET => '/'], "root: \n", 'root after flash_flush()');

response_content_is([GET => '/fishy'], '',
   'GET /fishy yields redirection');
response_content_is([GET => '/'], "root: SLIIIME!\n",);
response_content_is([GET => '/'], "root: SLIIIME!\n",);

flash_flush();
response_content_is([GET => '/'], "root: \n", 'root after flash_flush()');
