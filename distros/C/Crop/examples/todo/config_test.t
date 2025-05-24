use strict;
use warnings;
use Test::More;
use Crop::Config;

# Load the configuration data
my $config_data = Crop::Config::data();

# Test install section
is($config_data->{install}{path}, '/home/user/crop/todo/install', 'Install path is correct');
is($config_data->{install}{url}, 'http://todoapp.local', 'Install URL is correct');
is($config_data->{install}{mode}, 'test', 'Install mode is correct');

# Test warehouse section
is($config_data->{warehouse}{db}{main}{name}, 'crop_db', 'Warehouse DB name is correct');
is($config_data->{warehouse}{db}{main}{driver}, 'Pg', 'Warehouse DB driver is correct');
is($config_data->{warehouse}{db}{main}{server}{host}, 'localhost', 'Warehouse DB host is correct');
is($config_data->{warehouse}{db}{main}{server}{port}, '5432', 'Warehouse DB port is correct');
is($config_data->{warehouse}{db}{main}{role}{admin}{login}, 'crop_admin', 'Admin login is correct');
is($config_data->{warehouse}{db}{main}{role}{admin}{pass}, 'secret2', 'Admin password is correct');
is($config_data->{warehouse}{db}{main}{role}{user}{login}, 'crop_user', 'User login is correct');
is($config_data->{warehouse}{db}{main}{role}{user}{pass}, 'secret1', 'User password is correct');

# Test upload section
is($config_data->{upload}{dir}, '/home/user/todo/uploads', 'Upload directory is correct');
is($config_data->{upload}{path}, '/user/upload/file/', 'Upload path is correct');
is($config_data->{upload}{url}, '/user/upload/my/', 'Upload URL is correct');

# Test logLevel
is($config_data->{logLevel}, 'WARNING', 'Log level is correct');

# Test debug section
is($config_data->{debug}{output}, 'On', 'Debug output is correct');
is_deeply($config_data->{debug}{layer}, ['APP'], 'Debug layer is correct');

# Test test section
is($config_data->{test}{url}{todo}, '/todo/', 'Test URL is correct');

done_testing();
