use Test::Simple 'no_plan';
use strict;
use lib './lib';
use warnings;
#use CGI::Application::Plugin::TmplInnerOuter;
use lib './t';
use TestOne;

ok(1);

my $t = new TestOne;

ok($t,' instanced');
ok(ref $t,'object is ref');

$t->start_mode('test');

$ENV{CGI_APP_RETURN_ONLY} = 1;
ok( $t->run,'run' );









