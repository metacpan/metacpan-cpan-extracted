# vim: filetype=perl :
use strict;
use warnings;

use Test::More import => ['!pass'];

eval "use Template";
plan skip_all => "Template::Toolkit required for testing default" if $@;
plan tests => 7;

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

ok(get('/single' => sub {
   flash('whatever');
   template auto => {where => '/single'};
}),
   'single route');

ok(get('/multiple' => sub {
   flash(qw( whatever you do ));
   template auto => {where => '/multiple'};
}),
   'multiple route');

route_exists [GET => $_] for qw( /single /multiple );

response_content_is([GET => '/single'], "/single: whatever\n");
response_content_is([GET => '/multiple'], "/multiple: whatever*you*do\n");
