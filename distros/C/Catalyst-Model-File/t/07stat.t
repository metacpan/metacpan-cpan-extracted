use strict;
use warnings;

use Test::More;

plan tests => 5;

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

open my $fh, '>>', $ENV{MODEL_FILE_DIR} . '/foo1';
print $fh '1234';
close $fh;

my $model = TestApp->model('File');

my @files_from_model = sort $model->list( 
  mode => 'files',
);

for my $file (@files_from_model) {
    my $st = $file->stat;
    ok(defined $st && $st->isa('File::stat'), 'Stat works on file from model');
    ok(defined $st && $st->size == 4, 'Got correct size from stat');
}

$model->{root_dir}->rmtree;
