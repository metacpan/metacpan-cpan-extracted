#	$Id: 05-store.t 49 2014-05-02 11:30:14Z adam $

use strict;
use Test;
BEGIN { plan tests => 44 }

use Config::Trivial::Storable;

ok(1);

#
#	Basic Constructor (2-5)
#
ok(my $config = Config::Trivial::Storable->new(
	config_file => "./t/test.data"));			# 2 Create Config object
ok($config->read);								# 3 Read it in
ok($config->store(
	config_file => "./t/test2.data"));			# 4 Write it out
ok(-e "./t/test2.data");						# 5 Was written out

#
#	Create New (6-10)
#

$config = Config::Trivial::Storable->new();
my $data = {test => "orrinoco"};				    # New Data
ok($config->store(
	config_file => "./t/test3.data",		
	configuration => $data));					    # 6 Write it too
ok(-e "./t/test3.data");                            # 7 Test it's there 

$config = Config::Trivial::Storable->new();
ok($config->set_storable_file("./t/test3.data"));   # 8 Manuall set the storefile
$data = {
    test1 => "orrinoco",
    test => "womble"};          					# New Data
ok($config->store(configuration => $data));			# 9 Write it too
ok(-e "./t/test3.data");                            # 10 Test it's there
ok(-e "./t/test3.data~");                           # 11 Check it's updated the old file


#
#	Read things back (12-24)
#

ok($config = Config::Trivial::Storable->new(
    config_file => "./t/test2.data"));              # 12 Create Config object
ok($data = $config->retrieve);                      # 13 Get it back
ok($data->{test1}, "foo");                          # 14 check value
ok($data->{test3}, "baz");                          # 15 check value
ok($config->write);								    # 16 write it back (should make a backup)
ok(-e "./t/test2.data~");                           # 17 Check it's updated the old file

ok($config = Config::Trivial::Storable->new(
    config_file => "./t/test3.data"));              # 18 Create Config object
ok($config->retrieve("test"), "womble");            # 19 Retrive a single value
ok($config->retrieve("test1"), "orrinoco");         # 20 Retrive a single value

ok($config = Config::Trivial::Storable->new);       # 21 New empty setting 
ok($config->set_storable_file("./t/test3.data"));   # 22 Manuall set the storefile
ok($config->{_storable_file}, "./t/test3.data");    # 23 Set manually
ok($config->retrieve("test"), "womble");            # 24 Get the file using the storefile

#
#   Magic reading ... (25-34)
#

sleep (2);                                          # Ensure config file is younger than storeable 

$data = {test => "bulgaria"};                       # New Data
ok(! -e "./t/test4.data");                          # 25 Data file isn't there
ok($config->write(
    config_file => "./t/test4.data",
    configuration => $data));                       # 26 Write it
ok(-e "./t/test4.data");                            # 27 It's there now

ok($config = Config::Trivial::Storable->new(
    config_file => "./t/test.data"));               # 28 Create Config object (text version)
ok($config->set_storable_file("./t/test3.data"));   # 29 Manually set the storefile
ok($config->retrieve("test"), "womble");            # 30 Get the file using the storefile
ok($config->set_config_file("./t/test4.data"));     # 31 Manually set the storefile
ok($config->{_storable_file}, "./t/test3.data");    # 32 The Storable file
ok($config->{_config_file}, "./t/test4.data");      # 33 The Config file
ok($config->retrieve("test"), "bulgaria");          # 34 Get the file using the storefile
ok($config->set_storable_file("./t/test3.data"));   # 35 Manually set the storefile
ok($config->set_config_file("./t/test3.data"));     # 36 and config file to the same file
ok($config->retrieve("test"), "womble");            # 37 Get the file using the storefile
undef $data;
$data = $config->retrieve('');
ok ($data->{"test"}, "womble");                     # 38 Did the whole lot come back okay


#
#	Make sure we clean up (38-43)
#
ok(unlink("./t/test2.data", "./t/test2.data~", "./t/test3.data", "./t/test3.data~","./t/test4.data"), 5);
ok(! -e "./t/test2.data");						# 39 Deleted test2.data okay
ok(! -e "./t/test2.data~");						# 40 Deleted test2.data~ okay
ok(! -e "./t/test3.data");						# 41 Deleted test3.data okay
ok(! -e "./t/test3.data~");						# 42 Deleted test3.data okay
ok(! -e "./t/test4.data");						# 43 Deleted test4.data okay

__DATA__

foo bar
