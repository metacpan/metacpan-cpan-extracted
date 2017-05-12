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
      queue   => 'key_multiple',
      dequeue => 'when_used',
   },
};
use_ok 'Dancer::Plugin::FlashNote';

ok(get('/' => sub { template key_multiple => {where => 'root'} }),
   'root route');
ok(
   get(
      '/whine' => sub {
         flash(warn  => 'groan');
         flash(error => 'GROAN');
         template key_multiple => {where => 'whine'};
      }
   ),
   'whine route'
);
ok(
   get(
      '/noisy' => sub {
         flash(warn  => 'BOOM!');
         flash(error => 'kaboom!');
         flash(error => 'KABOOM!');
         template key_multiple => {where => 'noisy'};
      }
   ),
   'noisy route'
);
ok(
   get(
      '/fishy' => sub {
         flash(warn => 'SLIIIME!');
         redirect '/';
      }
   ),
   'fishy route'
);

route_exists [GET => $_] for qw( / /whine /noisy /fishy );

response_content_is([GET => '/'],
   "root:\n", 'response for / has no flash message');
response_content_is(
   [GET => '/whine'], "whine:
* warn: 'groan'
* error: 'GROAN'\n"
);
response_content_is([GET => '/'],
   "root:\n", 'response for / has no flash message');
response_content_is(
   [GET => '/noisy'], "noisy:
* warn: 'BOOM!'
* error: 'kaboom!'
* error: 'KABOOM!'\n"
);
response_content_is([GET => '/'],
   "root:\n", 'response for / has no flash message');
response_content_is([GET => '/fishy'], '',
   'GET /fishy yields redirection');
response_content_is(
   [GET => '/'],
   "root:\n* warn: 'SLIIIME!'\n",
   'now response for / has flash message'
);

