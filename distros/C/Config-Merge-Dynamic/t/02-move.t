#!perl -T

# for develop
#use lib qw(./lib/);
#use Smart::Comments;
#use Test::More qw( no_plan );

use Test::More tests => 8;

# for filename resolution
use File::Basename qw/dirname/;
use File::Spec;

BEGIN { use_ok('Config::Merge::Dynamic') };

my $class_name = 'Config::Merge::Dynamic';

my $path = join '/', File::Spec->splitdir( dirname(__FILE__) ), 'data';

my $config = new_ok( $class_name => [{ 'path' => $path }], $class_name );
# $config : $config 

ok( $config->move('user_config', 'system_config'), 'seems move() worked' );
# $config : $config 

ok( ! defined $config->('user_config'), 'old values are wiped' );

my $delta;
$delta->{apache}{worker}[1] = 'fast';
$delta->{app}{user} = 'my name';

ok( $config->inject( 'system_config', $delta ), 'delta data injected' );

my $new_data = $config->('system_config');
my $result = $config->('result');

is_deeply( $new_data, $result, 'all data proceed correctly' );

my $last_data;
ok( $last_data = $config->move('system_config' ), 'seems one-args(to root) move() worked' );

# just clean up
delete $last_data->{$_} for (qw(result system_config user_config));

# $last_data : $last_data

is_deeply( $last_data, $result, 'all data proceed correctly another one' );