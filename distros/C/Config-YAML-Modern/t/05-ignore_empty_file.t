#!perl -T

use Test::More tests => 7;

# use Test::More qw( no_plan );

# for filename resolution
use File::Basename qw/dirname/;
use File::Spec;

# for develop
# use lib qw(./lib/);
# use Smart::Comments;

BEGIN { use_ok('Config::YAML::Modern') }

my $class_name = 'Config::YAML::Modern';

my $args = [
    'key_conversion'    => 'lc',
    'i_dont_use_suffix' => 1,
    'ignore_empty_file' => 1
];

my $config1 = new_ok( $class_name => $args, $class_name );

my $config_check = new_ok( $class_name => $args, $class_name );

my $data_dir        = 'data';
my $data_sub_dir    = 'subdata';
my $empty_files_dir = 'for_empty_files';

my @directories = File::Spec->splitdir( dirname(__FILE__) );

my $path_subdir =
  File::Spec->catdir( ( @directories, $data_dir, $data_sub_dir ) );

my $filename1 = 'empty';
my $path_file1 =
  File::Spec->catfile( ( @directories, $data_dir, $data_sub_dir ), $filename1 );
$config1->load_file($path_file1);

my $filename_check = 'another.file';
my $path_file_check =
  File::Spec->catfile( ( @directories, $data_dir, $data_sub_dir ),
    $filename_check );

$config_check->load_file($path_file_check);

note('check empty files');
is_deeply( $config1->config(), {}, 'empty file ignored on load_file' );

$config1->load_dir($path_subdir);

is_deeply( $config1->config(), $config_check->config(),
    'empty file ignored on load_dir' );

note('load file with data and append empty data');
$path_file2 = File::Spec->catfile( ( @directories, $data_dir ), $filename1 );
$config1->load_file($path_file2);    # loading t/data/empty

my $result = $config1->config();

#check add_file
$config1->add_file( $path_file1, 'RIGHT_PRECEDENT' );

is_deeply( $config1->config(), $result, 'empty file ignored on add_file' );

#check add_dir
my $path_empty_dir =
  File::Spec->catdir( ( @directories, $data_dir, $empty_files_dir ) );

$config1->add_dir( $path_empty_dir, 'RIGHT_PRECEDENT' );

is_deeply( $config1->config(), $result, 'empty file ignored on add_dir' );

