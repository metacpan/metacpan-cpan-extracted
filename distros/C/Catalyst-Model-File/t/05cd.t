use strict;
use warnings;

use Test::More;

plan tests => 10;

use FindBin;
use lib "$FindBin::Bin/lib";
require Path::Class;


$ENV{MODEL_FILE_DIR} = $FindBin::Bin . '/store';
Path::Class::dir($ENV{MODEL_FILE_DIR})->rmtree;

use_ok('Catalyst::Model::File');
use_ok('TestApp');


ok(-d $ENV{MODEL_FILE_DIR}, 'Store directory exists');

my $model = TestApp->model('File');

# Subdir test
{
    my $file = 'sub/dir/file.txt';
    $model->splat($file, $file);

}

$model->cd('sub', 'dir');

is($model->pwd, Path::Class::dir('/sub/dir'), "pwd is correct");

is_deeply(
  [ $model->list ],
  [ Path::Class::file('file.txt') ],
  "list right after cd");


$model->cd('..', 'foo');

is($model->pwd, Path::Class::dir('/sub/foo'), "pwd right after cd('..')");

is($model->parent->pwd, Path::Class::dir('/sub'), "Parent right");
is($model->parent->pwd, Path::Class::dir('/'), "Parent right");
is($model->parent->pwd, Path::Class::dir('/'), "Parent doesn't go out of root");

is_deeply([
        Path::Class::file('sub/dir/file.txt')
    ],
    [ $model->list ], "List right after repeated parent");



$model->{root_dir}->rmtree;
