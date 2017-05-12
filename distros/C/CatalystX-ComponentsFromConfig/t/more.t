#!perl
use Test::More;
use Test::Deep;
use Path::Class;
use lib 't/lib';

my $me=file(__FILE__);
my $config_file=$me->parent->file('testapp-more.conf');

$ENV{CATALYST_CONFIG}=$config_file->stringify;
require TestApp;

cmp_deeply(TestApp->components,
           {
               'TestApp::Model::Foo' => all(
                   isa('TestApp::ModelBase::Foo'),
                   methods(something => 'a string'),
               ),
               'TestApp::View::Bar' => all(
                   isa('TestApp::ViewBase::Foo'),
                   methods(something => 'a view'),
               ),
           },
           'the plugin worked');

ok(TestApp->view('Bar')->can('magic'),
   'trait was applied');
cmp_deeply(TestApp->model('Foo')->requested_traits,
           ['Magic'],
           'explicit new_with_traits called');

done_testing();
