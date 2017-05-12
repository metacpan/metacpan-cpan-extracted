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

my $config = new_ok(
    $class_name => [ 'key_conversion' => 'ucfirst' ],
    $class_name
);

ok( !eval { $config->load_dir() } && $@, 'void call' );

ok( !eval { $config->load_dir('./this_directory_cant_be_exists/') } && $@,
    'non-existans directory' );

my $data_dir = 'data';

my @directories = File::Spec->splitdir( dirname(__FILE__) );
push @directories, $data_dir;
my $path = File::Spec->catdir(@directories);

my $config0 = new_ok(
    $class_name => [ 'file_suffix' => '.txt' ],
    $class_name
);

ok( !eval { $config0->load_dir($path) } && $@, 'missmatched pattern ' );

note('load data from directory');

ok( $config->load_dir($path), 'load directory' );

# this section for suffixless case
note('check files without suffix');

my $config2 = new_ok(
    $class_name => [
        'key_conversion'    => 'ucfirst',
        'i_dont_use_suffix' => 1
    ],
    $class_name
);

ok( $config2->load_dir($path), 'load directory' );

my $data_all = $config2->config();

my $filename = 'check.file';
my $path3 = File::Spec->catfile( @directories, $filename );

my $config3 = new_ok(
    $class_name => [
        'key_conversion'    => 'ucfirst',
        'i_dont_use_suffix' => 1
    ],
    $class_name
);

my $check_data = $config3->load_file($path3)->config();

is_deeply(
    $check_data->{'Check'}{'File'},
    $data_all->{'Another'}{'File'},
    'return object matched'
);

# chech dive()
note('check dave method');

my $daved_data1 = $config2->dive(qw/Another File/);
my $daved_data2 = $config3->dive(qw/Check File/);

is_deeply( $daved_data1, $daved_data2, 'dived return matched' );

ok( !eval { $config2->dive() } && $@, 'empty call forb' );

