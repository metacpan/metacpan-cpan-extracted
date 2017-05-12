#! perl
use Test::More;

if (eval "use CGI::Prototype::Mecha; 1") {
  plan no_plan;
} else {
  plan skip_all => 'CGI::Prototype::Mecha required for testing CGIPH';
}

use lib qw(t/TestApp TestApp);

isa_ok
  my $m = CGI::Prototype::Mecha->new(protoapp => 'My::App'),
  'CGI::Prototype::Mecha';
ok $m->get('http://mecha/'),
  'welcome page fetched';
is $m->status, 200,
  'welcome page status ok';
# $m->diag_forms;
like $m->content, qr/Enter your name/,
  'welcome page contains correct content';

## empty fields should stay on same page
ok $m->submit_form
  (fields => {first => '', last => ''});
is $m->status, 200,
  'welcome page status ok';
like $m->content, qr/Enter your name/,
  'welcome page contains correct content';

## only one should stay on same page
ok $m->submit_form
  (fields => {first => 'Fred', last => ''});
is $m->status, 200,
  'welcome page status ok';
like $m->content, qr/Enter your name/,
  'welcome page contains correct content';

## only other should stay on same page
ok $m->submit_form
  (fields => {first => '', last => 'Flintstone'});
is $m->status, 200,
  'welcome page status ok';
like $m->content, qr/Enter your name/,
  'welcome page contains correct content';

## both should go to thanks page
ok $m->submit_form
  (fields => {first => 'Fred', last => 'Flintstone'});
is $m->status, 200,
  'thanks page status ok';
like $m->content, qr/Thanks for stopping by,\s*Fred Flintstone!/,
  'thanks page contains correct content';

