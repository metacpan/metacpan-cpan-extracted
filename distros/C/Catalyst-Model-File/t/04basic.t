use strict;
use warnings;

use Test::More;

plan tests => 14;

use FindBin;
use lib "$FindBin::Bin/lib";


$ENV{MODEL_FILE_DIR} = $FindBin::Bin . '/store';
{
    require Path::Class;
    Path::Class::dir($ENV{MODEL_FILE_DIR})->rmtree;
}

use_ok('Catalyst::Model::File');
use_ok('TestApp');


ok(-d $ENV{MODEL_FILE_DIR}, 'Store directory exists');

my @files = (qw(foo1 foo2));

for my $file (@files) {
    open FILE, '>>', $ENV{MODEL_FILE_DIR} . '/' .$file or die "$! for $ENV{MODEL_FILE_DIR}/$file";
    print FILE $file;
    close FILE;
}

my $model = TestApp->model('File');

ok($model, 'Model ok');

is_deeply([ sort $model->list], \@files, 'List matches');

for my $file (@files) {
    is($model->slurp($file), $file, 'slurp okay');
}

# Slurp/Splat tests
{
    my $file = 'file3';
    my $string = 'A B C';
    $model->splat($file, $string);

    open FILE, $ENV{MODEL_FILE_DIR} . '/'. $file;
    my (@lines) = <FILE>;
    close FILE;
    is_deeply([$string], \@lines, 'splat works');

    is($model->slurp($file), $string, 'slurp works');
}

# Subdir test
{
    my $file = 'sub/dir/file,txt';
    $model->splat($file, $file);

    my $file_obj = $model->file($file);

    ok($file_obj->stat, 'File in sub directory created');
    is($file_obj->slurp, $file, "File contents are right");
}

@files = (Path::Class::file('file3'),
          Path::Class::file('foo1'),
          Path::Class::file('foo2'));
my @dirs = (Path::Class::dir('sub'));
my @both = (@files, @dirs);

$model->cd('/');
# mode => 'both' test
{
    my @result = sort $model->list(recurse => 0, mode => 'both');
    is_deeply(\@result, \@both, 'List of dirs & files matches');
}

# mode => 'dir' test
{
    my @result = sort $model->list(recurse => 0, mode => 'dirs');
    is_deeply(\@result, \@dirs, 'List of dirs matches');
}

# mode => 'file' test
{
    my @result = sort $model->list(recurse => 0, mode => 'files');
    is_deeply(\@result, \@files, 'List of files matches');
}


$model->{root_dir}->rmtree;
