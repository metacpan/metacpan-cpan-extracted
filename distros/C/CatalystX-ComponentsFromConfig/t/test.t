#!perl
use Test::More;
use Test::Deep;
use Path::Class;
use lib 't/lib';

my $me=file(__FILE__);
my $config_file=$me->parent->file('testapp.conf');

$ENV{CATALYST_CONFIG}=$config_file->stringify;
require TestApp;

cmp_deeply(TestApp->components,
           {
               'TestApp::Model::Foo' => all(
                   isa('Foo'),
                   methods(
                       something => 'a string',
                       orig_args => [superhashof({something => 'a string'})],
                   ),
               ),
               'TestApp::View::Bar' => all(
                   isa('Foo'),
                   methods(
                       something => 'a view',
                       orig_args => [something => 'a view'],
                   ),
               ),
           },
           'the plugin worked');

ok(TestApp->model('Foo')->can('trait_method'),
   'trait was applied');
TestApp->model('Foo')->doit;
TestApp->view('bar')->doit;

cmp_deeply(\@TestApp::ModelAdaptor::calls,
           [ 'a string' ],
           'custom adaptor with config');

done_testing();
