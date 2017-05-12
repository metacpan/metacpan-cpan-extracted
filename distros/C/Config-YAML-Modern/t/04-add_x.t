#!perl -T

use Test::More tests => 13;

#use Test::More qw( no_plan );

# for filename resolution
use File::Basename qw/dirname/;
use File::Spec;

# for develop
#use lib qw(./lib/);
#use Smart::Comments;

BEGIN { use_ok('Config::YAML::Modern') }

my $class_name = 'Config::YAML::Modern';

my $args = [
    'key_conversion'    => 'ucfirst',
    'i_dont_use_suffix' => 1
];

my $config1 = new_ok( $class_name => $args, $class_name );

my $config2 = new_ok( $class_name => $args, $class_name );

my $config_check = new_ok( $class_name => $args, $class_name );

my $config_for_empty = new_ok( $class_name => $args, $class_name );

my $data_dir     = 'data';
my $data_sub_dir = 'subdata';

my @directories = File::Spec->splitdir( dirname(__FILE__) );
push @directories, $data_dir;
my $path_dir = File::Spec->catdir(@directories);

my $filename1 = 'another.file';
my $path_file1 = File::Spec->catfile( @directories, $filename1 );
$config1->load_file($path_file1);

my $filename2 = 'another.file.one';
my $path_file2 = File::Spec->catfile( @directories, $filename2 );
$config2->load_file($path_file2);

my $filename_check = 'check.file';
my $path_file_check = File::Spec->catfile( @directories, $filename_check );

$config_check->load_file($path_file_check);

# check add_hash
note('merge data by add_hash');
ok( !eval { $config1->add_hash() } && $@, 'empty add_hash depricated' );
ok( !eval { $config1->add_hash( [ 'one', 'two' ] ) } && $@,
    'not hash at add_hash depricated' );

$config1->add_hash( $config2->config() );

is_deeply(
    $config1->dive(qw/Another/),
    $config_check->dive(qw/Check/),
    'object merged by add_hash properly'
);

#re-use object and check add_file
note('merge data by add_file');

# make more fun
$config1->load_file($path_file2)->add_file( $path_file1, 'RIGHT_PRECEDENT' );

is_deeply(
    $config1->dive(qw/Another/),
    $config_check->dive(qw/Check/),
    'object merged by add_file properly'
);

#re-use object and check add_dir
note('merge data by add_dir');

push @directories, $data_sub_dir;
$path_dir = File::Spec->catdir(@directories);

$config1->load_file($path_file2)->add_dir( $path_dir, 'RIGHT_PRECEDENT' );

is_deeply(
    $config1->dive(qw/Another/),
    $config_check->dive(qw/Check/),
    'object merged by add_dir properly'
);

note('check empty root hash correct addition');

my $fulled_hash = { c => 4, d => 5 };
my $empty_hash = {};

$config_for_empty->add_hash($empty_hash);

is_deeply( $config_for_empty->config(),
    $empty_hash, 'empty object & empty hash merged properly' );

$config_for_empty->add_hash($fulled_hash);

is_deeply( $config_for_empty->config(),
    $fulled_hash, 'empty object & fulled hash merged properly' );

$config_for_empty->add_hash($empty_hash);

is_deeply( $config_for_empty->config(),
    $fulled_hash, 'fulled object & empty hash merged properly' );
