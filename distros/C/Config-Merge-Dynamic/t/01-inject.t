#!perl -T

# for develop
#use lib qw(./lib/);
#use Smart::Comments;
#use Test::More qw( no_plan );

use Test::More tests => 10;

# for filename resolution
use File::Basename qw/dirname/;
use File::Spec;

BEGIN { use_ok('Config::Merge::Dynamic') };

my $class_name = 'Config::Merge::Dynamic';

my $path = join '/', File::Spec->splitdir( dirname(__FILE__) ), 'data';

my $config = new_ok( $class_name => [{ 'path' => $path }], $class_name );
### $config : $config 

my $old_data = $config->('system_config.app.passphrase');
### $config : $config 

my $inject_data;
ok( $inject_data = $config->('user_config'), 'data to inject readed');

ok( $config->inject('system_config', $inject_data ), 'data injected with full path' );

ok( $config->inject('system_config.apache.worker.1', 'fast'), 'value in array injected');

ok( $config->inject({system_config => { app => { user => 'my name' } } }), 'value without path injected' );

my $new_data;
ok( $new_data = $config->('system_config'), 'data after altered readed');
### $new_data : $new_data

my $result;
ok( $result = $config->('result'), 'result readed');

is_deeply( $new_data, $result, 'all data injected correctly' );

ok( $old_data ne $config->('system_config.app.passphrase'), 'cache work correctly');