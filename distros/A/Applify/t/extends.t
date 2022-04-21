use warnings;
use strict;
use Test::More;

plan skip_all => 'Skipped on 5.10.1' unless eval 'require 5.12.0;1';

package BaseClass;
sub meta {'i am not moose'}

my $app = eval <<"HERE" or die $@;
package main;
sub not_app_method { 1 }
use Applify;
sub app::foo { 1 }
sub bar { 1 }
sub AUTOLOAD { 'Autoloaded' }
extends 'BaseClass';
app { 0 };
HERE

package main;
my $script = $app->_script;

ok !app->can('foo'),              'foo() was removed from app:: namespace';
ok !main->can('bar'),             'bar() was removed from main:: namespace';
ok !!main->can('not_app_method'), 'not_app_method() was not removed from main:: namespace';
ok !!$app->can('foo'),            '...and into the $app namespace';
ok !$app->can('not_app_method'),  'not_app_method() was not applied to app class';
ok !$app->can('app'),             'app() was not applied to app class';
ok !$app->can('option'),          'option() was not applied to app class';
ok !$app->can('documentation'),   'documentation() was not applied to app class';
ok !$app->can('version'),         'version() was not applied to app class';
isa_ok $script, 'Applify';
can_ok $script, qw(option app documentation version options new print_help import);
is $script->{caller}->[0], 'main', 'called from main::';

done_testing;
